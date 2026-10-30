-- 1. Backfill missing transaction_pin_hash on public.profiles from auth.users metadata
UPDATE public.profiles AS p
   SET transaction_pin_hash = u.raw_user_meta_data->>'transaction_pin_hash',
       updated_at = NOW()
  FROM auth.users AS u
 WHERE p.id = u.id
   AND (p.transaction_pin_hash IS NULL OR BTRIM(p.transaction_pin_hash) = '')
   AND NULLIF(BTRIM(u.raw_user_meta_data->>'transaction_pin_hash'), '') IS NOT NULL;

-- 2. Allow saving automatic Paystack transfer accounts with timestamp tracking and
-- crediting net-of-Paystack-fee amounts on wallet funding.

CREATE OR REPLACE FUNCTION public.save_paystack_dedicated_wallet_account(
    p_user_id UUID,
    p_customer_code TEXT,
    p_account_number TEXT,
    p_bank_name TEXT,
    p_account_name TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF p_account_number IS NULL OR p_account_number !~ '^[0-9]{10,20}$'
       OR NULLIF(BTRIM(p_bank_name), '') IS NULL
       OR NULLIF(BTRIM(p_account_name), '') IS NULL THEN
        RAISE EXCEPTION 'Invalid Paystack dedicated account details';
    END IF;

    UPDATE public.wallets
       SET paystack_customer_code = COALESCE(NULLIF(BTRIM(p_customer_code), ''), paystack_customer_code),
           virtual_account_number = p_account_number,
           virtual_account_bank = p_bank_name,
           virtual_account_name = p_account_name,
           paystack_dva_status = 'assigned',
           paystack_dva_requested_at = NOW(),
           updated_at = NOW()
     WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found for user';
    END IF;

    RETURN jsonb_build_object(
        'status', 'assigned',
        'account_number', p_account_number,
        'bank_name', p_bank_name,
        'account_name', p_account_name
    );
END;
$$;

DROP FUNCTION IF EXISTS public.credit_paystack_wallet_funding(UUID, TEXT, NUMERIC);

CREATE OR REPLACE FUNCTION public.credit_paystack_wallet_funding(
    p_user_id UUID,
    p_reference TEXT,
    p_amount NUMERIC,
    p_narration TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    payment_amount NUMERIC;
    payment_status TEXT;
    current_balance NUMERIC;
    updated_balance NUMERIC;
BEGIN
    IF p_user_id IS NULL
       OR p_reference IS NULL
       OR p_amount IS NULL
       OR p_amount <= 0
       OR p_amount <> ROUND(p_amount, 2) THEN
        RAISE EXCEPTION 'Invalid wallet funding credit amount';
    END IF;

    SELECT amount, status
      INTO payment_amount, payment_status
      FROM public.transactions
     WHERE user_id = p_user_id
       AND reference = p_reference
       AND category = 'wallet_fund'
       AND type = 'credit'
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet funding reference not found';
    END IF;

    IF payment_status = 'completed' THEN
        RETURN jsonb_build_object(
            'status', 'completed',
            'credited', FALSE,
            'amount', payment_amount
        );
    END IF;

    IF payment_status NOT IN ('pending', 'failed') THEN
        RAISE EXCEPTION 'Wallet funding is not pending';
    END IF;

    SELECT balance
      INTO current_balance
      FROM public.wallets
     WHERE user_id = p_user_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found';
    END IF;

    UPDATE public.wallets
       SET balance = balance + p_amount,
           total_funded = total_funded + p_amount,
           updated_at = NOW()
     WHERE user_id = p_user_id
     RETURNING balance INTO updated_balance;

    UPDATE public.transactions
       SET amount = p_amount,
           status = 'completed',
           balance_before = current_balance,
           balance_after = updated_balance,
           narration = COALESCE(NULLIF(BTRIM(p_narration), ''), narration, 'Paystack wallet funding')
     WHERE user_id = p_user_id
       AND reference = p_reference;

    RETURN jsonb_build_object(
        'status', 'completed',
        'credited', TRUE,
        'amount', p_amount,
        'balance', updated_balance
    );
END;
$$;

DROP FUNCTION IF EXISTS public.credit_paystack_dedicated_wallet_funding(UUID, TEXT, TEXT, NUMERIC);

CREATE OR REPLACE FUNCTION public.credit_paystack_dedicated_wallet_funding(
    p_user_id UUID,
    p_customer_code TEXT,
    p_reference TEXT,
    p_amount NUMERIC,
    p_narration TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    current_wallet public.wallets%ROWTYPE;
    existing_transaction public.transactions%ROWTYPE;
    updated_balance NUMERIC;
    effective_narration TEXT;
BEGIN
    IF p_user_id IS NULL
       OR p_reference IS NULL
       OR p_reference !~ '^[A-Za-z0-9_-]{8,100}$'
       OR p_amount IS NULL
       OR p_amount <= 0
       OR p_amount <> ROUND(p_amount, 2) THEN
        RAISE EXCEPTION 'Invalid Paystack dedicated funding request';
    END IF;

    effective_narration := COALESCE(
        NULLIF(BTRIM(p_narration), ''),
        'Paystack dedicated account transfer'
    );

    SELECT *
      INTO current_wallet
      FROM public.wallets
     WHERE user_id = p_user_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found';
    END IF;

    SELECT *
      INTO existing_transaction
      FROM public.transactions
     WHERE reference = p_reference
     FOR UPDATE;

    IF FOUND THEN
        IF existing_transaction.user_id <> p_user_id
           OR existing_transaction.category <> 'wallet_fund'
           OR existing_transaction.type <> 'credit' THEN
            RAISE EXCEPTION 'Paystack reference already belongs to another transaction';
        END IF;

        IF existing_transaction.status = 'completed' THEN
            RETURN jsonb_build_object(
                'status', 'completed',
                'credited', FALSE,
                'amount', existing_transaction.amount,
                'balance', current_wallet.balance
            );
        END IF;

        UPDATE public.wallets
           SET balance = balance + p_amount,
               total_funded = total_funded + p_amount,
               updated_at = NOW()
         WHERE user_id = p_user_id
         RETURNING balance INTO updated_balance;

        UPDATE public.transactions
           SET amount = p_amount,
               status = 'completed',
               balance_before = current_wallet.balance,
               balance_after = updated_balance,
               narration = effective_narration
         WHERE id = existing_transaction.id;

        RETURN jsonb_build_object(
            'status', 'completed',
            'credited', TRUE,
            'amount', p_amount,
            'balance', updated_balance
        );
    END IF;

    UPDATE public.wallets
       SET balance = balance + p_amount,
           total_funded = total_funded + p_amount,
           updated_at = NOW()
     WHERE user_id = p_user_id
     RETURNING balance INTO updated_balance;

    INSERT INTO public.transactions (
        user_id, type, category, amount, balance_before, balance_after,
        reference, narration, status, idempotency_key
    )
    VALUES (
        p_user_id,
        'credit',
        'wallet_fund',
        p_amount,
        updated_balance - p_amount,
        updated_balance,
        p_reference,
        effective_narration,
        'completed',
        p_reference
    );

    RETURN jsonb_build_object(
        'status', 'completed',
        'credited', TRUE,
        'amount', p_amount,
        'balance', updated_balance
    );
END;
$$;

REVOKE ALL ON FUNCTION public.save_paystack_dedicated_wallet_account(UUID, TEXT, TEXT, TEXT, TEXT)
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.credit_paystack_wallet_funding(UUID, TEXT, NUMERIC, TEXT)
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.credit_paystack_dedicated_wallet_funding(UUID, TEXT, TEXT, NUMERIC, TEXT)
    FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.save_paystack_dedicated_wallet_account(UUID, TEXT, TEXT, TEXT, TEXT)
    TO service_role;
GRANT EXECUTE ON FUNCTION public.credit_paystack_wallet_funding(UUID, TEXT, NUMERIC, TEXT)
    TO service_role;
GRANT EXECUTE ON FUNCTION public.credit_paystack_dedicated_wallet_funding(UUID, TEXT, TEXT, NUMERIC, TEXT)
    TO service_role;

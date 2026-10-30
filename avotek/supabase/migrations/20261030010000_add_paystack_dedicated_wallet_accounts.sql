ALTER TABLE public.wallets
    ADD COLUMN IF NOT EXISTS paystack_customer_code TEXT,
    ADD COLUMN IF NOT EXISTS paystack_dva_status TEXT NOT NULL DEFAULT 'unassigned',
    ADD COLUMN IF NOT EXISTS paystack_dva_requested_at TIMESTAMPTZ;

ALTER TABLE public.wallets
    DROP CONSTRAINT IF EXISTS wallets_paystack_dva_status_check;

ALTER TABLE public.wallets
    ADD CONSTRAINT wallets_paystack_dva_status_check
    CHECK (paystack_dva_status IN ('unassigned', 'pending', 'assigned', 'failed'));

CREATE UNIQUE INDEX IF NOT EXISTS wallets_paystack_customer_code_unique
    ON public.wallets (paystack_customer_code)
    WHERE paystack_customer_code IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS wallets_virtual_account_number_unique
    ON public.wallets (virtual_account_number)
    WHERE virtual_account_number IS NOT NULL;

CREATE OR REPLACE FUNCTION public.claim_paystack_dedicated_wallet_account(
    p_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    current_wallet public.wallets%ROWTYPE;
BEGIN
    SELECT *
      INTO current_wallet
      FROM public.wallets
     WHERE user_id = p_user_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found';
    END IF;

    IF current_wallet.virtual_account_number IS NOT NULL
       AND current_wallet.paystack_dva_status = 'assigned' THEN
        RETURN jsonb_build_object(
            'status', 'assigned',
            'account_number', current_wallet.virtual_account_number,
            'bank_name', current_wallet.virtual_account_bank,
            'account_name', current_wallet.virtual_account_name
        );
    END IF;

    IF current_wallet.paystack_dva_status = 'pending'
       AND current_wallet.paystack_dva_requested_at > NOW() - INTERVAL '5 minutes' THEN
        RETURN jsonb_build_object(
            'status', 'pending',
            'customer_code', current_wallet.paystack_customer_code
        );
    END IF;

    UPDATE public.wallets
       SET paystack_dva_status = 'pending',
           paystack_dva_requested_at = NOW(),
           updated_at = NOW()
     WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
        'status', 'claimed',
        'customer_code', current_wallet.paystack_customer_code
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.save_paystack_customer_code(
    p_user_id UUID,
    p_customer_code TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF p_customer_code IS NULL OR p_customer_code !~ '^CUS_[A-Za-z0-9]+$' THEN
        RAISE EXCEPTION 'Invalid Paystack customer code';
    END IF;

    UPDATE public.wallets
       SET paystack_customer_code = p_customer_code,
           updated_at = NOW()
     WHERE user_id = p_user_id
       AND (paystack_customer_code IS NULL OR paystack_customer_code = p_customer_code);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Paystack customer does not match wallet';
    END IF;
END;
$$;

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
       SET paystack_customer_code = p_customer_code,
           virtual_account_number = p_account_number,
           virtual_account_bank = p_bank_name,
           virtual_account_name = p_account_name,
           paystack_dva_status = 'assigned',
           paystack_dva_requested_at = NULL,
           updated_at = NOW()
     WHERE user_id = p_user_id
       AND paystack_customer_code = p_customer_code;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Paystack customer does not match wallet';
    END IF;

    RETURN jsonb_build_object(
        'status', 'assigned',
        'account_number', p_account_number,
        'bank_name', p_bank_name,
        'account_name', p_account_name
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.fail_paystack_dedicated_wallet_account(
    p_user_id UUID
)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    UPDATE public.wallets
       SET paystack_dva_status = 'failed',
           paystack_dva_requested_at = NULL,
           updated_at = NOW()
     WHERE user_id = p_user_id
       AND paystack_dva_status = 'pending'
       AND virtual_account_number IS NULL;
$$;

CREATE OR REPLACE FUNCTION public.credit_paystack_dedicated_wallet_funding(
    p_user_id UUID,
    p_customer_code TEXT,
    p_reference TEXT,
    p_amount NUMERIC
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
BEGIN
    IF p_user_id IS NULL
       OR p_customer_code IS NULL
       OR p_reference IS NULL
       OR p_reference !~ '^[A-Za-z0-9_-]{12,100}$'
       OR p_amount IS NULL
       OR p_amount <= 0
       OR p_amount <> ROUND(p_amount, 2) THEN
        RAISE EXCEPTION 'Invalid Paystack dedicated funding request';
    END IF;

    SELECT *
      INTO current_wallet
      FROM public.wallets
     WHERE user_id = p_user_id
       AND paystack_customer_code = p_customer_code
       AND paystack_dva_status = 'assigned'
       AND virtual_account_number IS NOT NULL
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Paystack dedicated account not found';
    END IF;

    SELECT *
      INTO existing_transaction
      FROM public.transactions
     WHERE reference = p_reference
     FOR UPDATE;

    IF FOUND THEN
        IF existing_transaction.user_id = p_user_id
           AND existing_transaction.category = 'wallet_fund'
           AND existing_transaction.type = 'credit'
           AND existing_transaction.amount = p_amount
           AND existing_transaction.status = 'completed' THEN
            RETURN jsonb_build_object('status', 'completed', 'credited', FALSE);
        END IF;
        RAISE EXCEPTION 'Paystack reference already belongs to another transaction';
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
        'Paystack dedicated account transfer',
        'completed',
        p_reference
    );

    RETURN jsonb_build_object(
        'status', 'completed',
        'credited', TRUE,
        'balance', updated_balance
    );
END;
$$;

REVOKE ALL ON FUNCTION public.claim_paystack_dedicated_wallet_account(UUID)
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.save_paystack_customer_code(UUID, TEXT)
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.save_paystack_dedicated_wallet_account(UUID, TEXT, TEXT, TEXT, TEXT)
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fail_paystack_dedicated_wallet_account(UUID)
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.credit_paystack_dedicated_wallet_funding(UUID, TEXT, TEXT, NUMERIC)
    FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.claim_paystack_dedicated_wallet_account(UUID)
    TO service_role;
GRANT EXECUTE ON FUNCTION public.save_paystack_customer_code(UUID, TEXT)
    TO service_role;
GRANT EXECUTE ON FUNCTION public.save_paystack_dedicated_wallet_account(UUID, TEXT, TEXT, TEXT, TEXT)
    TO service_role;
GRANT EXECUTE ON FUNCTION public.fail_paystack_dedicated_wallet_account(UUID)
    TO service_role;
GRANT EXECUTE ON FUNCTION public.credit_paystack_dedicated_wallet_funding(UUID, TEXT, TEXT, NUMERIC)
    TO service_role;

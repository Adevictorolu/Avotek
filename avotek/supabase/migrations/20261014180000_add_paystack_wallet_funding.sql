-- Server-only, idempotent wallet credits after verified Paystack payment.
CREATE OR REPLACE FUNCTION public.prepare_paystack_wallet_funding(
    p_user_id UUID,
    p_reference TEXT,
    p_amount NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    current_balance NUMERIC;
BEGIN
    IF p_user_id IS NULL
       OR p_reference IS NULL
       OR p_amount IS NULL
       OR p_reference !~ '^AVOFUND_[A-Fa-f0-9]{32}$'
       OR p_amount < 100
       OR p_amount > 1000000
       OR p_amount <> ROUND(p_amount, 2) THEN
        RAISE EXCEPTION 'Invalid wallet funding request';
    END IF;

    SELECT balance
      INTO current_balance
      FROM public.wallets
     WHERE user_id = p_user_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found';
    END IF;

    INSERT INTO public.transactions (
        user_id, type, category, amount, balance_before, balance_after,
        reference, narration, status, idempotency_key
    )
    VALUES (
        p_user_id, 'credit', 'wallet_fund', p_amount,
        current_balance, current_balance, p_reference,
        'Paystack wallet funding', 'pending', p_reference
    );

    RETURN jsonb_build_object('reference', p_reference, 'status', 'pending');
END;
$$;

CREATE OR REPLACE FUNCTION public.fail_paystack_wallet_funding(
    p_user_id UUID,
    p_reference TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    current_status TEXT;
BEGIN
    UPDATE public.transactions
       SET status = 'failed'
     WHERE user_id = p_user_id
       AND reference = p_reference
       AND category = 'wallet_fund'
       AND status = 'pending'
    RETURNING status INTO current_status;

    RETURN jsonb_build_object(
        'status', COALESCE(current_status, 'unchanged'),
        'finalized', FOUND
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.credit_paystack_wallet_funding(
    p_user_id UUID,
    p_reference TEXT,
    p_amount NUMERIC
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

    IF payment_amount <> p_amount THEN
        RAISE EXCEPTION 'Wallet funding amount mismatch';
    END IF;

    IF payment_status = 'completed' THEN
        RETURN jsonb_build_object('status', 'completed', 'credited', FALSE);
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
       SET status = 'completed',
           balance_before = current_balance,
           balance_after = updated_balance
     WHERE user_id = p_user_id
       AND reference = p_reference;

    RETURN jsonb_build_object(
        'status', 'completed',
        'credited', TRUE,
        'balance', updated_balance
    );
END;
$$;

REVOKE ALL ON FUNCTION public.prepare_paystack_wallet_funding(UUID, TEXT, NUMERIC)
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fail_paystack_wallet_funding(UUID, TEXT)
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.credit_paystack_wallet_funding(UUID, TEXT, NUMERIC)
    FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.prepare_paystack_wallet_funding(UUID, TEXT, NUMERIC)
    TO service_role;
GRANT EXECUTE ON FUNCTION public.fail_paystack_wallet_funding(UUID, TEXT)
    TO service_role;
GRANT EXECUTE ON FUNCTION public.credit_paystack_wallet_funding(UUID, TEXT, NUMERIC)
    TO service_role;

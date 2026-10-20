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
    existing_reference TEXT;
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

    SELECT reference
      INTO existing_reference
      FROM public.transactions
     WHERE user_id = p_user_id
       AND category = 'wallet_fund'
       AND type = 'credit'
       AND status = 'pending'
     ORDER BY created_at DESC
     LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'reference', existing_reference,
            'status', 'pending',
            'already_pending', TRUE
        );
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

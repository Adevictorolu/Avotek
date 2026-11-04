CREATE OR REPLACE FUNCTION public.finalize_vtu_purchase_with_cashback(
    p_user_id UUID,
    p_reference TEXT,
    p_status TEXT,
    p_narration TEXT,
    p_cashback_amount NUMERIC DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    purchase_amount NUMERIC;
    purchase_status TEXT;
    purchase_category TEXT;
    current_balance NUMERIC;
    cashback_amount NUMERIC := COALESCE(p_cashback_amount, 0);
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;
    IF p_status NOT IN ('completed', 'pending', 'failed') THEN
        RAISE EXCEPTION 'Invalid purchase status';
    END IF;
    IF cashback_amount < 0 OR cashback_amount > 1000000 THEN
        RAISE EXCEPTION 'Invalid cashback amount';
    END IF;

    SELECT amount, status, category
      INTO purchase_amount, purchase_status, purchase_category
      FROM public.transactions
     WHERE reference = p_reference
       AND user_id = p_user_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Purchase reservation not found';
    END IF;

    IF purchase_status <> 'pending' THEN
        RETURN jsonb_build_object(
            'status', purchase_status,
            'finalized', FALSE,
            'cashback_amount', 0
        );
    END IF;

    IF p_status = 'failed' THEN
        UPDATE public.wallets
           SET balance = balance + purchase_amount,
               total_spent = GREATEST(0, total_spent - purchase_amount),
               updated_at = NOW()
         WHERE user_id = p_user_id
         RETURNING balance INTO current_balance;

        UPDATE public.transactions
           SET status = 'failed',
               balance_after = COALESCE(current_balance, balance_after),
               narration = COALESCE(p_narration, narration)
         WHERE reference = p_reference
           AND user_id = p_user_id;
        cashback_amount := 0;
    ELSE
        IF p_status = 'completed' AND purchase_category = 'airtime' THEN
            cashback_amount := LEAST(cashback_amount, purchase_amount);
            IF cashback_amount > 0 THEN
                UPDATE public.wallets
                   SET balance = balance + cashback_amount,
                       updated_at = NOW()
                 WHERE user_id = p_user_id
                 RETURNING balance INTO current_balance;

                INSERT INTO public.transactions (
                    user_id, type, category, amount, balance_before, balance_after,
                    reference, narration, status, idempotency_key
                )
                VALUES (
                    p_user_id,
                    'credit',
                    'airtime_cashback',
                    cashback_amount,
                    current_balance - cashback_amount,
                    current_balance,
                    LEFT(p_reference, 115) || '-CB',
                    'Airtime cashback for purchase ' || p_reference,
                    'completed',
                    LEFT(p_reference, 115) || '-CB'
                )
                ON CONFLICT (reference) DO NOTHING;
            END IF;
        ELSE
            cashback_amount := 0;
        END IF;

        UPDATE public.transactions
           SET status = p_status,
               narration = COALESCE(p_narration, narration)
         WHERE reference = p_reference
           AND user_id = p_user_id;
    END IF;

    RETURN jsonb_build_object(
        'status', p_status,
        'finalized', TRUE,
        'cashback_amount', cashback_amount
    );
END;
$$;

REVOKE ALL ON FUNCTION public.finalize_vtu_purchase_with_cashback(UUID, TEXT, TEXT, TEXT, NUMERIC)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_vtu_purchase_with_cashback(UUID, TEXT, TEXT, TEXT, NUMERIC)
    TO service_role;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables
             WHERE pubname = 'supabase_realtime'
               AND schemaname = 'public'
               AND tablename = 'wallets'
        ) THEN
            EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.wallets';
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables
             WHERE pubname = 'supabase_realtime'
               AND schemaname = 'public'
               AND tablename = 'transactions'
        ) THEN
            EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.transactions';
        END IF;
    END IF;
END;
$$;

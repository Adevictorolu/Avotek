CREATE TABLE IF NOT EXISTS public.airtime_cash_conversions (
    reference TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    network TEXT NOT NULL CHECK (network IN ('MTN', 'AIRTEL')),
    phone TEXT NOT NULL,
    airtime_amount NUMERIC(12, 2) NOT NULL,
    payout_amount NUMERIC(12, 2) NOT NULL,
    provider_reference TEXT,
    status TEXT NOT NULL DEFAULT 'processing'
        CHECK (status IN ('processing', 'completed', 'failed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS airtime_cash_conversions_user_created_idx
    ON public.airtime_cash_conversions (user_id, created_at DESC);

ALTER TABLE public.airtime_cash_conversions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.airtime_cash_conversions FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.airtime_cash_conversions TO service_role;

CREATE OR REPLACE FUNCTION public.begin_airtime_cash_conversion(
    p_user_id UUID,
    p_reference TEXT,
    p_network TEXT,
    p_phone TEXT,
    p_airtime_amount NUMERIC,
    p_payout_amount NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    existing_conversion public.airtime_cash_conversions%ROWTYPE;
    expected_payout NUMERIC;
    current_network TEXT := UPPER(BTRIM(p_network));
BEGIN
    IF p_user_id IS NULL OR p_reference IS NULL OR
       LENGTH(BTRIM(p_reference)) < 12 OR LENGTH(BTRIM(p_reference)) > 120 THEN
        RAISE EXCEPTION 'Invalid airtime conversion request';
    END IF;
    IF current_network NOT IN ('MTN', 'AIRTEL') THEN
        RAISE EXCEPTION 'Airtime conversion supports MTN and Airtel only';
    END IF;
    IF p_phone !~ '^234[0-9]{10}$' THEN
        RAISE EXCEPTION 'Invalid airtime sender phone number';
    END IF;
    IF p_airtime_amount < 1000 OR p_airtime_amount > 50000 OR
       p_airtime_amount <> TRUNC(p_airtime_amount) THEN
        RAISE EXCEPTION 'Invalid airtime conversion amount';
    END IF;

    expected_payout := ROUND(
        p_airtime_amount *
        CASE current_network WHEN 'MTN' THEN 0.85 ELSE 0.82 END
    );
    IF p_payout_amount <> expected_payout THEN
        RAISE EXCEPTION 'Airtime conversion payout does not match the configured rate';
    END IF;

    SELECT * INTO existing_conversion
      FROM public.airtime_cash_conversions
     WHERE reference = p_reference
     FOR UPDATE;

    IF FOUND THEN
        IF existing_conversion.user_id <> p_user_id OR
           existing_conversion.network <> current_network OR
           existing_conversion.phone <> p_phone OR
           existing_conversion.airtime_amount <> p_airtime_amount OR
           existing_conversion.payout_amount <> p_payout_amount THEN
            RAISE EXCEPTION 'Airtime conversion reference already used';
        END IF;
        RETURN jsonb_build_object(
            'status', existing_conversion.status,
            'started', FALSE
        );
    END IF;

    PERFORM 1
      FROM public.wallets
     WHERE user_id = p_user_id
     FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.airtime_cash_conversions
         WHERE user_id = p_user_id
           AND status = 'processing'
    ) THEN
        RAISE EXCEPTION 'A previous airtime conversion is still being confirmed';
    END IF;

    INSERT INTO public.airtime_cash_conversions (
        reference, user_id, network, phone, airtime_amount, payout_amount
    )
    VALUES (
        BTRIM(p_reference), p_user_id, current_network, p_phone,
        p_airtime_amount, p_payout_amount
    );

    RETURN jsonb_build_object('status', 'processing', 'started', TRUE);
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_airtime_cash_conversion(
    p_user_id UUID,
    p_reference TEXT,
    p_provider_reference TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    conversion public.airtime_cash_conversions%ROWTYPE;
    balance_before NUMERIC;
    balance_after NUMERIC;
BEGIN
    SELECT * INTO conversion
      FROM public.airtime_cash_conversions
     WHERE reference = p_reference
       AND user_id = p_user_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Airtime conversion request not found';
    END IF;
    IF conversion.status = 'completed' THEN
        RETURN jsonb_build_object(
            'status', 'completed',
            'credited', FALSE,
            'payout_amount', conversion.payout_amount
        );
    END IF;
    IF conversion.status <> 'processing' THEN
        RAISE EXCEPTION 'Airtime conversion is not pending';
    END IF;

    SELECT balance INTO balance_before
      FROM public.wallets
     WHERE user_id = p_user_id
     FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found';
    END IF;

    UPDATE public.wallets
       SET balance = balance + conversion.payout_amount,
           updated_at = NOW()
     WHERE user_id = p_user_id
     RETURNING balance INTO balance_after;

    INSERT INTO public.transactions (
        user_id, type, category, amount, balance_before, balance_after,
        reference, narration, status, idempotency_key
    )
    VALUES (
        p_user_id, 'credit', 'airtime_cash', conversion.payout_amount,
        balance_before, balance_after, p_reference,
        conversion.network || ' airtime-to-cash wallet payout',
        'completed', p_reference
    );

    INSERT INTO public.vtu_orders AS existing_order (
        id, user_id, service_type, network, phone, plan, amount,
        status, provider_reference
    )
    VALUES (
        p_reference, p_user_id, 'airtime_cash', conversion.network,
        conversion.phone,
        '₦' || conversion.airtime_amount::TEXT || ' airtime converted',
        conversion.payout_amount, 'successful',
        NULLIF(BTRIM(p_provider_reference), '')
    )
    ON CONFLICT (id) DO UPDATE
       SET status = 'successful',
           amount = EXCLUDED.amount,
           provider_reference = COALESCE(
               EXCLUDED.provider_reference,
               existing_order.provider_reference
           )
     WHERE existing_order.user_id = EXCLUDED.user_id;

    UPDATE public.airtime_cash_conversions
       SET status = 'completed',
           provider_reference = NULLIF(BTRIM(p_provider_reference), ''),
           updated_at = NOW()
     WHERE reference = p_reference;

    RETURN jsonb_build_object(
        'status', 'completed',
        'credited', TRUE,
        'payout_amount', conversion.payout_amount,
        'balance_after', balance_after
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.fail_airtime_cash_conversion(
    p_user_id UUID,
    p_reference TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    UPDATE public.airtime_cash_conversions
       SET status = 'failed',
           updated_at = NOW()
     WHERE reference = p_reference
       AND user_id = p_user_id
       AND status = 'processing';

    UPDATE public.vtu_orders
       SET status = 'failed'
     WHERE id = p_reference
       AND user_id = p_user_id
       AND service_type = 'airtime_cash'
       AND status = 'pending';

    RETURN jsonb_build_object('status', 'failed', 'updated', FOUND);
END;
$$;

REVOKE ALL ON FUNCTION public.begin_airtime_cash_conversion(
    UUID, TEXT, TEXT, TEXT, NUMERIC, NUMERIC
) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.complete_airtime_cash_conversion(UUID, TEXT, TEXT)
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fail_airtime_cash_conversion(UUID, TEXT)
    FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.begin_airtime_cash_conversion(
    UUID, TEXT, TEXT, TEXT, NUMERIC, NUMERIC
) TO service_role;
GRANT EXECUTE ON FUNCTION public.complete_airtime_cash_conversion(UUID, TEXT, TEXT)
    TO service_role;
GRANT EXECUTE ON FUNCTION public.fail_airtime_cash_conversion(UUID, TEXT)
    TO service_role;

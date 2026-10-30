-- 20261030190000_gift_vouchers_and_coupons.sql
-- Enables gift voucher issuance, wallet debit, shareable coupon links, and instant atomic wallet redemption.

CREATE TABLE IF NOT EXISTS public.gift_vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipient TEXT,
    note TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'redeemed', 'cancelled', 'expired')),
    claimed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    claimed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gift_vouchers_code ON public.gift_vouchers (UPPER(code));
CREATE INDEX IF NOT EXISTS idx_gift_vouchers_creator ON public.gift_vouchers (creator_id);

ALTER TABLE public.gift_vouchers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Gift voucher read policy" ON public.gift_vouchers;
CREATE POLICY "Gift voucher read policy"
    ON public.gift_vouchers FOR SELECT
    USING (creator_id = auth.uid() OR status = 'active' OR claimed_by = auth.uid());

-- Function: Create Gift Voucher with Wallet Debit
CREATE OR REPLACE FUNCTION public.create_gift_voucher(
    p_amount NUMERIC,
    p_recipient TEXT DEFAULT '',
    p_note TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_balance NUMERIC;
    v_code TEXT;
    v_voucher_id UUID;
    v_ref TEXT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated.';
    END IF;

    IF p_amount IS NULL OR p_amount < 50 THEN
        RAISE EXCEPTION 'Minimum gift voucher amount is ₦50.';
    END IF;

    -- Check and lock wallet
    SELECT balance INTO v_balance
    FROM public.wallets
    WHERE user_id = v_user_id
    FOR UPDATE;

    IF v_balance IS NULL OR v_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient wallet balance to create this gift voucher.';
    END IF;

    -- Generate unique code
    v_code := 'AVOGIFT-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT || NOW()::TEXT) FROM 1 FOR 8));
    v_ref := 'GIFT-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));

    -- Debit wallet
    UPDATE public.wallets
    SET balance = balance - p_amount,
        total_spent = total_spent + p_amount,
        updated_at = NOW()
    WHERE user_id = v_user_id;

    -- Insert transaction
    INSERT INTO public.transactions (
        user_id, type, category, amount, balance_before, balance_after,
        reference, narration, status
    ) VALUES (
        v_user_id, 'debit', 'gift_voucher', p_amount, v_balance, v_balance - p_amount,
        v_ref, 'Created Gift Voucher: ' || v_code, 'completed'
    );

    -- Insert voucher
    INSERT INTO public.gift_vouchers (
        code, amount, creator_id, recipient, note, status
    ) VALUES (
        v_code, p_amount, v_user_id, p_recipient, p_note, 'active'
    ) RETURNING id INTO v_voucher_id;

    RETURN jsonb_build_object(
        'success', true,
        'voucher_id', v_voucher_id,
        'code', v_code,
        'amount', p_amount,
        'new_balance', v_balance - p_amount
    );
END;
$$;

-- Function: Redeem Gift Voucher with Instant Wallet Credit
CREATE OR REPLACE FUNCTION public.redeem_gift_voucher(
    p_code TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_voucher RECORD;
    v_balance NUMERIC;
    v_ref TEXT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated.';
    END IF;

    IF p_code IS NULL OR BTRIM(p_code) = '' THEN
        RAISE EXCEPTION 'Please provide a valid coupon code.';
    END IF;

    -- Find and lock active voucher
    SELECT * INTO v_voucher
    FROM public.gift_vouchers
    WHERE UPPER(code) = UPPER(BTRIM(p_code))
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Coupon or Gift code not found. Check code and retry.';
    END IF;

    IF v_voucher.status != 'active' THEN
        RAISE EXCEPTION 'This coupon code has already been redeemed or expired.';
    END IF;

    -- Select and lock claiming user's wallet
    SELECT balance INTO v_balance
    FROM public.wallets
    WHERE user_id = v_user_id
    FOR UPDATE;

    IF v_balance IS NULL THEN
        -- Create wallet if missing
        INSERT INTO public.wallets (user_id, balance, currency)
        VALUES (v_user_id, 0.00, 'NGN')
        RETURNING balance INTO v_balance;
    END IF;

    v_ref := 'REDEEM-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));

    -- Credit wallet
    UPDATE public.wallets
    SET balance = balance + v_voucher.amount,
        total_funded = total_funded + v_voucher.amount,
        updated_at = NOW()
    WHERE user_id = v_user_id;

    -- Update voucher
    UPDATE public.gift_vouchers
    SET status = 'redeemed',
        claimed_by = v_user_id,
        claimed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_voucher.id;

    -- Insert transaction
    INSERT INTO public.transactions (
        user_id, type, category, amount, balance_before, balance_after,
        reference, narration, status
    ) VALUES (
        v_user_id, 'credit', 'coupon_redeem', v_voucher.amount, v_balance, v_balance + v_voucher.amount,
        v_ref, 'Redeemed Gift Coupon: ' || v_voucher.code, 'completed'
    );

    RETURN jsonb_build_object(
        'success', true,
        'code', v_voucher.code,
        'amount', v_voucher.amount,
        'new_balance', v_balance + v_voucher.amount,
        'note', v_voucher.note
    );
END;
$$;

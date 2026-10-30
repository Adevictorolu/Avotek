-- Migration: Admin Panel Privileges, Referral Stats & Rewards, Change PIN
-- Project: gcixbqrridzgobkqnlfz

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        LOWER(auth.jwt()->>'email') IN ('ademolavictor869@gmail.com', 'avotek12@gmail.com')
        OR auth.uid() IN ('89fa6337-2d44-4df1-8894-844085af37c6'::uuid, 'f6681d1c-2956-415c-9d64-25169d2ace6b'::uuid),
        FALSE
    );
$$;

-- Grant admin select/write access
CREATE POLICY "Admins can view all profiles"
    ON public.profiles
    FOR SELECT
    USING (public.is_admin());

CREATE POLICY "Admins can update all profiles"
    ON public.profiles
    FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "Admins can view all wallets"
    ON public.wallets
    FOR SELECT
    USING (public.is_admin());

CREATE POLICY "Admins can view all transactions"
    ON public.transactions
    FOR SELECT
    USING (public.is_admin());

CREATE POLICY "Admins can view all orders"
    ON public.vtu_orders
    FOR SELECT
    USING (public.is_admin());

-- 1. Admin System Stats
CREATE OR REPLACE FUNCTION public.admin_get_system_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    res JSONB;
    v_total_users INT;
    v_verified_kyc INT;
    v_unverified_kyc INT;
    v_total_balance NUMERIC(14,2);
    v_total_spent NUMERIC(14,2);
    v_total_orders INT;
    v_successful_orders INT;
    v_failed_orders INT;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Admin privileges required';
    END IF;

    SELECT COUNT(*) INTO v_total_users FROM public.profiles;
    SELECT COUNT(*) INTO v_verified_kyc FROM public.profiles WHERE LOWER(kyc_status) = 'verified';
    SELECT COUNT(*) INTO v_unverified_kyc FROM public.profiles WHERE LOWER(COALESCE(kyc_status, 'unverified')) <> 'verified';

    SELECT COALESCE(SUM(balance), 0), COALESCE(SUM(total_spent), 0)
      INTO v_total_balance, v_total_spent
      FROM public.wallets;

    SELECT COUNT(*) INTO v_total_orders FROM public.vtu_orders;
    SELECT COUNT(*) INTO v_successful_orders FROM public.vtu_orders WHERE status = 'successful';
    SELECT COUNT(*) INTO v_failed_orders FROM public.vtu_orders WHERE status = 'failed';

    res := jsonb_build_object(
        'total_users', v_total_users,
        'verified_kyc', v_verified_kyc,
        'unverified_kyc', v_unverified_kyc,
        'total_balance', v_total_balance,
        'total_spent', v_total_spent,
        'total_orders', v_total_orders,
        'successful_orders', v_successful_orders,
        'failed_orders', v_failed_orders
    );

    RETURN res;
END;
$$;

-- 2. Admin List Users
CREATE OR REPLACE FUNCTION public.admin_list_users()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    res JSONB;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Admin privileges required';
    END IF;

    SELECT COALESCE(jsonb_agg(u), '[]'::jsonb)
      INTO res
      FROM (
          SELECT p.id,
                 p.email,
                 p.full_name,
                 p.phone,
                 p.kyc_status,
                 p.referral_code,
                 p.created_at,
                 COALESCE(w.balance, 0.00) as balance,
                 COALESCE(w.virtual_account_number, '') as account_number,
                 COALESCE(w.virtual_account_bank, '') as bank_name
            FROM public.profiles p
            LEFT JOIN public.wallets w ON w.user_id = p.id
           ORDER BY p.created_at DESC
      ) u;

    RETURN res;
END;
$$;

-- 3. Admin Update User KYC
CREATE OR REPLACE FUNCTION public.admin_set_user_kyc(
    p_user_id UUID,
    p_kyc_status TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Admin privileges required';
    END IF;

    UPDATE public.profiles
       SET kyc_status = LOWER(TRIM(p_kyc_status)),
           updated_at = NOW()
     WHERE id = p_user_id;

    RETURN jsonb_build_object('success', TRUE, 'kyc_status', LOWER(TRIM(p_kyc_status)));
END;
$$;

-- 4. Admin Wallet Adjust
CREATE OR REPLACE FUNCTION public.admin_adjust_user_wallet(
    p_user_id UUID,
    p_amount NUMERIC,
    p_narration TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_balance_before NUMERIC;
    v_balance_after NUMERIC;
    v_ref TEXT;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Admin privileges required';
    END IF;

    SELECT balance INTO v_balance_before
      FROM public.wallets
     WHERE user_id = p_user_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found for this user';
    END IF;

    IF v_balance_before + p_amount < 0 THEN
        RAISE EXCEPTION 'Debit exceeds current balance';
    END IF;

    UPDATE public.wallets
       SET balance = balance + p_amount,
           updated_at = NOW()
     WHERE user_id = p_user_id
     RETURNING balance INTO v_balance_after;

    v_ref := 'ADM-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || FLOOR(RANDOM() * 90000 + 10000);

    INSERT INTO public.transactions (
        user_id,
        type,
        category,
        amount,
        balance_before,
        balance_after,
        reference,
        narration,
        status
    )
    VALUES (
        p_user_id,
        CASE WHEN p_amount >= 0 THEN 'credit' ELSE 'debit' END,
        'admin_adjustment',
        ABS(p_amount),
        v_balance_before,
        v_balance_after,
        v_ref,
        COALESCE(p_narration, 'Admin wallet adjustment'),
        'completed'
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'balance_before', v_balance_before,
        'balance_after', v_balance_after
    );
END;
$$;

-- 5. Referral Stats & Leaderboard
CREATE OR REPLACE FUNCTION public.get_user_referral_summary(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_ref_code TEXT;
    v_count INT;
    v_points INT;
    v_earnings NUMERIC(12,2);
BEGIN
    SELECT referral_code INTO v_ref_code
      FROM public.profiles
     WHERE id = p_user_id;

    IF v_ref_code IS NULL OR v_ref_code = '' THEN
        RETURN jsonb_build_object('referral_count', 0, 'avo_points', 0, 'earnings_naira', 0.00);
    END IF;

    SELECT COUNT(*) INTO v_count
      FROM public.profiles
     WHERE UPPER(referred_by) = UPPER(v_ref_code);

    v_points := v_count * 100;
    v_earnings := v_count * 50.00; -- ₦50 bonus per referral

    RETURN jsonb_build_object(
        'referral_code', v_ref_code,
        'referral_count', v_count,
        'avo_points', v_points,
        'earnings_naira', v_earnings
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_referral_leaderboard()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    res JSONB;
BEGIN
    SELECT COALESCE(jsonb_agg(l), '[]'::jsonb)
      INTO res
      FROM (
          SELECT p.full_name,
                 p.referral_code,
                 COUNT(r.id) AS referrals_count,
                 COUNT(r.id) * 100 AS avo_tokens
            FROM public.profiles p
            JOIN public.profiles r ON UPPER(r.referred_by) = UPPER(p.referral_code)
           GROUP BY p.id, p.full_name, p.referral_code
           ORDER BY referrals_count DESC
           LIMIT 10
      ) l;

    RETURN res;
END;
$$;

-- 6. Redeem AVO Token Points to Wallet
CREATE OR REPLACE FUNCTION public.redeem_avo_points(
    p_user_id UUID,
    p_points INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_summary JSONB;
    v_available_points INT;
    v_naira NUMERIC(12,2);
    v_bal_before NUMERIC;
    v_bal_after NUMERIC;
    v_ref TEXT;
BEGIN
    IF auth.uid() <> p_user_id AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    IF p_points < 100 THEN
        RAISE EXCEPTION 'Minimum redemption is 100 AVO points';
    END IF;

    v_summary := public.get_user_referral_summary(p_user_id);
    v_available_points := (v_summary->>'avo_points')::INT;

    IF v_available_points < p_points THEN
        RAISE EXCEPTION 'Insufficient AVO points. You have % points.', v_available_points;
    END IF;

    -- 100 AVO Points = ₦50 Naira wallet credit
    v_naira := (p_points / 100.0) * 50.0;

    SELECT balance INTO v_bal_before
      FROM public.wallets
     WHERE user_id = p_user_id
       FOR UPDATE;

    UPDATE public.wallets
       SET balance = balance + v_naira,
           total_funded = total_funded + v_naira,
           updated_at = NOW()
     WHERE user_id = p_user_id
     RETURNING balance INTO v_bal_after;

    v_ref := 'AVO-RDM-' || EXTRACT(EPOCH FROM NOW())::BIGINT;

    INSERT INTO public.transactions (
        user_id,
        type,
        category,
        amount,
        balance_before,
        balance_after,
        reference,
        narration,
        status
    )
    VALUES (
        p_user_id,
        'credit',
        'avo_token_redemption',
        v_naira,
        v_bal_before,
        v_bal_after,
        v_ref,
        'Redeemed ' || p_points || ' AVO Token Points',
        'completed'
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'points_redeemed', p_points,
        'amount_credited', v_naira,
        'new_balance', v_bal_after
    );
END;
$$;

-- 7. Change Transaction PIN from Old to New
CREATE OR REPLACE FUNCTION public.change_user_transaction_pin(
    p_user_id UUID,
    p_old_pin_hash TEXT,
    p_new_pin_hash TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_current_hash TEXT;
BEGIN
    IF auth.uid() <> p_user_id AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    SELECT transaction_pin_hash INTO v_current_hash
      FROM public.profiles
     WHERE id = p_user_id;

    IF v_current_hash IS NOT NULL AND v_current_hash <> '' THEN
        IF v_current_hash <> p_old_pin_hash THEN
            RAISE EXCEPTION 'Current transaction PIN is incorrect';
        END IF;
    END IF;

    UPDATE public.profiles
       SET transaction_pin_hash = p_new_pin_hash,
           updated_at = NOW()
     WHERE id = p_user_id;

    RETURN jsonb_build_object('success', TRUE);
END;
$$;

-- Permissions
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.admin_get_system_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_user_kyc(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_adjust_user_wallet(UUID, NUMERIC, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_referral_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_referral_leaderboard() TO authenticated;
GRANT EXECUTE ON FUNCTION public.redeem_avo_points(UUID, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.change_user_transaction_pin(UUID, TEXT, TEXT) TO authenticated;

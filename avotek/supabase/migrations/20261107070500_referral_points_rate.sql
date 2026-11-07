CREATE OR REPLACE FUNCTION public.get_user_referral_summary(
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_referral_code TEXT;
    v_avo_id TEXT;
    v_username TEXT;
    v_referral_count INTEGER := 0;
    v_lifetime_points INTEGER := 0;
    v_redeemed_points INTEGER := 0;
    v_earnings NUMERIC(12, 2) := 0;
BEGIN
    IF v_user_id IS NULL OR (
        auth.uid() IS DISTINCT FROM v_user_id AND NOT public.is_admin()
    ) THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    SELECT referral_code, avo_id, username
      INTO v_referral_code, v_avo_id, v_username
      FROM public.profiles
     WHERE id = v_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'referral_count', 0,
            'avo_points', 0,
            'lifetime_avo_points', 0,
            'redeemed_points', 0,
            'total_earned', 0.00,
            'earnings_naira', 0.00
        );
    END IF;

    SELECT COUNT(*)::INTEGER
      INTO v_referral_count
      FROM public.profiles referred
     WHERE UPPER(BTRIM(referred.referred_by)) IN (
         UPPER(BTRIM(v_referral_code)),
         UPPER(BTRIM(v_avo_id)),
         UPPER(BTRIM(v_username))
     );

    v_lifetime_points := v_referral_count * 10;

    SELECT COALESCE(SUM(
        CASE
            WHEN narration ~ '^Redeemed [0-9]+ AVO Token Points$'
                THEN SUBSTRING(
                    narration FROM '^Redeemed ([0-9]+) AVO Token Points$'
                )::INTEGER
            ELSE ROUND(amount * 2)::INTEGER
        END
    ), 0)::INTEGER
      INTO v_redeemed_points
      FROM public.transactions
     WHERE user_id = v_user_id
       AND category = 'avo_token_redemption'
       AND status = 'completed';

    SELECT COALESCE(SUM(amount), 0)::NUMERIC(12, 2)
      INTO v_earnings
      FROM public.transactions
     WHERE user_id = v_user_id
       AND category = 'referral_bonus'
       AND status = 'completed';

    RETURN jsonb_build_object(
        'referral_code', v_referral_code,
        'referral_count', v_referral_count,
        'avo_points', GREATEST(0, v_lifetime_points - v_redeemed_points),
        'lifetime_avo_points', v_lifetime_points,
        'redeemed_points', v_redeemed_points,
        'total_earned', v_earnings,
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
    result JSONB;
BEGIN
    SELECT COALESCE(jsonb_agg(ranked), '[]'::JSONB)
      INTO result
      FROM (
          SELECT
              COALESCE(NULLIF(BTRIM(referrer.full_name), ''),
                       NULLIF(BTRIM(referrer.username), ''),
                       'Avotek Member') AS name,
              referrer.avo_id,
              COUNT(referred.id)::INTEGER AS referral_count,
              (COUNT(referred.id) * 10)::INTEGER AS points
            FROM public.profiles referrer
            JOIN public.profiles referred
              ON UPPER(BTRIM(referred.referred_by)) IN (
                  UPPER(BTRIM(referrer.referral_code)),
                  UPPER(BTRIM(referrer.avo_id)),
                  UPPER(BTRIM(referrer.username))
              )
           GROUP BY referrer.id, referrer.full_name, referrer.username,
                    referrer.avo_id
           ORDER BY COUNT(referred.id) DESC, referrer.created_at ASC
           LIMIT 10
      ) ranked;

    RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.redeem_avo_points(
    p_user_id UUID,
    p_points INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_summary JSONB;
    v_available_points INTEGER;
    v_naira NUMERIC(12, 2);
    v_balance_before NUMERIC;
    v_balance_after NUMERIC;
    v_reference TEXT;
BEGIN
    IF p_user_id IS NULL OR (
        auth.uid() IS DISTINCT FROM p_user_id AND NOT public.is_admin()
    ) THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    IF p_points IS NULL OR p_points < 200 THEN
        RAISE EXCEPTION 'Minimum redemption is 200 AVO points';
    END IF;

    PERFORM 1
      FROM public.profiles
     WHERE id = p_user_id
       FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User profile was not found';
    END IF;

    v_summary := public.get_user_referral_summary(p_user_id);
    v_available_points := COALESCE((v_summary->>'avo_points')::INTEGER, 0);
    IF v_available_points < p_points THEN
        RAISE EXCEPTION 'Insufficient AVO points. You have % points.',
            v_available_points;
    END IF;

    SELECT balance
      INTO v_balance_before
      FROM public.wallets
     WHERE user_id = p_user_id
       FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet was not found';
    END IF;

    v_naira := p_points;
    UPDATE public.wallets
       SET balance = balance + v_naira,
           total_funded = total_funded + v_naira,
           updated_at = NOW()
     WHERE user_id = p_user_id
     RETURNING balance INTO v_balance_after;

    v_reference := 'AVO-RDM-' || gen_random_uuid()::TEXT;
    INSERT INTO public.transactions (
        user_id, type, category, amount, balance_before, balance_after,
        reference, narration, status
    )
    VALUES (
        p_user_id, 'credit', 'avo_token_redemption', v_naira,
        v_balance_before, v_balance_after, v_reference,
        'Redeemed ' || p_points || ' AVO Token Points', 'completed'
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'points_redeemed', p_points,
        'amount_credited', v_naira,
        'new_balance', v_balance_after
    );
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_referral_summary(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_referral_leaderboard() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.redeem_avo_points(UUID, INTEGER) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_user_referral_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_referral_leaderboard() TO authenticated;
GRANT EXECUTE ON FUNCTION public.redeem_avo_points(UUID, INTEGER) TO authenticated;

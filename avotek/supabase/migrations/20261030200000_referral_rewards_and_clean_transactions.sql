-- Migration: Enhanced Mutual Referral Rewards and Clean Transactions for New Users
-- Description:
-- 1. Updates handle_new_user to ensure referred_by is saved in public.profiles.
-- 2. Rewards BOTH users upon registration:
--    - Referrer receives ₦50 wallet balance + 100 AVO token points.
--    - Referee (new user) receives ₦25 welcome bonus credit into their wallet balance.
-- 3. Ensures incoming users who do not use a referral code start with a clean 0 transactions and ₦0.00 balance.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    clean_name TEXT;
    clean_phone TEXT;
    clean_avatar TEXT;
    clean_ref TEXT;
    clean_avo_id TEXT;
    clean_username TEXT;
    clean_referred_by TEXT;
    v_referrer_id UUID;
    v_ref_balance_before NUMERIC;
    v_ref_balance_after NUMERIC;
BEGIN
    clean_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1)
    );
    clean_phone := COALESCE(NEW.raw_user_meta_data->>'phone', '');
    clean_avatar := COALESCE(
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'picture',
        ''
    );
    clean_referred_by := NULLIF(BTRIM(NEW.raw_user_meta_data->>'referred_by'), '');
    clean_ref := 'AVO' || UPPER(SUBSTRING(NEW.id::text, 1, 6));
    clean_avo_id := 'AVO' || nextval('public.avo_id_seq')::text;
    clean_username := COALESCE(
        NULLIF(REGEXP_REPLACE(
            LOWER(BTRIM(NEW.raw_user_meta_data->>'username')),
            '[^a-z0-9._-]', '', 'g'
        ), ''),
        REGEXP_REPLACE(LOWER(SPLIT_PART(NEW.email, '@', 1)),
            '[^a-z0-9._-]', '', 'g') || '_' ||
            LOWER(LEFT(REPLACE(NEW.id::text, '-', ''), 8))
    );

    -- Insert or update user profile
    INSERT INTO public.profiles (
        id, email, full_name, phone, avatar_url, referral_code, avo_id, username, referred_by
    )
    VALUES (
        NEW.id, NEW.email, clean_name, clean_phone, clean_avatar, clean_ref,
        clean_avo_id, clean_username, clean_referred_by
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        avo_id = COALESCE(NULLIF(profiles.avo_id, ''), EXCLUDED.avo_id),
        username = COALESCE(NULLIF(profiles.username, ''), EXCLUDED.username),
        referred_by = COALESCE(profiles.referred_by, EXCLUDED.referred_by),
        avatar_url = CASE
            WHEN profiles.avatar_url IS NULL OR profiles.avatar_url = ''
                THEN EXCLUDED.avatar_url
            ELSE profiles.avatar_url
        END,
        updated_at = NOW();

    -- Ensure a wallet is created with 0 balance
    INSERT INTO public.wallets (user_id, balance, currency)
    VALUES (NEW.id, 0.00, 'NGN')
    ON CONFLICT (user_id) DO NOTHING;

    -- Process mutual referral rewards if a valid referral code was supplied
    IF clean_referred_by IS NOT NULL AND clean_referred_by <> '' THEN
        SELECT id INTO v_referrer_id
          FROM public.profiles
         WHERE (UPPER(referral_code) = UPPER(clean_referred_by)
            OR UPPER(avo_id) = UPPER(clean_referred_by)
            OR UPPER(username) = UPPER(clean_referred_by))
           AND id <> NEW.id
         LIMIT 1;

        IF v_referrer_id IS NOT NULL THEN
            -- 1. Reward Referrer: ₦50 credit
            SELECT balance INTO v_ref_balance_before
              FROM public.wallets
             WHERE user_id = v_referrer_id
             FOR UPDATE;

            IF v_ref_balance_before IS NOT NULL THEN
                v_ref_balance_after := v_ref_balance_before + 50.00;

                UPDATE public.wallets
                   SET balance = v_ref_balance_after,
                       total_funded = total_funded + 50.00,
                       updated_at = NOW()
                 WHERE user_id = v_referrer_id;

                INSERT INTO public.transactions (
                    user_id, type, category, amount, balance_before, balance_after,
                    reference, narration, status
                )
                VALUES (
                    v_referrer_id, 'credit', 'referral_bonus', 50.00,
                    v_ref_balance_before, v_ref_balance_after,
                    'REF-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || FLOOR(RANDOM() * 9000 + 1000),
                    'Referral commission bonus for inviting ' || clean_name, 'completed'
                );
            END IF;

            -- 2. Reward Referee (New User): ₦25 welcome bonus
            UPDATE public.wallets
               SET balance = 25.00,
                   total_funded = 25.00,
                   updated_at = NOW()
             WHERE user_id = NEW.id;

            INSERT INTO public.transactions (
                user_id, type, category, amount, balance_before, balance_after,
                reference, narration, status
            )
            VALUES (
                NEW.id, 'credit', 'welcome_bonus', 25.00, 0.00, 25.00,
                'WLC-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || FLOOR(RANDOM() * 9000 + 1000),
                'Welcome registration bonus for joining via referral code ' || clean_referred_by, 'completed'
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

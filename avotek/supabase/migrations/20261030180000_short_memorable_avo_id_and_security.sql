-- 20261030180000_short_memorable_avo_id_and_security.sql
-- Assigns short, memorable, 5-digit AVO IDs (e.g. AVO10112) for all users and incoming sign-ups.

CREATE SEQUENCE IF NOT EXISTS public.avo_id_seq START WITH 10101 INCREMENT BY 1;

-- Backfill existing profiles to short memorable AVO ID format
UPDATE public.profiles
SET avo_id = 'AVO' || LPAD(((abs(hashtext(id::text)) % 90000) + 10000)::text, 5, '0')
WHERE avo_id IS NULL OR avo_id = '' OR avo_id LIKE 'AVO-%' OR LENGTH(avo_id) > 10;

-- Ensure uniqueness if any collision occurred during backfill
DO $$
DECLARE
    dup_row RECORD;
BEGIN
    FOR dup_row IN (
        SELECT id FROM public.profiles
        WHERE UPPER(avo_id) IN (
            SELECT UPPER(avo_id) FROM public.profiles
            GROUP BY UPPER(avo_id) HAVING COUNT(*) > 1
        )
    ) LOOP
        UPDATE public.profiles
        SET avo_id = 'AVO' || nextval('public.avo_id_seq')::text
        WHERE id = dup_row.id;
    END LOOP;
END $$;

-- Update unique index
DROP INDEX IF EXISTS public.profiles_avo_id_unique;
CREATE UNIQUE INDEX IF NOT EXISTS profiles_avo_id_unique
    ON public.profiles (UPPER(avo_id))
    WHERE avo_id IS NOT NULL;

-- Update handle_new_user trigger to assign short memorable AVO ID to all incoming sign-ups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    clean_name TEXT;
    clean_phone TEXT;
    clean_avatar TEXT;
    clean_ref TEXT;
    clean_avo_id TEXT;
    clean_username TEXT;
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

    INSERT INTO public.profiles (
        id, email, full_name, phone, avatar_url, referral_code, avo_id, username
    )
    VALUES (
        NEW.id, NEW.email, clean_name, clean_phone, clean_avatar, clean_ref,
        clean_avo_id, clean_username
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        avo_id = COALESCE(NULLIF(profiles.avo_id, ''), EXCLUDED.avo_id),
        username = COALESCE(NULLIF(profiles.username, ''), EXCLUDED.username),
        avatar_url = CASE
            WHEN profiles.avatar_url IS NULL OR profiles.avatar_url = ''
                THEN EXCLUDED.avatar_url
            ELSE profiles.avatar_url
        END,
        updated_at = NOW();

    INSERT INTO public.wallets (user_id, balance, currency)
    VALUES (NEW.id, 0.00, 'NGN')
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

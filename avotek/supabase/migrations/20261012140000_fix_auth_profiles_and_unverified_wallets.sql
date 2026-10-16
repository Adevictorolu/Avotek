ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS avo_id TEXT,
    ADD COLUMN IF NOT EXISTS username TEXT;

UPDATE public.profiles
SET avo_id = 'AVO-' || UPPER(LEFT(REPLACE(id::TEXT, '-', ''), 16))
WHERE avo_id IS NULL OR BTRIM(avo_id) = '' OR UPPER(avo_id) = 'AVO-10001';

UPDATE public.profiles
SET username = LOWER(REGEXP_REPLACE(SPLIT_PART(email, '@', 1),
        '[^a-z0-9._-]', '', 'g')) || '_' ||
    LOWER(LEFT(REPLACE(id::TEXT, '-', ''), 8))
WHERE username IS NULL OR BTRIM(username) = '';

WITH duplicate_ids AS (
    SELECT id
    FROM public.profiles
    WHERE UPPER(avo_id) IN (
        SELECT UPPER(avo_id)
        FROM public.profiles
        GROUP BY UPPER(avo_id)
        HAVING COUNT(*) > 1
    )
)
UPDATE public.profiles AS profile
SET avo_id = 'AVO-' || UPPER(REPLACE(profile.id::TEXT, '-', ''))
FROM duplicate_ids
WHERE profile.id = duplicate_ids.id;

WITH duplicate_usernames AS (
    SELECT id
    FROM public.profiles
    WHERE LOWER(username) IN (
        SELECT LOWER(username)
        FROM public.profiles
        GROUP BY LOWER(username)
        HAVING COUNT(*) > 1
    )
)
UPDATE public.profiles AS profile
SET username = LOWER(profile.username) || '_' ||
    LOWER(REPLACE(profile.id::TEXT, '-', ''))
FROM duplicate_usernames
WHERE profile.id = duplicate_usernames.id;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_avo_id_unique
    ON public.profiles (UPPER(avo_id))
    WHERE avo_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_username_unique
    ON public.profiles (LOWER(username))
    WHERE username IS NOT NULL;

ALTER TABLE public.wallets
    ALTER COLUMN virtual_account_bank DROP DEFAULT;

UPDATE public.wallets
SET virtual_account_number = NULL,
    virtual_account_bank = NULL,
    virtual_account_name = NULL
WHERE virtual_account_number ~ '^90[0-9]{8}$'
  AND virtual_account_bank = 'Wema Bank / PalmPay'
  AND virtual_account_name LIKE 'AVOTEK - %';

DROP POLICY IF EXISTS "Users can insert own wallet" ON public.wallets;
DROP POLICY IF EXISTS "Users can update own wallet" ON public.wallets;
REVOKE INSERT, UPDATE, DELETE ON public.wallets FROM anon, authenticated;
GRANT SELECT ON public.wallets TO authenticated;

DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
REVOKE INSERT, UPDATE, DELETE ON public.transactions FROM anon, authenticated;
GRANT SELECT ON public.transactions TO authenticated;

REVOKE ALL ON FUNCTION public.reserve_vtu_purchase(NUMERIC, TEXT, TEXT, TEXT)
    FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.finalize_vtu_purchase(UUID, TEXT, TEXT, TEXT)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_vtu_purchase(NUMERIC, TEXT, TEXT, TEXT)
    TO authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_vtu_purchase(UUID, TEXT, TEXT, TEXT)
    TO service_role;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
    clean_avo_id := 'AVO-' || UPPER(LEFT(REPLACE(NEW.id::text, '-', ''), 16));
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
$$;

WITH missing_users AS (
    SELECT
        auth_user.id,
        auth_user.email,
        auth_user.raw_user_meta_data,
        'AVO' || UPPER(LEFT(REPLACE(auth_user.id::TEXT, '-', ''), 6))
            AS short_referral_code,
        'AVO-' || UPPER(LEFT(REPLACE(auth_user.id::TEXT, '-', ''), 16))
            AS avo_id,
        LOWER(REGEXP_REPLACE(
            COALESCE(
                NULLIF(BTRIM(auth_user.raw_user_meta_data->>'username'), ''),
                SPLIT_PART(auth_user.email, '@', 1)
            ),
            '[^a-z0-9._-]', '', 'g'
        )) || '_' || LOWER(LEFT(REPLACE(auth_user.id::TEXT, '-', ''), 8))
            AS username
    FROM auth.users AS auth_user
    LEFT JOIN public.profiles AS profile ON profile.id = auth_user.id
    WHERE profile.id IS NULL
),
profile_values AS (
    SELECT
        missing_users.*,
        CASE
            WHEN NOT EXISTS (
                SELECT 1
                FROM public.profiles AS existing
                WHERE existing.referral_code = missing_users.short_referral_code
            )
            AND COUNT(*) OVER (
                PARTITION BY missing_users.short_referral_code
            ) = 1
                THEN missing_users.short_referral_code
            ELSE 'AVO' || UPPER(REPLACE(missing_users.id::TEXT, '-', ''))
        END AS referral_code
    FROM missing_users
)
INSERT INTO public.profiles (
    id,
    email,
    full_name,
    phone,
    avatar_url,
    referral_code,
    avo_id,
    username
)
SELECT
    id,
    email,
    COALESCE(
        NULLIF(raw_user_meta_data->>'full_name', ''),
        NULLIF(raw_user_meta_data->>'name', ''),
        NULLIF(SPLIT_PART(email, '@', 1), ''),
        'Avotek User'
    ),
    COALESCE(raw_user_meta_data->>'phone', ''),
    COALESCE(
        raw_user_meta_data->>'avatar_url',
        raw_user_meta_data->>'picture',
        ''
    ),
    referral_code,
    avo_id,
    username
FROM profile_values
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.wallets (user_id, balance, currency)
SELECT profile.id, 0.00, 'NGN'
FROM public.profiles AS profile
LEFT JOIN public.wallets AS wallet ON wallet.user_id = profile.id
WHERE wallet.user_id IS NULL
ON CONFLICT (user_id) DO NOTHING;

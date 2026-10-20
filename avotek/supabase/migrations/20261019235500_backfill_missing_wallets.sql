INSERT INTO public.wallets (user_id, balance, currency)
SELECT profile.id, 0.00, 'NGN'
FROM public.profiles AS profile
WHERE NOT EXISTS (
    SELECT 1
    FROM public.wallets AS wallet
    WHERE wallet.user_id = profile.id
)
ON CONFLICT (user_id) DO NOTHING;

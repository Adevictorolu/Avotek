REVOKE SELECT ON TABLE public.vtu_orders FROM PUBLIC, anon, authenticated;
REVOKE INSERT ON TABLE public.vtu_orders FROM PUBLIC, anon, authenticated;

GRANT SELECT (
    id,
    user_id,
    service_type,
    network,
    phone,
    plan,
    amount,
    status,
    token,
    created_at
) ON TABLE public.vtu_orders TO authenticated;

GRANT INSERT (
    id,
    user_id,
    service_type,
    network,
    phone,
    plan,
    amount,
    status,
    token,
    created_at
) ON TABLE public.vtu_orders TO authenticated;

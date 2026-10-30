CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        (current_setting('request.jwt.claims', true)::jsonb->>'role') = 'service_role'
        OR LOWER(auth.jwt()->>'email') IN ('ademolavictor869@gmail.com', 'avotek12@gmail.com')
        OR auth.uid() IN ('89fa6337-2d44-4df1-8894-844085af37c6'::uuid, 'f6681d1c-2956-415c-9d64-25169d2ace6b'::uuid),
        FALSE
    );
$$;

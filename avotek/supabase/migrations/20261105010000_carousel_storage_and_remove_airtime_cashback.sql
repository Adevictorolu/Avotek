INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
VALUES (
    'avotek-carousel',
    'avotek-carousel',
    TRUE,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Avotek carousel images are public" ON storage.objects;
CREATE POLICY "Avotek carousel images are public"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avotek-carousel');

DROP POLICY IF EXISTS "Avotek admins can upload carousel images" ON storage.objects;
CREATE POLICY "Avotek admins can upload carousel images"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'avotek-carousel' AND public.is_admin());

DROP POLICY IF EXISTS "Avotek admins can update carousel images" ON storage.objects;
CREATE POLICY "Avotek admins can update carousel images"
    ON storage.objects FOR UPDATE TO authenticated
    USING (bucket_id = 'avotek-carousel' AND public.is_admin())
    WITH CHECK (bucket_id = 'avotek-carousel' AND public.is_admin());

DROP POLICY IF EXISTS "Avotek admins can delete carousel images" ON storage.objects;
CREATE POLICY "Avotek admins can delete carousel images"
    ON storage.objects FOR DELETE TO authenticated
    USING (bucket_id = 'avotek-carousel' AND public.is_admin());

DROP FUNCTION IF EXISTS public.finalize_vtu_purchase_with_cashback(UUID, TEXT, TEXT, TEXT, NUMERIC);

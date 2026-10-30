-- Migration: KYC Tier 2 (NIN) and App Settings (APK Management)
-- Date: 2026-10-30

-- 1. Add NIN and kyc_tier columns to public.profiles if not existing
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS nin text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS kyc_tier integer DEFAULT 1;

-- 2. Create app_settings table for global system configurations (e.g. mobile APK downloads)
CREATE TABLE IF NOT EXISTS public.app_settings (
  key text PRIMARY KEY,
  value text NOT NULL,
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read app_settings" ON public.app_settings;
CREATE POLICY "Anyone can read app_settings"
  ON public.app_settings FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admin can update app_settings" ON public.app_settings;
CREATE POLICY "Admin can update app_settings"
  ON public.app_settings FOR ALL
  USING (
    auth.jwt() ->> 'email' = 'ademolavictor869@gmail.com'
    OR auth.role() = 'service_role'
  )
  WITH CHECK (
    auth.jwt() ->> 'email' = 'ademolavictor869@gmail.com'
    OR auth.role() = 'service_role'
  );

-- Seed default mobile APK download settings
INSERT INTO public.app_settings (key, value)
VALUES 
  ('apk_download_url', 'https://github.com/adevictorolu/Avotek/releases/latest/download/avotek.apk'),
  ('apk_version', 'v1.2.0')
ON CONFLICT (key) DO UPDATE 
SET value = EXCLUDED.value, updated_at = now();

-- 3. Create RPC to submit NIN for Tier 2 KYC verification
CREATE OR REPLACE FUNCTION public.submit_nin_kyc(p_nin text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_clean_nin text := regexp_replace(COALESCE(p_nin, ''), '\D', '', 'g');
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.';
  END IF;

  IF length(v_clean_nin) != 11 THEN
    RAISE EXCEPTION 'National Identity Number (NIN) must be exactly 11 digits.';
  END IF;

  UPDATE public.profiles
  SET 
    nin = v_clean_nin,
    kyc_status = 'verified',
    kyc_tier = 2,
    updated_at = now()
  WHERE id = v_user_id;

  RETURN jsonb_build_object(
    'status', 'success',
    'kyc_tier', 2,
    'kyc_status', 'verified',
    'message', 'Tier 2 KYC (NIN) verified successfully.'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.submit_nin_kyc(text) TO authenticated, service_role;

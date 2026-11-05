INSERT INTO public.app_settings (key, value)
VALUES (
  'pricing_overrides',
  '{"service_markup_multiplier":1,"price_rounding_increment":1,"cable_fee":0,"electricity_fee":0}'
)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
updated_at = now();

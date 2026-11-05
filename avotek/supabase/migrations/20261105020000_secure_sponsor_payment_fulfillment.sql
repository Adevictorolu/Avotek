CREATE TABLE IF NOT EXISTS public.sponsor_payments (
    reference TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    amount_kobo BIGINT NOT NULL CHECK (amount_kobo > 0),
    service TEXT NOT NULL,
    exam TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity BETWEEN 1 AND 10),
    recipient TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'initialized'
        CHECK (status IN ('initialized', 'processing', 'completed')),
    processing_started_at TIMESTAMPTZ,
    fulfillment JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.sponsor_payments ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.sponsor_payments FROM PUBLIC, anon, authenticated;
GRANT ALL ON public.sponsor_payments TO service_role;

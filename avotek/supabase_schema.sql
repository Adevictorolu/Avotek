-- ==============================================================================
-- AVOTEK VTU SUPABASE DATABASE SCHEMA (PostgreSQL)
-- Run this script inside your Supabase project SQL Editor
-- URL: https://gcixbqrridzgobkqnlfz.supabase.co
-- ==============================================================================

-- 1. PROFILES TABLE (Linked with Supabase Auth auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL DEFAULT 'Avotek User',
    phone TEXT DEFAULT '',
    avatar_url TEXT,
    avo_id TEXT,
    username TEXT,
    kyc_status TEXT DEFAULT 'tier1',
    referral_code TEXT UNIQUE,
    referred_by TEXT,
    transaction_pin_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avo_id TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS username TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_avo_id ON public.profiles(avo_id);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);

UPDATE public.profiles
SET avo_id = 'AVO-' || UPPER(SUBSTRING(REPLACE(id::text, '-', ''), 1, 12))
WHERE avo_id IS NULL OR avo_id = '';

UPDATE public.profiles
SET username = LOWER(SPLIT_PART(email, '@', 1))
WHERE username IS NULL OR username = '';

-- 2. WALLETS TABLE (Single Direct Wallet per user)
CREATE TABLE IF NOT EXISTS public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    currency TEXT NOT NULL DEFAULT 'NGN',
    virtual_account_number TEXT,
    virtual_account_bank TEXT,
    virtual_account_name TEXT,
    total_funded NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total_spent NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.wallets ALTER COLUMN virtual_account_bank DROP DEFAULT;
UPDATE public.wallets
SET virtual_account_number = NULL,
    virtual_account_bank = NULL,
    virtual_account_name = NULL
WHERE virtual_account_number ~ '^90[0-9]{8}$'
  AND virtual_account_bank IN ('Wema Bank / PalmPay', 'Wema Bank / Moniepoint');

-- 3. TRANSACTIONS TABLE (Immutable Financial Ledger)
CREATE TABLE IF NOT EXISTS public.transactions (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('credit', 'debit')),
    category TEXT NOT NULL, -- 'airtime', 'data', 'electricity', 'cable', 'wallet_fund'
    amount NUMERIC(12, 2) NOT NULL,
    balance_before NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    balance_after NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    reference TEXT NOT NULL UNIQUE,
    narration TEXT,
    status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'pending', 'failed')),
    idempotency_key TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. VTU ORDERS TABLE (VTU Deliveries)
CREATE TABLE IF NOT EXISTS public.vtu_orders (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    service_type TEXT NOT NULL, -- 'airtime', 'data', 'electricity', 'cable'
    network TEXT NOT NULL,
    phone TEXT NOT NULL,
    plan TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'successful' CHECK (status IN ('successful', 'pending', 'failed')),
    provider_reference TEXT,
    token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. AUTOMATIC TRIGGER: Create Profile & Wallet on Auth Signup (Email & Google OAuth)
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
    -- Extract full name from Google metadata or email
    clean_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1)
    );
    clean_phone := COALESCE(NEW.raw_user_meta_data->>'phone', '');
    clean_username := COALESCE(
        NULLIF(NEW.raw_user_meta_data->>'username', ''),
        LOWER(SPLIT_PART(NEW.email, '@', 1))
    );
    clean_avo_id := 'AVO-' || UPPER(SUBSTRING(REPLACE(NEW.id::text, '-', ''), 1, 12));
    -- Extract avatar picture from Google metadata
    clean_avatar := COALESCE(
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'picture',
        ''
    );
    clean_ref := 'AVO' || UPPER(SUBSTRING(REPLACE(NEW.id::text, '-', ''), 1, 12));

    -- Insert or update public.profiles
    INSERT INTO public.profiles (
        id, email, full_name, phone, avatar_url, avo_id, username, referral_code
    )
    VALUES (
        NEW.id, NEW.email, clean_name, clean_phone, clean_avatar,
        clean_avo_id, clean_username, clean_ref
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        avo_id = COALESCE(profiles.avo_id, EXCLUDED.avo_id),
        username = COALESCE(profiles.username, EXCLUDED.username),
        avatar_url = CASE 
            WHEN profiles.avatar_url IS NULL OR profiles.avatar_url = '' THEN EXCLUDED.avatar_url 
            ELSE profiles.avatar_url 
        END,
        updated_at = NOW();

    -- Insert into public.wallets (Single Direct Wallet)
    INSERT INTO public.wallets (
        user_id,
        balance,
        currency,
        virtual_account_number,
        virtual_account_bank,
        virtual_account_name
    )
    VALUES (
        NEW.id,
        0.00,
        'NGN',
        NULL,
        NULL,
        NULL
    )
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger hook
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vtu_orders ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can view, insert & update their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Wallets: Users may read only their own wallet; only trusted backend code writes.
DROP POLICY IF EXISTS "Users can view own wallet" ON public.wallets;
CREATE POLICY "Users can view own wallet" ON public.wallets
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own wallet" ON public.wallets;
DROP POLICY IF EXISTS "Users can update own wallet" ON public.wallets;

-- Transactions: Users can view own transactions
DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
CREATE POLICY "Users can view own transactions" ON public.transactions
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;

-- VTU Orders: Users may read only their own orders; only trusted backend code writes.
DROP POLICY IF EXISTS "Users can view own orders" ON public.vtu_orders;
CREATE POLICY "Users can view own orders" ON public.vtu_orders
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own orders" ON public.vtu_orders;

REVOKE INSERT, UPDATE, DELETE ON public.wallets FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.transactions FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.vtu_orders FROM anon, authenticated;

-- Indexes for lightning fast queries
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_vtu_orders_user_id ON public.vtu_orders(user_id);

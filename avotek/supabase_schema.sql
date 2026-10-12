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
    kyc_status TEXT DEFAULT 'tier1',
    referral_code TEXT UNIQUE,
    referred_by TEXT,
    transaction_pin_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS avo_id TEXT,
    ADD COLUMN IF NOT EXISTS username TEXT;

UPDATE public.profiles
SET avo_id = 'AVO-' || UPPER(LEFT(REPLACE(id::TEXT, '-', ''), 16))
WHERE avo_id IS NULL OR BTRIM(avo_id) = '' OR UPPER(avo_id) = 'AVO-10001';

UPDATE public.profiles
SET username = LOWER(SPLIT_PART(email, '@', 1)) || '_' ||
    LOWER(LEFT(REPLACE(id::TEXT, '-', ''), 8))
WHERE username IS NULL OR BTRIM(username) = '';

WITH duplicate_ids AS (
    SELECT id
    FROM public.profiles
    GROUP BY UPPER(avo_id)
    HAVING COUNT(*) > 1
)
UPDATE public.profiles AS profile
SET avo_id = 'AVO-' || UPPER(REPLACE(profile.id::TEXT, '-', ''))
FROM duplicate_ids
WHERE profile.id = duplicate_ids.id;

WITH duplicate_usernames AS (
    SELECT id
    FROM public.profiles
    GROUP BY LOWER(username)
    HAVING COUNT(*) > 1
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

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    generated_avo_id TEXT;
    generated_username TEXT;
BEGIN
    generated_avo_id :=
        'AVO-' || UPPER(LEFT(REPLACE(NEW.id::TEXT, '-', ''), 16));
    generated_username := COALESCE(
        NULLIF(LOWER(BTRIM(NEW.raw_user_meta_data->>'username')), ''),
        REGEXP_REPLACE(LOWER(SPLIT_PART(NEW.email, '@', 1)),
            '[^a-z0-9._-]', '', 'g') || '_' ||
            LOWER(LEFT(REPLACE(NEW.id::TEXT, '-', ''), 8))
    );

    INSERT INTO public.profiles (
        id, email, full_name, phone, referral_code, avo_id, username
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NULLIF(NEW.raw_user_meta_data->>'full_name', ''), 'Avotek User'),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        generated_avo_id,
        generated_avo_id,
        generated_username
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

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

ALTER TABLE public.wallets
    ALTER COLUMN virtual_account_bank DROP DEFAULT;

UPDATE public.wallets
SET virtual_account_number = NULL,
    virtual_account_bank = NULL,
    virtual_account_name = NULL
WHERE virtual_account_number ~ '^90[0-9]{8}$'
  AND virtual_account_bank = 'Wema Bank / PalmPay'
  AND virtual_account_name LIKE 'AVOTEK - %';

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
    -- Extract avatar picture from Google metadata
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

    -- Insert or update public.profiles
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
            WHEN profiles.avatar_url IS NULL OR profiles.avatar_url = '' THEN EXCLUDED.avatar_url 
            ELSE profiles.avatar_url 
        END,
        updated_at = NOW();

    -- Insert into public.wallets (Single Direct Wallet)
    INSERT INTO public.wallets (user_id, balance, currency)
    VALUES (NEW.id, 0.00, 'NGN')
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
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Wallet balances are readable by their owner and writable only by trusted
-- database functions or server-side payment providers.
CREATE POLICY "Users can view own wallet" ON public.wallets
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own wallet" ON public.wallets;
DROP POLICY IF EXISTS "Users can update own wallet" ON public.wallets;
REVOKE INSERT, UPDATE, DELETE ON public.wallets FROM anon, authenticated;
GRANT SELECT ON public.wallets TO authenticated;

-- Transactions: Users can view own transactions
CREATE POLICY "Users can view own transactions" ON public.transactions
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
REVOKE INSERT, UPDATE, DELETE ON public.transactions FROM anon, authenticated;
GRANT SELECT ON public.transactions TO authenticated;

-- VTU Orders: Users can view and insert own orders
CREATE POLICY "Users can view own orders" ON public.vtu_orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own orders" ON public.vtu_orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Indexes for lightning fast queries
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_vtu_orders_user_id ON public.vtu_orders(user_id);

-- VTU debits are reserved and finalized atomically by the authenticated
-- Bigisub Edge Function. The client must not write wallet balances directly.
CREATE OR REPLACE FUNCTION public.reserve_vtu_purchase(
    p_amount NUMERIC,
    p_reference TEXT,
    p_category TEXT,
    p_narration TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    account_id UUID := auth.uid();
    current_status TEXT;
    previous_amount NUMERIC;
    balance_after NUMERIC;
BEGIN
    IF account_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    IF p_amount <= 0 OR p_amount > 1000000 THEN
        RAISE EXCEPTION 'Invalid purchase amount';
    END IF;
    IF p_reference IS NULL OR LENGTH(p_reference) < 12 OR LENGTH(p_reference) > 120 THEN
        RAISE EXCEPTION 'Invalid purchase reference';
    END IF;

    SELECT status, amount
      INTO current_status, previous_amount
      FROM public.transactions
     WHERE reference = p_reference
       AND user_id = account_id;

    IF FOUND THEN
        IF previous_amount <> p_amount THEN
            RAISE EXCEPTION 'Reference already used for a different amount';
        END IF;
        RETURN jsonb_build_object(
            'reserved', current_status IN ('pending', 'completed'),
            'status', current_status,
            'idempotent', TRUE
        );
    END IF;

    UPDATE public.wallets
       SET balance = balance - p_amount,
           total_spent = total_spent + p_amount,
           updated_at = NOW()
     WHERE user_id = account_id
       AND balance >= p_amount
     RETURNING balance INTO balance_after;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Insufficient wallet balance';
    END IF;

    INSERT INTO public.transactions (
        user_id, type, category, amount, balance_before, balance_after,
        reference, narration, status, idempotency_key
    )
    VALUES (
        account_id, 'debit', p_category, p_amount, balance_after + p_amount,
        balance_after, p_reference, p_narration, 'pending', p_reference
    );

    RETURN jsonb_build_object(
        'reserved', TRUE,
        'status', 'pending',
        'balance_after', balance_after
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.finalize_vtu_purchase(
    p_user_id UUID,
    p_reference TEXT,
    p_status TEXT,
    p_narration TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    account_id UUID := p_user_id;
    purchase_amount NUMERIC;
    purchase_status TEXT;
    current_balance NUMERIC;
BEGIN
    IF account_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required';
    END IF;
    IF p_status NOT IN ('completed', 'pending', 'failed') THEN
        RAISE EXCEPTION 'Invalid purchase status';
    END IF;

    SELECT amount, status
      INTO purchase_amount, purchase_status
      FROM public.transactions
     WHERE reference = p_reference
       AND user_id = account_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Purchase reservation not found';
    END IF;

    IF purchase_status <> 'pending' THEN
        RETURN jsonb_build_object(
            'status', purchase_status,
            'finalized', FALSE
        );
    END IF;

    IF p_status = 'failed' THEN
        UPDATE public.wallets
           SET balance = balance + purchase_amount,
               total_spent = GREATEST(0, total_spent - purchase_amount),
               updated_at = NOW()
         WHERE user_id = account_id
         RETURNING balance INTO current_balance;

        UPDATE public.transactions
           SET status = 'failed',
               balance_after = COALESCE(current_balance, balance_after),
               narration = COALESCE(p_narration, narration)
         WHERE reference = p_reference
           AND user_id = account_id;
    ELSE
        UPDATE public.transactions
           SET status = p_status,
               narration = COALESCE(p_narration, narration)
         WHERE reference = p_reference
           AND user_id = account_id;
    END IF;

    RETURN jsonb_build_object('status', p_status, 'finalized', TRUE);
END;
$$;

REVOKE ALL ON FUNCTION public.reserve_vtu_purchase(NUMERIC, TEXT, TEXT, TEXT)
    FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.finalize_vtu_purchase(UUID, TEXT, TEXT, TEXT)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_vtu_purchase(NUMERIC, TEXT, TEXT, TEXT)
    TO authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_vtu_purchase(UUID, TEXT, TEXT, TEXT)
    TO service_role;

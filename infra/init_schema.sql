-- ====================================================================
-- AVOTEK PLATFORM — POSTGRESQL PRODUCTION & DEMO SCHEMA INITIALIZER
-- Motto: Leveraging Technology in Education
-- Tables: users, wallets, transactions, orders, service_catalog, audit_logs
-- ====================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    phone VARCHAR(32) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    otp_state VARCHAR(64),
    transaction_pin_hash VARCHAR(255),
    kyc_status VARCHAR(32) DEFAULT 'tier1', -- tier1, tier2, tier3
    referral_code VARCHAR(64) UNIQUE NOT NULL,
    referred_by VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code);

-- 3. WALLETS TABLE (Double-entry Ledger Anchor)
CREATE TABLE IF NOT EXISTS wallets (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    currency VARCHAR(8) DEFAULT 'NGN',
    virtual_account_number VARCHAR(32),
    virtual_account_bank VARCHAR(128) DEFAULT 'Wema Bank / Moniepoint',
    virtual_account_name VARCHAR(255),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_wallet UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallets_va_num ON wallets(virtual_account_number);

-- 4. TRANSACTIONS LEDGER (Immutable Audit)
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(32) NOT NULL, -- 'credit', 'debit', 'refund', 'topup', 'cashback'
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    balance_before NUMERIC(15, 2) NOT NULL,
    balance_after NUMERIC(15, 2) NOT NULL,
    reference VARCHAR(128) UNIQUE NOT NULL,
    status VARCHAR(32) DEFAULT 'completed', -- 'pending', 'completed', 'failed', 'reversed'
    description TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_reference ON transactions(reference);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);

-- 5. ORDERS TABLE (VTU, Academic Exam PINs, Electricity, Cable)
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    service_type VARCHAR(64) NOT NULL, -- 'data', 'airtime', 'exam_pin', 'electricity', 'cable'
    network_provider VARCHAR(64) NOT NULL, -- 'MTN', 'AIRTEL', 'GLO', '9MOBILE', 'WAEC', 'JAMB', 'IKEDC', etc.
    recipient_identifier VARCHAR(128) NOT NULL, -- Phone number, Meter number, Smartcard number
    amount NUMERIC(15, 2) NOT NULL,
    cost_price NUMERIC(15, 2) NOT NULL,
    sell_price NUMERIC(15, 2) NOT NULL,
    provider_reference VARCHAR(128),
    status VARCHAR(32) DEFAULT 'pending', -- 'pending', 'success', 'failed', 'reversed'
    channel VARCHAR(32) DEFAULT 'mobile', -- 'mobile', 'web', 'whatsapp', 'api'
    idempotency_key VARCHAR(128) UNIQUE NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- 6. SERVICE CATALOG (Pricing & Margin Control)
CREATE TABLE IF NOT EXISTS service_catalog (
    id SERIAL PRIMARY KEY,
    category VARCHAR(64) NOT NULL, -- 'airtime', 'data', 'exam_pin', 'electricity', 'cable'
    name VARCHAR(128) NOT NULL,
    service_code VARCHAR(64) UNIQUE NOT NULL,
    network_provider VARCHAR(64) NOT NULL,
    cost_price NUMERIC(15, 2) NOT NULL,
    default_markup NUMERIC(5, 2) NOT NULL DEFAULT 2.50, -- Percentage markup
    sell_price NUMERIC(15, 2) NOT NULL,
    active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 7. AUDIT LOGS
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    admin_id INT,
    action VARCHAR(64) NOT NULL,
    entity_type VARCHAR(64) NOT NULL,
    entity_id VARCHAR(64) NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ====================================================================
-- SEED DATA (INITIAL SERVICE CATALOG & DEMO ACCOUNTS)
-- ====================================================================

-- Seed Service Catalog
INSERT INTO service_catalog (category, name, service_code, network_provider, cost_price, default_markup, sell_price, active)
VALUES
  -- MTN Data
  ('data', 'MTN SME 1.0GB (30 Days)', 'MTN-DATA-1GB', 'MTN', 260.00, 3.85, 270.00, true),
  ('data', 'MTN SME 2.0GB (30 Days)', 'MTN-DATA-2GB', 'MTN', 520.00, 3.85, 540.00, true),
  ('data', 'MTN Corporate 5.0GB (30 Days)', 'MTN-DATA-5GB', 'MTN', 1300.00, 3.85, 1350.00, true),
  ('data', 'MTN Gifting 10.0GB (30 Days)', 'MTN-DATA-10GB', 'MTN', 2600.00, 3.85, 2700.00, true),
  -- Airtel Data
  ('data', 'Airtel CG 1.0GB (30 Days)', 'AIRTEL-DATA-1GB', 'AIRTEL', 265.00, 3.77, 275.00, true),
  ('data', 'Airtel CG 2.0GB (30 Days)', 'AIRTEL-DATA-2GB', 'AIRTEL', 530.00, 3.77, 550.00, true),
  ('data', 'Airtel CG 5.0GB (30 Days)', 'AIRTEL-DATA-5GB', 'AIRTEL', 1325.00, 3.77, 1375.00, true),
  -- Glo Data
  ('data', 'Glo SME 1.0GB (30 Days)', 'GLO-DATA-1GB', 'GLO', 240.00, 4.17, 250.00, true),
  ('data', 'Glo SME 2.0GB (30 Days)', 'GLO-DATA-2GB', 'GLO', 480.00, 4.17, 500.00, true),
  -- 9mobile Data
  ('data', '9mobile SME 1.5GB (30 Days)', '9MOB-DATA-1.5GB', '9MOBILE', 250.00, 4.00, 260.00, true),
  -- Educational Exam PINs (Avotek Core Academic Services)
  ('exam_pin', 'WAEC Result Checker PIN (Instant)', 'EXAM-WAEC-01', 'WAEC', 3450.00, 1.45, 3500.00, true),
  ('exam_pin', 'NECO Token (Direct Result Checker)', 'EXAM-NECO-01', 'NECO', 1150.00, 4.35, 1200.00, true),
  ('exam_pin', 'JAMB UTME e-PIN (With Mock)', 'EXAM-JAMB-01', 'JAMB', 7600.00, 1.32, 7700.00, true),
  ('exam_pin', 'NABTEB Result Checker e-PIN', 'EXAM-NABTEB-01', 'NABTEB', 1450.00, 3.45, 1500.00, true)
ON CONFLICT (service_code) DO NOTHING;

-- Seed Demo User for Immediate Testing
INSERT INTO users (id, phone, email, name, password_hash, kyc_status, referral_code, created_at)
VALUES (
    1,
    '08031234567',
    'demo@avotek.africa',
    'Chukwuemeka Obi',
    '$2a$10$w8T0yM5t3P3U0K.g0w4Yeu2q7i2h0gQ9jA3f7k8k1.4J5g9n9h5S', -- hashed 'password123'
    'tier2',
    'AVOTEK01',
    NOW()
) ON CONFLICT (phone) DO NOTHING;

INSERT INTO wallets (user_id, balance, currency, virtual_account_number, virtual_account_bank, virtual_account_name, updated_at)
VALUES (
    1,
    25000.00, -- ₦25,000 Sandbox Balance
    'NGN',
    '9031234567',
    'Wema Bank / Moniepoint',
    'AVOTEK - Chukwuemeka Obi',
    NOW()
) ON CONFLICT (user_id) DO NOTHING;

-- Seed Sample Transactions
INSERT INTO transactions (user_id, type, amount, balance_before, balance_after, reference, status, description, created_at)
VALUES
  (1, 'topup', 25000.00, 0.00, 25000.00, 'TX-AVO-INIT-001', 'completed', 'Dedicated Virtual Account Transfer (Wema Bank)', NOW() - INTERVAL '2 hours'),
  (1, 'debit', 540.00, 25000.00, 24460.00, 'TX-AVO-DATA-002', 'completed', 'Data Top-Up: MTN SME 2.0GB to 08031234567', NOW() - INTERVAL '1 hour'),
  (1, 'debit', 3500.00, 24460.00, 20960.00, 'TX-AVO-EXAM-003', 'completed', 'WAEC Result Checker PIN purchase (Token: 981245019284)', NOW() - INTERVAL '30 minutes')
ON CONFLICT (reference) DO NOTHING;

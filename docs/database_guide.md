# AVOTEK Custom Backend & Database Architecture Guide
**Motto: Leveraging Technology in Education**

This guide provides everything you need to know about the Avotek custom backend (PostgreSQL + Serverpod ORM), how to access user registrations, monitor data purchases, and manage transactions directly via SQL or the built-in Admin Panel.

---

## 1. Where User Data is Stored

All user information and transactions are stored in your custom PostgreSQL database:
- **Database Name**: `avotek`
- **Host**: `localhost` (or `postgres` inside Docker)
- **Port**: `5432`
- **Tables**:
  - `users`: Phone numbers, emails, full names, KYC verification levels, referral codes, timestamps.
  - `wallets`: User balances (NGN), dedicated virtual bank account numbers (Wema/Moniepoint), bank account names.
  - `transactions`: Immutable audit log of every top-up, debit, refund, and cashback with before/after balances.
  - `orders`: Every data top-up, airtime recharge, WAEC/JAMB exam PIN, electricity token, and cable subscription.
  - `service_catalog`: Wholesale cost prices, default markups, retail sell prices, and active status.
  - `audit_logs`: Administrative actions, manual refunds, and security audits.

---

## 2. Essential SQL Queries to Access User Data

You can run these queries directly using **pgAdmin**, **DBeaver**, or the `psql` command line:

### A. View All Registered Users & Live Wallet Balances
```sql
SELECT 
    u.id AS user_id,
    u.name,
    u.phone,
    u.email,
    u.kyc_status,
    w.balance AS current_balance_ngn,
    w.virtual_account_number,
    w.virtual_account_bank,
    u.created_at AS registration_date
FROM users u
LEFT JOIN wallets w ON u.id = w.user_id
ORDER BY u.created_at DESC;
```

### B. Track How Users Buy Data (Data Top-Up Ledger)
```sql
SELECT 
    o.id AS order_id,
    u.name AS customer_name,
    u.phone AS customer_phone,
    o.network_provider,
    o.recipient_identifier AS recipient_phone,
    o.sell_price AS amount_paid,
    o.cost_price,
    (o.sell_price - o.cost_price) AS profit,
    o.status,
    o.provider_reference,
    o.created_at
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.service_type = 'data'
ORDER BY o.created_at DESC;
```

### C. Check a Specific User's Full Transaction History
```sql
SELECT 
    t.created_at,
    t.reference,
    t.type,
    t.amount,
    t.balance_before,
    t.balance_after,
    t.description,
    t.status
FROM transactions t
WHERE t.user_id = 1
ORDER BY t.created_at DESC;
```

### D. Credit a User's Wallet Manually
```sql
-- Step 1: Update wallet balance
UPDATE wallets 
SET balance = balance + 5000.00, updated_at = NOW() 
WHERE user_id = 1;

-- Step 2: Insert ledger record
INSERT INTO transactions (user_id, type, amount, balance_before, balance_after, reference, status, description, created_at)
SELECT 
    1, 
    'credit', 
    5000.00, 
    balance - 5000.00, 
    balance, 
    'MANUAL-CREDIT-' || EXTRACT(EPOCH FROM NOW())::INT, 
    'completed', 
    'Admin manual top-up credit', 
    NOW()
FROM wallets WHERE user_id = 1;
```

---

## 3. How to Start the Backend Locally

```bash
# Option 1: Start PostgreSQL and Redis via Docker Compose
cd infra
docker compose up -d postgres redis

# Option 2: Run the Serverpod backend
cd ../avotek/avotek_server
dart bin/main.dart
```

Once running, the backend provides:
- **RPC API**: `http://localhost:8080/`
- **Serverpod Web Insights**: `http://localhost:8081/`
- **Webhooks & Health**: `http://localhost:8082/`

---

## 4. Built-In In-App Admin Dashboard

Don't want to type SQL? Simply click the **Admin Portal** icon in the top app bar of the Avotek application:
- **Orders Tab**: View real-time data purchases, airtime, and exam PIN orders with one-tap instant refunds.
- **Service Catalog**: Adjust wholesale prices, markup percentages, and activate/deactivate data packages.
- **User Directory**: View all registered users, phone numbers, emails, and balances right from your phone or web browser!

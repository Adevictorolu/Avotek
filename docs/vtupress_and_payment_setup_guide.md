# AVOTEK VTUPress, Aggregator Keys & Payments Setup Guide

This guide provides step-by-step instructions on how to set up **VTUPress**, **VTpass**, **ClubKonnect**, and **Paystack** for AVOTEK, how to retrieve all API keys and secret keys, fund your float balances, and ensure the frontend and backend operate synchronously.

---

## 1. Understanding VTUPress vs. Upstream Providers

**VTUPress** (`vtupress.com`) is a widely used WordPress software and plugin in Nigeria for creating Virtual Top-Up platforms.

### Scenario A: You Own an Existing VTUPress Website
If you already have an existing WordPress VTU website powered by the VTUPress plugin:
1. Log in to your **WordPress Admin Dashboard** (`yourwebsite.com/wp-admin`).
2. Navigate to **VTUPress** in the sidebar.
3. Go to **Settings > API Configuration** (or **API Importer**).
4. Under **Developer API / REST API**, generate or copy your **API Key / Secret Token**.
5. Set these in AVOTEK:
   - `VTUPRESS_URL=https://yourwebsite.com`
   - `VTUPRESS_API_KEY=your_api_key_here`

### Scenario B: You Connect Upstream Telco Providers (VTpass & ClubKonnect)
VTUPress itself connects to upstream providers like **VTpass** and **ClubKonnect** to vend airtime and data. You can connect AVOTEK directly to these providers for lower wholesale rates and higher speed:
1. **VTpass** (`vtpass.com`): Primary aggregator for instant MTN/Airtel/Glo/9mobile data, airtime, electricity disco tokens, cable TV, and exam PINs.
2. **ClubKonnect** (`clubkonnect.com`): Secondary fallback aggregator offering discounted SME data.

---

## 2. Step-by-Step: Getting Keys & Setting Up Providers

### 2.1 VTpass (Primary Provider)
1. **Create / Log In to Account:**
   - Go to [vtpass.com](https://www.vtpass.com) and sign in.
2. **Retrieve API Keys:**
   - Go to **Developer Tools** or **API Keys** in your dashboard.
   - Copy:
     - **API Key** (`VTPASS_API_KEY`)
     - **Secret Key** (`VTPASS_SECRET_KEY`)
     - **Public Key** (`VTPASS_PUBLIC_KEY`)
3. **Fund Float Balance:**
   - Click **Fund Wallet** on the VTpass dashboard.
   - Transfer money to your assigned Providus or Wema Bank dedicated account.
   - *Recommended initial float:* ₦50,000 – ₦200,000. When customers purchase data or airtime in AVOTEK, VTpass debits this float.

### 2.2 ClubKonnect (Fallback Provider)
1. **Create / Log In to Account:**
   - Go to [clubkonnect.com](https://www.clubkonnect.com) and sign in.
2. **Retrieve API Keys:**
   - Navigate to **Developer API** / **Integration**.
   - Copy your **UserID** (`CK_USER_ID`) and **API Key** (`CK_API_KEY`).
3. **Fund Wallet:**
   - Fund your wallet using bank transfer or Monnify automated funding.

---

## 3. Paystack Automated Payments & Customer Virtual Accounts

AVOTEK automates customer wallet funding using **Dedicated Virtual Accounts (DVA)**. Every user registered on AVOTEK gets an automated Wema Bank or Titan Trust account number. When the customer makes a bank transfer, Paystack instantly pings AVOTEK via webhook to credit their wallet.

### 3.1 Obtaining Paystack Live Keys
1. Log in to [dashboard.paystack.com](https://dashboard.paystack.com).
2. Complete business compliance (Tier 2 or Tier 3).
3. Switch toggle to **Live Mode** in the top navigation.
4. Go to **Settings > API Keys & Webhooks**.
5. Copy:
   - **Secret Key:** `sk_live_...`
   - **Public Key:** `pk_live_...`
6. Under **Preferences**, enable **Dedicated Virtual Accounts**.

### 3.2 Setting the Paystack Webhook
1. On the same **API Keys & Webhooks** page, locate **Live Webhook URL**.
2. Set your production webhook URL:
   ```text
   https://api.yourdomain.com:8082/webhook/paystack
   ```
   *(Or through Nginx/reverse proxy: `https://api.yourdomain.com/webhook/paystack`)*
3. When transfers arrive, AVOTEK verifies the `x-paystack-signature` using HMAC SHA512 and credits the customer's wallet instantly with atomic ledger locking.

---

## 4. Configuring Backend Environment Variables

Create or update your `.env` in `infra/` or your deployment platform (Docker, Railway, Render, VPS):

```bash
# --- VTUPress (Optional Direct Reseller API) ---
VTUPRESS_URL=https://yourvtuwebsite.com
VTUPRESS_API_KEY=your_vtupress_api_key

# --- VTpass (Primary) ---
VTPASS_API_KEY=your_vtpass_api_key
VTPASS_SECRET_KEY=your_vtpass_secret_key
VTPASS_PUBLIC_KEY=your_vtpass_public_key
VTPASS_BASE_URL=https://api-service.vtpass.com/api

# --- ClubKonnect (Fallback) ---
CK_USER_ID=your_clubkonnect_userid
CK_API_KEY=your_clubkonnect_apikey
CK_BASE_URL=https://www.clubkonnect.com/api

# --- Paystack Payments ---
PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxxxxxxxxxx
PAYSTACK_PUBLIC_KEY=pk_live_xxxxxxxxxxxxxxxxxxxxxxxx
PAYSTACK_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxx
```

> **Note on Sandbox Mode:** If no third-party keys are supplied, AVOTEK automatically activates `MockAggregator`, supplying simulated tokens, instant approvals, and mock transactions so you can test all features end-to-end without spending real money.

---

## 5. Synchronous Operation (Frontend + Backend)

1. **Client URL Resolution:**
   - On Flutter Web, `ClientProvider` automatically routes to your live domain or respects build-time defines:
     ```bash
     flutter build web --release --dart-define=SERVER_URL=https://api.yourdomain.com:8080/
     ```
2. **Failover Execution:**
   - Frontend calls `client.order.buyData(...)`.
   - Backend checks user wallet balance atomically in PostgreSQL.
   - Backend attempts primary provider (VTUPress or VTpass).
   - If primary provider is offline or times out, backend automatically invokes fallback (ClubKonnect) without customer drop-off.
   - If both fail, the transaction auto-reverses with zero fund loss.

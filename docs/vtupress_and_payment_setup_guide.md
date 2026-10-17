# AVOTEK VTUPress, Aggregator Keys & Payments Setup Guide

> **Legacy guide:** The current app does not use the Serverpod/VTUPress,
> VTpass, ClubKonnect, or automatic mock-aggregator setup described here.
> Wallet funding currently uses Paystack hosted checkout through the
> `paystack-payments` Supabase Edge Function. Follow
> [`AVOTEK_GO_LIVE_STATUS.md`](./AVOTEK_GO_LIVE_STATUS.md) for the current
> deployment and testing steps. Dedicated virtual accounts and automatic
> simulated payments are not implemented.

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

## 3. Paystack Hosted Checkout (current integration)

The current wallet-funding flow creates a hosted Paystack checkout session from
the authenticated Supabase Edge Function. It does not provision dedicated
virtual accounts or accept manual bank transfers as proof of payment.

### 3.1 Configure keys and URLs

1. Start with Paystack **Test Mode** and save its secret key in Supabase
   Edge Function secrets as `PAYSTACK_SECRET_KEY`. Do not put it in Flutter,
   Git, chat, or logs.
2. Set `PAYSTACK_CALLBACK_URL` to
   `https://adevictorolu.github.io/Avotek/#/wallet/fund`.
3. Set Paystack's webhook URL to
   `https://gcixbqrridzgobkqnlfz.supabase.co/functions/v1/paystack-payments`.
   This is the webhook endpoint; the callback is only the customer's return
   URL. Do not configure a separate `PAYSTACK_WEBHOOK_SECRET`; the function
   verifies `x-paystack-signature` with `PAYSTACK_SECRET_KEY`.
4. Follow the Test-mode and Live-mode verification steps in
   [`AVOTEK_GO_LIVE_STATUS.md`](./AVOTEK_GO_LIVE_STATUS.md). A Live secret key
   or configured URL alone does not establish that wallet funding works.

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

# Current Paystack secrets belong in Supabase Edge Function secrets, not this
# legacy Serverpod .env:
# PAYSTACK_SECRET_KEY=<Paystack test/live secret key>
# PAYSTACK_CALLBACK_URL=https://adevictorolu.github.io/Avotek/#/wallet/fund
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

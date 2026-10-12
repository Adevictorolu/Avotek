# AVOTEK Production Readiness & Gateway Configuration Guide

This comprehensive guide details the exact steps required to take the **AVOTEK VTU & Financial Services Platform** live, configure payment gateways and telco aggregators, fund working capital (float), manage CAC registration workflows, and secure the Super Admin portal.

---

## Table of Contents
1. [Overview & Architectural Topography](#1-overview--architectural-topography)
2. [Paystack Live Setup (Dedicated NUBAN & Webhooks)](#2-paystack-live-setup-dedicated-nuban--webhooks)
3. [Bigisub VTU Setup & Float Funding](#3-bigisub-vtu-setup--float-funding)
4. [WhatsApp Cloud API & Termii SMS Setup](#4-whatsapp-cloud-api--termii-sms-setup)
5. [CAC Business Registration Operations](#5-cac-business-registration-operations)
6. [Dynamic Catalog & Pricing Margins](#6-dynamic-catalog--pricing-margins)
7. [Super Admin Security & Gateway Access](#7-super-admin-security--gateway-access)
8. [Serverpod Backend & Docker Production Deployment](#8-serverpod-backend--docker-production-deployment)
9. [Pre-Launch Verification Checklist](#9-pre-launch-verification-checklist)
10. [Supabase Authentication Setup](#10-supabase-authentication-setup)

---

## 1. Overview & Architectural Topography

AVOTEK runs on a high-throughput architecture consisting of:
- **Client Frontend**: Flutter cross-platform client (Web, Android, iOS) with Plus Jakarta Sans typography, light/dark themes, zero-distortion brand assets, and discreet admin routing.
- **Authentication & database**: Supabase Auth, PostgreSQL, and Edge Functions.
- **VTU provider**: Bigisub is called through the authenticated `bigisub` Edge Function.

> **Live status:** wallet top-ups, dedicated virtual accounts, Paystack webhooks, WhatsApp messages, and Termii messages are not implemented or configured in this repository. Do not advertise live payments until the checklist in [`GO_LIVE_NEXT_STEPS.md`](./GO_LIVE_NEXT_STEPS.md) is complete. Wallet funding intentionally remains unavailable rather than showing fabricated bank details.

```mermaid
graph TD
    Client[Flutter Client - Web/Mobile] -->|Auth & data| Supabase[Supabase Auth / PostgreSQL]
    Client -->|Authenticated request| Edge[Supabase Edge Functions]
    Edge -->|VTU requests| Bigisub[Bigisub API]
    FuturePay[Future payment webhook] -. not implemented .-> Supabase
    FutureNotify[Future WhatsApp / SMS] -. not implemented .-> Client
```

---

## 2. Paystack Live Setup (Dedicated NUBAN & Webhooks)

**Not live or implemented.** The repository does not currently create Paystack transactions or Dedicated Virtual Accounts, receive Paystack webhooks, or credit customer balances from verified payments. Do not display a made-up transfer account or accept a screenshot/manual transfer as proof of payment. The steps below are prerequisites for a future integration, not existing capabilities.

### 2.1 Obtain Live API Keys
1. Log into your [Paystack Dashboard](https://dashboard.paystack.com).
2. Complete your business compliance (Tier 2/Tier 3 CAC documentation).
3. Toggle from **Test Mode** to **Live Mode** in the top-left navigation.
4. Navigate to **Settings > API Keys & Webhooks**.
5. Copy your:
   - **Live Secret Key**: `sk_live_xxxxxxxxxxxxxxxxxxxxxxxx`
   - **Live Public Key**: `pk_live_xxxxxxxxxxxxxxxxxxxxxxxx`

### 2.2 Configure Webhooks
1. Do not enter a webhook URL until a production HTTPS webhook endpoint has been implemented and deployed.
2. Paystack signs webhooks using HMAC SHA512. A future implementation must verify `x-paystack-signature`, validate the event, and credit funds idempotently before treating any deposit as successful. No such handler is currently deployed by this repository.

### 2.3 Activating Dedicated NUBANs
1. Ensure your Paystack account has **Dedicated Virtual Accounts** enabled under **Preferences**.
2. A future server-side integration must create and persist a provider-assigned account only after Paystack confirms it. The current app does not request or issue dedicated virtual accounts.

---

## 3. Bigisub VTU Setup & Float Funding

The Flutter client calls the authenticated `bigisub` Supabase Edge Function. That server-side function proxies requests to `https://api.bigisub.ng`; the Bigisub token and transaction PIN must never be included in Flutter, browser storage, client settings, logs, or source control.

### 3.1 Configure Bigisub
1. Sign in to the Bigisub dashboard and verify the API token. **Rotate any token previously pasted into chat, committed, or displayed in the app settings before going live.**
2. Fund the Bigisub reseller/corporate float and confirm service access for airtime, data, cable, and electricity.
3. Deploy the `bigisub` Supabase Edge Function and set secrets without putting their values in application source:
   ```powershell
   supabase secrets set BIGISUB_API_TOKEN=<rotated-token> BIGISUB_TRANSACTION_PIN=<provider-transaction-pin>
   supabase functions deploy bigisub
   ```
4. Apply `avotek/supabase_schema.sql`; it adds authenticated RPCs that reserve a customer wallet debit before dispatch and refund a confirmed failure.
5. Exercise each service with a provider-approved low-value/test transaction, verify its Bigisub reference and final status, and confirm the wallet/ledger result before enabling customers.

The documented API overview identifies the API base URL, `Authorization: Token …` authentication, and services. Detailed endpoint schemas and webhook signing/retry rules were not available from the public page during implementation. The function uses the endpoint paths already present in the former Avotek Bigisub adapter; confirm those routes, request fields, provider status values, and result shapes with Bigisub before production use. Do not configure an unverified webhook endpoint: obtain Bigisub's signing and event contract, then implement signature verification and idempotent processing before accepting callbacks. Until then, reconcile pending purchases using provider status queries and manual/provider dashboard review.

---

## 4. WhatsApp Cloud API & Termii SMS Setup

### 4.1 Meta WhatsApp Cloud API Setup
WhatsApp delivery is **not integrated** in the current app. The account and templates below are prerequisites for a future server-side integration; do not promise receipts, warnings, or OTP delivery until the implementation has been deployed and tested.

1. Navigate to the [Meta for Developers Portal](https://developers.facebook.com).
2. Create a Business App and add the **WhatsApp** product.
3. Connect a clean phone number (not currently active on WhatsApp personal/business app).
4. Create a **System User** with Admin rights in Meta Business Manager and generate a **Permanent Access Token** with permissions:
   - `whatsapp_business_messaging`
   - `whatsapp_business_management`
5. Note your:
   - **Phone Number ID**
   - **WhatsApp Business Account (WABA) ID**
   - **Permanent Access Token**
6. Configure message templates in WhatsApp Manager (`welcome_user`, `transaction_receipt`, `wallet_funded`).

### 4.2 Termii SMS Integration
For users without active internet or WhatsApp:
1. Create an account at [Termii](https://termii.com).
2. Submit your **Sender ID** application (e.g., `AVOTEK`) with your CAC certificate for telecommunications approval.
3. Retrieve your **Termii API Key** from Settings.
4. Fund your Termii SMS wallet balance.
5. Implement and test server-side SMS routing before promising OTPs or transactional alerts; the current app has no Termii integration.

---

## 5. CAC Business Registration Operations

AVOTEK includes a comprehensive in-app **Corporate Affairs Commission (CAC)** service, allowing customers to apply for business registrations directly.

### 5.1 Registration Packages & Margins
| Package Type | Default System Price | Processing Timeline | Deliverables |
| :--- | :--- | :--- | :--- |
| **Business Name (Sole Proprietorship)** | ₦25,000 | 3 - 5 Business Days | CAC Certificate, Status Report |
| **Private Limited Company (LTD)** | ₦55,000 | 5 - 7 Business Days | CAC Certificate, Memorandum (MEMART), Status Report |
| **Incorporated Trustee (NGO / Church / Association)** | ₦120,000 | 14 - 21 Business Days | CAC Certificate, Constitution, Newspaper Publication Proof |

### 5.2 Admin Processing Workflow
1. This describes a future operational workflow; verify that the service, server-side validation, and escrow are implemented before accepting CAC orders.
2. If implemented and secured, the operations team would:
   - Logs into the **Super Admin Operations Suite**.
   - Inspects the application under the CAC Management queue.
   - Executes name reservation and filing on the official [CAC CRP Portal](https://pre.cac.gov.ng).
   - Updates status from `PENDING` -> `PROCESSING` -> `APPROVED`.
   - Uploads the signed PDF Certificate and Status Report.
3. WhatsApp notices are not currently implemented.

---

## 6. Dynamic Catalog & Pricing Margins

The admin pricing screens are not a production authorization boundary. Do not rely on client-side pricing or expose admin actions until access is enforced by authenticated server-side roles.

1. Only after server-side admin authorization has been implemented, access the **Pricing & Margins** tab.
2. Select category: `Data`, `Airtime`, `Electricity`, `Cable TV`, or `CAC`.
3. To adjust existing margin:
   - Click any catalog item to change cost price vs. selling price.
   - Toggle **Active / Inactive** to temporarily disable an upstream service under maintenance.
4. To add a brand-new service:
   - Tap **Add Catalog Item**.
   - Input Service ID (e.g., `CAC-EXP`, `STARLINK-SUB`), Service Name, Base Provider Cost (₦), AVOTEK Selling Price (₦), and Service Category.
   - Publish a catalog item only after its pricing and provider fulfillment are enforced server-side.

---

## 7. Super Admin Security & Gateway Access

The current admin gateway must not be treated as secure for production:

### 7.1 Security Guarantees
- **No Public Footprint**: External users, guests, and normal customers see zero administrative buttons, navigation items, or links in the UI.
- **Guarded Routes**: Attempting to navigate directly to `/admin` routes through `auth.isSuperAdmin` validation. Unauthorized access immediately redirects to `/admin-portal` requiring key authentication.
- **Session Locking**: Super Admin status can be manually locked at any time from the top bar, clearing privilege tokens from memory.

### 7.2 Production requirement
Never use a client-side shared passkey. Before exposing the admin suite, enforce authenticated server-side roles, remove any hard-coded passkeys, and independently review the authorization boundary. Once that work is deployed, verify access to:
   - Financial Overview & Wallet Floats
   - Dynamic Pricing & Margin Control
   - Transaction Audit Logs & Status Overrides
   - Live API Gateway Configurations (Paystack, VTpass, ClubKonnect, WhatsApp, Termii)
   - CAC Application Review & Approvals

---

## 8. Serverpod Backend & Docker Production Deployment

### 8.1 Environment Variables
Create `.env.production` in `avotek/avotek_server/config/`:
```env
# Database
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=avotek_prod
DATABASE_USER=avotek_admin
DATABASE_PASSWORD=YOUR_STRONG_POSTGRES_PASSWORD

# Redis Cache
REDIS_HOST=redis
REDIS_PORT=6379

# Paystack
PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxxxxxxxxxx
PAYSTACK_PUBLIC_KEY=pk_live_xxxxxxxxxxxxxxxxxxxxxxxx

# VTpass
VTPASS_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
VTPASS_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
VTPASS_PUBLIC_KEY=xxxxxxxxxxxxxxxxxxxxxxxx

# ClubKonnect
CLUBKONNECT_USER_ID=CK100xxxx
CLUBKONNECT_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx

# WhatsApp Cloud API
WHATSAPP_PHONE_NUMBER_ID=xxxxxxxxxxxxxxx
WHATSAPP_WABA_ID=xxxxxxxxxxxxxxx
WHATSAPP_ACCESS_TOKEN=EAAGxxxxxxxxxxxxxxxxxxxxxxxx

# Termii
TERMII_API_KEY=TLxxxxxxxxxxxxxxxxxxxxxxxx
TERMII_SENDER_ID=AVOTEK
```

### 8.2 Docker Compose Deployment
Run the backend with Docker Compose:
```bash
cd avotek/avotek_server
docker-compose -f docker-compose.production.yaml up -d --build
```

### 8.3 SSL/TLS Reverse Proxy (Caddy Example)
```caddy
avotek.yourdomain.com {
    reverse_proxy localhost:8080
}

webhook.yourdomain.com {
    reverse_proxy localhost:8082
}
```

---

## 9. Pre-Launch Verification Checklist

- [ ] **Paystack Webhook Tested**: Not implemented or tested.
- [ ] **Dedicated NUBAN Generation**: Created test customer DVA and verified auto-credit.
- [ ] **Bigisub Float Funded**: Fund the Bigisub reseller balance and verify it in the provider dashboard.
- [ ] **Airtime & SME Data Test**: Dispatched live ₦100 airtime and 500MB SME data test.
- [ ] **WhatsApp Notification**: Verified receipt delivery on real WhatsApp device.
- [ ] **Termii SMS Routing**: Verified 6-digit OTP delivery via registered sender ID.
- [ ] **CAC Order Flow**: Executed test CAC Business Name application and status update.
- [ ] **Admin Discrete Access**: Verified `/admin` is inaccessible to unauthenticated users.
- [ ] **Brand Fidelity**: Confirmed original AVOTEK logo renders cleanly on dark and light themes without AI alteration.

## 10. Supabase Authentication Setup

### Google sign-in
1. In Google Cloud Console, create an OAuth web client and add the Supabase Auth callback URL shown in **Supabase Dashboard > Authentication > Providers > Google** as an authorized redirect URI.
2. Enable Google in Supabase's Google provider settings and enter the client ID and client secret there. Keep the secret out of the Flutter app and repository.
3. Set the production website (for example, `https://your-domain.example`) as Supabase Auth **Site URL**. Add `https://your-domain.example/login-callback`, `https://your-domain.example/reset-password`, and required preview URLs to **Redirect URLs**. Do not leave Site URL set to `http://localhost:...`; auth links now request a callback based on the browser's current origin.
4. The mobile app registers the `io.supabase.avotek` URL scheme. Add the exact callbacks `io.supabase.avotek:///login-callback` and `io.supabase.avotek:///reset-password` to the Supabase redirect allow-list and test a Google sign-in on each target platform.

### Avotek ID, username, and phone sign-in
1. Apply `avotek/supabase_schema.sql` so profiles have unique `avo_id` and `username` values and new Supabase Auth users receive a profile row.
2. Deploy the identifier sign-in function from the `avotek` directory with `supabase functions deploy identifier-login`. The function uses Supabase's `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` server-side environment variables.
3. The function looks up identifiers with the service role but returns only an authenticated session after Supabase verifies the password. Never move the service-role key into the Flutter app.

### Password recovery
1. Add `https://<your-production-domain>/reset-password` to Supabase Auth **Redirect URLs** for web deployments.
2. For Android and iOS, allow `io.supabase.avotek:///reset-password` and confirm the installed build opens the reset route from an email.
3. Use Supabase's password-recovery email template and send a test email end-to-end before launch.

Email/password signup may require the user to confirm their email, depending on the Supabase Auth setting. The app intentionally does not create a signed-in local session until Supabase returns an authenticated session.

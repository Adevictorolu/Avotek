# AVOTEK Production Readiness & Gateway Configuration Guide

This comprehensive guide details the exact steps required to take the **AVOTEK VTU & Financial Services Platform** live, configure payment gateways and telco aggregators, fund working capital (float), manage CAC registration workflows, and secure the Super Admin portal.

---

## Table of Contents
1. [Overview & Architectural Topography](#1-overview--architectural-topography)
2. [Paystack Checkout & Webhooks](#2-paystack-checkout-and-webhook-setup)
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
- **VTU provider**: The upstream VTU provider is called through the authenticated `vtu-provider` Edge Function.

> **Live status:** Paystack checkout, server verification, signed webhook handling, and idempotent wallet-credit code are implemented, but an authenticated test payment has not been verified. Dedicated virtual accounts, WhatsApp messages, and Termii messages are not implemented. Do not advertise live payments until the checklist in [`AVOTEK_GO_LIVE_STATUS.md`](./AVOTEK_GO_LIVE_STATUS.md) is complete. The app does not fabricate bank details.

```mermaid
graph TD
    Client[Flutter Client - Web/Mobile] -->|Auth & data| Supabase[Supabase Auth / PostgreSQL]
    Client -->|Authenticated request| Edge[Supabase Edge Functions]
    Edge -->|VTU requests| Bigisub[Bigisub API]
    Client -->|Initialize / verify| PaystackFn[paystack-payments Edge Function]
    Paystack -->|Signed webhook| PaystackFn
    PaystackFn -->|Verify and credit once| Supabase
    FutureNotify[Future WhatsApp / SMS] -. not implemented .-> Client
```

---

## 2. Paystack Checkout and Webhook Setup

Paystack checkout initialization, server-side verification, and signed webhook
handling are implemented in the `paystack-payments` Supabase Edge Function.
The function credits a wallet only after an authenticated initialization
record, Paystack server-side verification, and exact reference, status,
currency, and amount checks. This integration is not certified ready for
customer transactions until the database migration and function are deployed,
Paystack secrets and URLs are configured, and the Test-mode checks in
[`AVOTEK_GO_LIVE_STATUS.md`](./AVOTEK_GO_LIVE_STATUS.md) pass. Dedicated Virtual
Accounts are not implemented. Do not accept screenshots or manual transfers as
proof of payment.

### Current Paystack transaction API flow

The server uses the official Paystack REST API over HTTPS:

1. `POST https://api.paystack.co/transaction/initialize` with the user's
   verified email, an integer amount in the currency subunit (NGN kobo, so
   naira multiplied by 100), `currency: "NGN"`, a server-generated unique
   reference, the callback URL, and wallet-funding metadata.
2. Return only the validated HTTPS `authorization_url` and reference to the
   signed-in Flutter client. The secret key remains in Supabase.
3. After checkout, verify with
   `GET https://api.paystack.co/transaction/verify/{reference}`. Do not treat
   the redirect, `trxref`, a client response, or a screenshot as payment
   confirmation.
4. For a valid `charge.success` webhook, check `x-paystack-signature` as
   HMAC-SHA512 of the exact raw request body using `PAYSTACK_SECRET_KEY`, then
   independently verify the transaction. Credit once through the locked
   `credit_paystack_wallet_funding` database function; duplicate webhook or
   verification calls must not credit twice.

The app currently accepts whole-naira amounts from ₦100 to ₦1,000,000. This is
Avotek's own limit; the amount sent to Paystack is in kobo. The current webhook
endpoint is
`https://gcixbqrridzgobkqnlfz.supabase.co/functions/v1/paystack-payments`.
`PAYSTACK_CALLBACK_URL` is the customer's return URL, not the webhook, and no
separate `PAYSTACK_WEBHOOK_SECRET` is used by this implementation. For browser
checkout, Avotek navigates the current tab to avoid popup blockers.

### 2.1 Configure Paystack keys safely
1. Log into your [Paystack Dashboard](https://dashboard.paystack.com).
2. Start in **Test Mode**. Add the Test Secret Key to Supabase Edge Function
   Secrets as `PAYSTACK_SECRET_KEY`. Never put it in Flutter, Git, logs, or
   chat. The app does not need the Paystack public key for server-created
   checkout sessions.
3. Configure `PAYSTACK_CALLBACK_URL` and deploy `paystack-payments` as
   documented in [`AVOTEK_GO_LIVE_STATUS.md`](./AVOTEK_GO_LIVE_STATUS.md).

### 2.2 Configure Webhooks
1. Set the Paystack Test Webhook URL to
   `https://gcixbqrridzgobkqnlfz.supabase.co/functions/v1/paystack-payments`
   after the function has been deployed.
2. Paystack signs webhooks using HMAC SHA512. The function checks
   `x-paystack-signature` and verifies a successful payment with Paystack
   before an idempotent database credit. A configured dashboard URL alone
   does not prove deployment or successful delivery.

### 2.3 Activating Dedicated NUBANs
Dedicated Virtual Account provisioning is not implemented. Do not show an
account number or invite bank transfers until a server-side provisioning and
verified deposit flow has been built and tested.

---

## 3. Bigisub VTU Setup & Float Funding

The Flutter client calls the authenticated `vtu-provider` Supabase Edge
Function. That server-side function proxies requests to
`https://api.bigisub.ng`; provider credentials must never be included in
Flutter, browser storage, client settings, logs, or source control.

### 3.1 Configure Bigisub
1. Sign in to the Bigisub dashboard and verify the API token. **Rotate any token previously pasted into chat, committed, or displayed in the app settings before going live.**
2. Fund the Bigisub reseller/corporate float and confirm service access for airtime, data, cable, and electricity.
3. Deploy the `vtu-provider` Supabase Edge Function and set secrets without putting their values in application source:
   ```powershell
   supabase secrets set BIGISUB_API_TOKEN=<rotated-token> BIGISUB_TRANSACTION_PIN=<provider-transaction-pin>
   supabase functions deploy vtu-provider
   ```
4. Apply `avotek/supabase_schema.sql`; it adds authenticated RPCs that reserve a customer wallet debit before dispatch and refund a confirmed failure.
5. Exercise each service with a provider-approved low-value/test transaction, verify its Bigisub reference and final status, and confirm the wallet/ledger result before enabling customers.

The supplied public API page confirms the API base URL, `Authorization: Token …` authentication, and the endpoint families for wallet balance, airtime, data, cable, electricity, recharge PINs, result checker, ISP, betting, SMS, and Marketing Hub. It documents standard service states as `successful`/`completed`, `processing`/`submitted`/`pending`/`in_progress`, and `failed`/`cancelled`/`refunded`/`partial`. The adapter recognizes these states and requery uses the documented GET route `/api/v2/anubis/transactions/{tranx_id}/requery/`.

For completed purchase responses, store `transaction_id`, `tran_id`, or `tranx_id` as the transaction identifier. Do not use `ref` or `api_id` for requery; the documentation identifies those as the upstream provider's own reference. A failed standard-service transaction is described as wallet-refunded by the provider. No authenticated provider transaction or settlement has yet been verified, so reconcile pending purchases through status queries and the provider dashboard.

Result-checker PIN and bulk SMS now have server-side proxy actions and wallet reservation. The PIN price is read from the provider's live price list before a debit is reserved. SMS cost is calculated from the documented per-page rate and message length; the returned cost must match before the debit is finalized. Pending SMS and other purchases can be rechecked from transaction history. These additions have not been tested against an authenticated Bigisub account. Keep them disabled in production until the provider float, account pricing and final status/refund behavior have been verified with approved test transactions.

ISP subscriptions, betting, recharge PINs, and Marketing Hub are not implemented in Avotek. The public page does not establish all account pricing and settlement details needed for safe wallet debits, so do not enable those products based on route names alone. The page also does not establish webhook signing/retry semantics; do not configure an unverified callback or treat an undocumented webhook as authoritative.

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

> **Legacy deployment notes:** This section describes an earlier Serverpod
> deployment and its `.env.production` variables. The current app uses
> Supabase Auth, PostgreSQL, and Edge Functions. Do not deploy this Serverpod
> configuration as a replacement for the Paystack/Supabase setup in section 2.

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

- [ ] **Paystack Webhook Tested**: Code is implemented; deploy and test signed delivery, verification, duplicate delivery, and idempotent credit in Test mode before Live.
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

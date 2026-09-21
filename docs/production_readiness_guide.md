# AVOTEK Production Readiness & Gateway Configuration Guide

This comprehensive guide details the exact steps required to take the **AVOTEK VTU & Financial Services Platform** live, configure payment gateways and telco aggregators, fund working capital (float), manage CAC registration workflows, and secure the Super Admin portal.

---

## Table of Contents
1. [Overview & Architectural Topography](#1-overview--architectural-topography)
2. [Paystack Live Setup (Dedicated NUBAN & Webhooks)](#2-paystack-live-setup-dedicated-nuban--webhooks)
3. [VTU Aggregator Setup & Float Funding (VTpass & ClubKonnect)](#3-vtu-aggregator-setup--float-funding-vtpass--clubkonnect)
4. [WhatsApp Cloud API & Termii SMS Setup](#4-whatsapp-cloud-api--termii-sms-setup)
5. [CAC Business Registration Operations](#5-cac-business-registration-operations)
6. [Dynamic Catalog & Pricing Margins](#6-dynamic-catalog--pricing-margins)
7. [Super Admin Security & Gateway Access](#7-super-admin-security--gateway-access)
8. [Serverpod Backend & Docker Production Deployment](#8-serverpod-backend--docker-production-deployment)
9. [Pre-Launch Verification Checklist](#9-pre-launch-verification-checklist)

---

## 1. Overview & Architectural Topography

AVOTEK runs on a high-throughput architecture consisting of:
- **Client Frontend**: Flutter cross-platform client (Web, Android, iOS) with Montserrat typography, light/dark themes, zero-distortion brand assets, and discreet admin routing.
- **Serverpod Backend**: Dart-native backend running on ports `8080` (API), `8081` (Insights), and `8082` (Webhooks).
- **Database & Cache**: PostgreSQL (with JSONB service catalogs) and Redis for rate-limiting and session management.
- **Upstream Aggregators**: Paystack (payments/virtual accounts), VTpass & ClubKonnect (data, airtime, cable, electricity), Meta WhatsApp Cloud API & Termii (notifications).

```mermaid
graph TD
    Client[Flutter Client - Web/Mobile] -->|REST / WebSockets| Serverpod[Serverpod API Port 8080]
    Paystack[Paystack Webhooks] -->|POST /webhook/paystack| WebhookServer[Webhook Port 8082]
    WebhookServer -->|Credit Wallet & Notify| DB[(PostgreSQL)]
    Serverpod -->|Airtime/Data Dispatch| VTpass[VTpass Live API]
    Serverpod -->|Failover / Reseller API| ClubKonnect[ClubKonnect Live API]
    Serverpod -->|Transaction Alerts| WhatsApp[WhatsApp Cloud API]
    Serverpod -->|OTP / SMS Alerts| Termii[Termii SMS Gateway]
```

---

## 2. Paystack Live Setup (Dedicated NUBAN & Webhooks)

AVOTEK provides automated wallet funding by assigning each registered customer a **Dedicated Virtual Account (DVA)** (Wema Bank, Titan Trust Bank, or Sterling Bank). Any bank transfer to this account instantly credits the customer's in-app wallet via webhook.

### 2.1 Obtain Live API Keys
1. Log into your [Paystack Dashboard](https://dashboard.paystack.com).
2. Complete your business compliance (Tier 2/Tier 3 CAC documentation).
3. Toggle from **Test Mode** to **Live Mode** in the top-left navigation.
4. Navigate to **Settings > API Keys & Webhooks**.
5. Copy your:
   - **Live Secret Key**: `sk_live_xxxxxxxxxxxxxxxxxxxxxxxx`
   - **Live Public Key**: `pk_live_xxxxxxxxxxxxxxxxxxxxxxxx`

### 2.2 Configure Webhooks
1. In **Settings > API Keys & Webhooks**, locate **Live Webhook URL**.
2. Enter your production endpoint:
   ```text
   https://api.yourdomain.com:8082/webhook/paystack
   ```
   *(or if running behind Nginx/Caddy proxy: `https://api.yourdomain.com/webhook/paystack` routed to port 8082)*
3. Paystack signs every webhook with your secret key via HMAC SHA512. AVOTEK's backend verifies the `x-paystack-signature` header before processing events like `charge.success` and `dedicated_account.assign.success`.

### 2.3 Activating Dedicated NUBANs
1. Ensure your Paystack account has **Dedicated Virtual Accounts** enabled under **Preferences**.
2. When a user completes KYC (BVN/NIN), AVOTEK issues an API request to `https://api.paystack.co/dedicated_account` to reserve an automated account number.

---

## 3. VTU Aggregator Setup & Float Funding (VTpass & ClubKonnect)

VTU operations require maintaining a funded pre-paid balance (**Float Balance**) with upstream aggregators. AVOTEK supports dual-redundancy with automatic failover between **VTpass** and **ClubKonnect**.

### 3.1 VTpass Integration & Funding
1. Register an enterprise partner account on [VTpass](https://www.vtpass.com).
2. Complete developer onboarding and obtain:
   - **API Key**
   - **Public Key**
   - **Secret Key**
3. Fund your VTpass Wallet:
   - Log in to the VTpass partner dashboard.
   - Click **Fund Wallet** and transfer funds to your assigned dedicated Wema/Providus account.
   - Recommended initial float: **₦100,000 – ₦500,000**.
4. Supported Services on VTpass:
   - Airtime: MTN, Airtel, Glo, 9mobile.
   - Data bundles: SME, Corporate Gifting, Direct CG.
   - Electricity: IKEDC, EKEDC, AEDC, IBEDC, PHED, etc.
   - Cable TV: DStv, GOtv, StarTimes.

### 3.2 ClubKonnect Integration & Funding
1. Register on [ClubKonnect](https://www.clubkonnect.com).
2. Retrieve your **UserID** and **API Key** from Developer Tools.
3. Fund your ClubKonnect Wallet via Monnify, bank transfer, or card.
4. ClubKonnect serves as the primary or failover provider for discounted MTN SME data and bulk airtime discounts.

### 3.3 Failover & Resilience Strategy
AVOTEK automatically executes the following logic during transactions:
1. Attempt primary provider (e.g., VTpass).
2. If the provider returns `503 Service Unavailable`, `Timeout`, or `Insufficient Balance`:
   - System logs the provider incident.
   - Instantly falls back to ClubKonnect without interrupting the user.
3. If both fail, transaction status is marked `FAILED` and user's wallet is immediately refunded.

---

## 4. WhatsApp Cloud API & Termii SMS Setup

### 4.1 Meta WhatsApp Cloud API Setup
AVOTEK sends real-time receipts, low-balance warnings, and OTPs directly to users' WhatsApp.

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
5. In AVOTEK, SMS routing is utilized for account verification OTPs and urgent transactional alerts.

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
1. When a user submits an application via `/services/cac`:
   - Application details (proposed business names, business object, proprietor/director KYC, address) are validated and saved.
   - Cost is debited from customer wallet and placed in escrow.
2. The AVOTEK Operations Team:
   - Logs into the **Super Admin Operations Suite**.
   - Inspects the application under the CAC Management queue.
   - Executes name reservation and filing on the official [CAC CRP Portal](https://pre.cac.gov.ng).
   - Updates status from `PENDING` -> `PROCESSING` -> `APPROVED`.
   - Uploads the signed PDF Certificate and Status Report.
3. The customer receives an automated WhatsApp and in-app notification to download their certificate.

---

## 6. Dynamic Catalog & Pricing Margins

The Super Admin can dynamically configure pricing without deploying code changes:

1. Access the **Super Admin Portal** -> **Pricing & Margins** tab.
2. Select category: `Data`, `Airtime`, `Electricity`, `Cable TV`, or `CAC`.
3. To adjust existing margin:
   - Click any catalog item to change cost price vs. selling price.
   - Toggle **Active / Inactive** to temporarily disable an upstream service under maintenance.
4. To add a brand-new service:
   - Tap **Add Catalog Item**.
   - Input Service ID (e.g., `CAC-EXP`, `STARLINK-SUB`), Service Name, Base Provider Cost (₦), AVOTEK Selling Price (₦), and Service Category.
   - Tap **Publish Service to Catalog**. Changes reflect instantly in client UI.

---

## 7. Super Admin Security & Gateway Access

AVOTEK utilizes a discrete, zero-exposure security architecture for the Admin portal:

### 7.1 Security Guarantees
- **No Public Footprint**: External users, guests, and normal customers see zero administrative buttons, navigation items, or links in the UI.
- **Guarded Routes**: Attempting to navigate directly to `/admin` routes through `auth.isSuperAdmin` validation. Unauthorized access immediately redirects to `/admin-portal` requiring key authentication.
- **Session Locking**: Super Admin status can be manually locked at any time from the top bar, clearing privilege tokens from memory.

### 7.2 Accessing the Super Admin Suite
1. Navigate directly to:
   ```text
   /admin-portal
   ```
2. Enter the Master Passkey:
   ```text
   avotek-admin-2026
   ```
   *(To change this passkey in production, update `lib/screens/admin/admin_gateway_screen.dart` and backend `config/passwords.yaml`)*
3. Upon entry, the full **AVOTEK Operations Suite** unlocks, granting access to:
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

- [ ] **Paystack Webhook Tested**: Successful ping test on port 8082 with live signature.
- [ ] **Dedicated NUBAN Generation**: Created test customer DVA and verified auto-credit.
- [ ] **Float Wallet Funded**: VTpass and ClubKonnect balance verified in Admin Overview.
- [ ] **Airtime & SME Data Test**: Dispatched live ₦100 airtime and 500MB SME data test.
- [ ] **WhatsApp Notification**: Verified receipt delivery on real WhatsApp device.
- [ ] **Termii SMS Routing**: Verified 6-digit OTP delivery via registered sender ID.
- [ ] **CAC Order Flow**: Executed test CAC Business Name application and status update.
- [ ] **Admin Discrete Access**: Verified `/admin` is inaccessible to unauthenticated users.
- [ ] **Brand Fidelity**: Confirmed original AVOTEK logo renders cleanly on dark and light themes without AI alteration.

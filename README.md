# AVOTEK — Leveraging Technology in Education
### Production-Grade Nigerian VTU & Academic Utilities Platform

AVOTEK (`A V O T E K`) is an end-to-end Virtual Top-Up (VTU) and academic utilities platform built specifically for the Nigerian educational and utilities ecosystem. Built with a custom PostgreSQL backend, full Serverpod RPC integration, and single-codebase Flutter deployment across Web, Android, and iOS.

---

## 🎨 Visual Identity & Brand System

Derived from the official AVOTEK visual identity:
- **Primary Color:** Electric Cyan (`#00A3FF`) & Deep Electric Blue (`#0084D6`)
- **Accent / Metallic Details:** Tech Slate (`#64748B`) & Circuit Silver (`#94A3B8`)
- **Dark Theme:** Deep Obsidian (`#0A0E17`), Midnight Card (`#111827`), Subtle Border (`#26334D`)
- **Light Theme:** Slate Pearl (`#F8FAFC`), Pure White (`#FFFFFF`), Border (`#E2E8F0`)
- **Design Language:** High contrast Material 3 flat surfaces, zero heavy drop shadows, generous whitespace, unified via a single `AppTheme` token system.

---

## 🏛️ System Architecture

```
                                    +-----------------------------------+
                                    |    Flutter App (Web + iOS + Android) |
                                    +-----------------+-----------------+
                                                      |
                                     Serverpod Typed RPC & WebSocket
                                                      |
                                                      v
                                    +-----------------------------------+
                                    |   AVOTEK Serverpod Backend (Dart) |
                                    +--------+------------------+-------+
                                             |                  |
           +---------------------------------+                  +--------------------------------+
           |                                                    |                                |
           v                                                    v                                v
+----------------------+                            +------------------------+        +---------------------+
| PostgreSQL 15 (DB)   |                            | Redis 7 (Distributed)  |        | HTTP Webhook Engine |
| - Users & KYC        |                            | - Idempotency Locks    |        | - Paystack NUBAN    |
| - Wallets & Ledger   |                            | - Rate Limiters        |        | - WhatsApp Cloud API|
| - Service Catalog    |                            +------------------------+        +---------------------+
| - Audit & Webhook Log|
+----------------------+
           |
           v
+-----------------------------------------------------------------------------------------------------------+
|                                    Aggregator Router (Unified Abstraction)                                |
+------------------------------------+-----------------------------------+----------------------------------+
                                     |                                   |
                                     v                                   v
                       +---------------------------+       +---------------------------+
                       |   VTpass (Primary)        |       | ClubKonnect (Fallback)    |
                       | - Airtime & Data          |       | - Auto-Failover           |
                       | - Electricity DISCOs      |       | - Secondary Verification  |
                       | - Cable TV & Exam PINs    |       +---------------------------+
                       +---------------------------+
```

---

## 📂 Repository Layout

```
├── avotek/
│   ├── avotek_flutter/      # Shared Flutter application (Web, Android, iOS)
│   │   ├── assets/          # Image assets, logo, favicon, and runtime config
│   │   │   └── images/      # High-resolution brand logo & platform graphics
│   │   ├── lib/
│   │   │   ├── core/theme/  # Unified Dark & Light AppTheme tokens (Montserrat typography)
│   │   │   ├── core/router/ # GoRouter with platform-aware web direct entry & /admin route
│   │   │   ├── providers/   # AuthProvider, WalletProvider, VtuProvider
│   │   │   ├── screens/     # Dashboard, Onboarding, Services, and Web Admin Operations Suite
│   │   │   └── widgets/     # BalanceCard, QuickServiceGrid, TransactionTile, AvotekLogo
│   │   └── test/            # Flutter widget & brand test suite (passing)
│   ├── avotek_server/       # Serverpod Dart backend
│   │   ├── lib/src/
│   │   │   ├── models/      # Serverpod SPI schema models (User, Wallet, Transaction, Order, etc.)
│   │   │   ├── endpoints/   # Auth, Wallet, Catalog, Order, Admin, Webhook endpoints
│   │   │   ├── engine/      # WalletEngine (atomic ledger) & OrderEngine (failover & auto-reverse)
│   │   │   ├── aggregators/ # Unified AggregatorRouter, VTpass, ClubKonnect, Mock adapters
│   │   │   ├── payments/    # Paystack dedicated NUBAN virtual account service
│   │   │   └── whatsapp/    # Meta WhatsApp Cloud API conversational state machine
│   │   └── test/unit/       # Full aggregator and router test suite (5/5 passing)
│   └── avotek_client/       # Auto-generated typed Dart RPC client consumed by Flutter
├── infra/
│   ├── init_schema.sql      # Production PostgreSQL 15 schema, indexes & seed catalogs
│   ├── docker-compose.yml   # PostgreSQL 15, Redis 7, Serverpod production container setup
│   └── .env.example         # Complete environment variable configuration template
└── docs/
    ├── database_guide.md    # Comprehensive guide for running SQL queries & inspecting users
    ├── api_reference.md     # Serverpod endpoint signatures and webhook protocols
    └── environment_variables.md # Variable breakdown, defaults, and production guidelines
```

---

## 🚀 Quick Start (Local Development)

### 1. Prerequisites
- **Flutter SDK** 3.24+ (or 3.47+)
- **Dart SDK** 3.5+
- **Docker & Docker Compose** (or local PostgreSQL 15 instance)
- **Serverpod CLI:** `dart pub global activate serverpod_cli`

### 2. Start PostgreSQL & Redis
```bash
cd infra
docker compose up -d postgres redis
```

### 3. Run Backend Migrations & Start Serverpod
```bash
cd avotek/avotek_server
serverpod create-migration # if schema changes made
dart bin/main.dart --apply-migrations
```
The Serverpod backend will bind to:
- **API / RPC:** `http://localhost:8080`
- **Insights Admin:** `http://localhost:8081`
- **Webhooks & Health:** `http://localhost:8082`

### 4. Run Flutter Application
```bash
cd avotek/avotek_flutter

# Web
flutter run -d chrome

# Mobile (Android / iOS)
flutter run
```

---

## ⚡ Live Operations Checklist

To transition from Mock development to live operations:
1. **VTpass Account:** Register at [vtpass.com](https://vtpass.com), fund your merchant balance, and add your `VTPASS_API_KEY`, `VTPASS_PUBLIC_KEY`, and `VTPASS_SECRET_KEY` to your environment.
2. **Paystack Dedicated Virtual Accounts:** Register at [paystack.com](https://paystack.com), complete business compliance, enable Dedicated NUBAN Accounts, and set your webhook callback to `https://your-domain.com:8082/webhook/paystack`.
3. **WhatsApp Business Cloud API:** Create a Meta Developer App, configure WhatsApp Cloud API, obtain a permanent System User Token, and register the webhook endpoint at `https://your-domain.com:8082/webhook/whatsapp`.
4. **Termii SMS:** Register at [termii.com](https://termii.com) for real-time OTP delivery to Nigerian phone numbers.

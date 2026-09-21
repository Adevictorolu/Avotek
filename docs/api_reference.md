# AVOTEK API Reference & Protocol Specification

AVOTEK leverages **Serverpod** as its backend architecture. Flutter clients connect directly to Serverpod via typed binary/JSON RPC protocols with zero REST boilerplate or manually serialized request models.

The generated typed client package `avotek_client` exposes endpoints grouped by business domain.

---

## 1. Authentication Endpoint (`client.auth`)

### `sendOtp(String phone)`
- **Description:** Sends a 6-digit one-time password to a Nigerian phone number via SMS (Termii integration) or simulates in development mode (`123456`).
- **Parameters:**
  - `phone` (`String`): Normalized Nigerian phone number (e.g. `08031234567`).
- **Returns:** `Future<bool>`

### `verifyOtp(String phone, String otp, {String? name})`
- **Description:** Verifies the user's OTP code. Creates a new user record and dedicated wallet if registering for the first time.
- **Parameters:**
  - `phone` (`String`): User's phone number.
  - `otp` (`String`): 6-digit OTP code.
  - `name` (`String?`, optional): Full name for initial registration.
- **Returns:** `Future<AuthResponse>`
  - `token` (`String`): JWT session authentication token.
  - `user` (`User`): Complete user profile object.

### `createPin(int userId, String pin)`
- **Description:** Sets a 4-digit transaction authorization PIN. Salted and hashed using BCrypt.
- **Returns:** `Future<bool>`

### `verifyPin(int userId, String pin)`
- **Description:** Validates a transaction PIN before executing wallet debits.
- **Returns:** `Future<bool>`

---

## 2. Wallet Endpoint (`client.wallet`)

### `getWallet(int userId)`
- **Description:** Retrieves real-time wallet balances, ledger snapshot, and assigned Paystack virtual bank account details.
- **Returns:** `Future<WalletSummary>`
  - `balance`: `double`
  - `currency`: `'NGN'`
  - `bankName`: Dedicated NUBAN bank name (e.g. `Wema Bank` / `Titan Bank`).
  - `accountNumber`: 10-digit dedicated virtual account number.
  - `accountName`: Assigned customer account name.

### `getTransactions(int userId, {int limit = 50, int offset = 0, String? filterType})`
- **Description:** Returns a paginated list of transactions (credits, debits, reversals, bonuses).
- **Parameters:**
  - `filterType` (`String?`, optional): `'credit'`, `'debit'`, `'reversal'`, `'bonus'`.
- **Returns:** `Future<List<Transaction>>`

### `simulateFunding(int userId, double amount)`
- **Description:** Sandbox/development utility to credit test funds directly to a user's wallet.
- **Returns:** `Future<bool>`

---

## 3. Catalog Endpoint (`client.catalog`)

### `getCatalog({String? serviceType, String? networkProvider})`
- **Description:** Fetches all active services and bundle variations dynamically. **No prices are hardcoded on the frontend.**
- **Parameters:**
  - `serviceType` (`String?`, optional): `'airtime'`, `'data'`, `'electricity'`, `'cable'`, `'exam_pin'`, `'betting'`.
  - `networkProvider` (`String?`, optional): `'MTN'`, `'AIRTEL'`, `'GLO'`, `'9MOBILE'`.
- **Returns:** `Future<List<ServiceCatalog>>`

### `getBeneficiaries(int userId, {String? serviceType})`
- **Description:** Retrieves saved recipients (phone numbers, meter numbers, smartcard numbers).
- **Returns:** `Future<List<Beneficiary>>`

### `saveBeneficiary(int userId, String serviceType, String networkProvider, String recipientIdentifier, String name)`
- **Description:** Saves or updates a quick-access beneficiary.
- **Returns:** `Future<Beneficiary>`

---

## 4. Order Endpoint (`client.order`)

All order operations enforce **ledger idempotency keys**, atomic balance checks, auto-failover aggregator routing, and automatic reversals on downstream failure.

### `buyAirtime(int userId, String network, String phone, double amount, String idempotencyKey, String channel)`
- **Returns:** `Future<OrderResult>`

### `buyData(int userId, String network, String phone, String variationCode, double amount, double sellPrice, String idempotencyKey, String channel)`
- **Returns:** `Future<OrderResult>`

### `verifyMeter(String disco, String meterNumber, String meterType)`
- **Description:** Pre-validates electricity meter number against the DISCO gateway.
- **Returns:** `Future<VerificationResponse>`
  - `isValid`: `bool`
  - `customerName`: `String?`
  - `details`: `String?` (e.g. customer address and tariff class).

### `payElectricity(int userId, String disco, String meterNumber, String meterType, double amount, String idempotencyKey, String channel)`
- **Description:** Dispatches utility token purchase.
- **Returns:** `Future<OrderResult>` (`token`: 20-digit prepaid token).

### `verifySmartcard(String provider, String smartcardNumber)`
- **Description:** Verifies DSTV, GOTV, or Startimes IUC number.
- **Returns:** `Future<VerificationResponse>`

### `payCableTV(int userId, String provider, String smartcardNumber, String variationCode, double amount, String idempotencyKey, String channel)`
- **Returns:** `Future<OrderResult>`

### `buyExamPin(int userId, String examType, int quantity, double amount, String idempotencyKey, String channel)`
- **Description:** Issues WAEC, NECO, or NABTEB registration scratch card PINs.
- **Returns:** `Future<OrderResult>` (`pinCode`: Generated exam PINs).

### `fundBetting(int userId, String provider, String customerId, double amount, String idempotencyKey, String channel)`
- **Returns:** `Future<OrderResult>`

---

## 5. Admin Endpoint (`client.admin`)

Requires elevated administrative privileges (`admin` or `superadmin` role).

### `getAllOrders({int limit = 100, int offset = 0, String? status})`
- **Returns:** `Future<List<Order>>`

### `getAllUsers({int limit = 100, int offset = 0})`
- **Returns:** `Future<List<User>>`

### `updateCatalogItem(int catalogId, double costPrice, double defaultMarkup, bool active)`
- **Description:** Dynamic margin and pricing control. Allows instant deactivation of services during aggregator maintenance.
- **Returns:** `Future<bool>`

### `manualRefundOrder(int orderId, int adminId, String reason)`
- **Description:** Triggers an atomic audit-logged refund from the admin console back to the customer's wallet.
- **Returns:** `Future<bool>`

---

## 6. HTTP Webhook Endpoints

Mounted via Serverpod Web Server on port `8082`:

### `POST /webhook/paystack`
- **Security:** Validates `X-Paystack-Signature` against HMAC-SHA512 of raw body with `PAYSTACK_WEBHOOK_SECRET`.
- **Event:** `charge.success`
- **Action:** Credits customer wallet instantly, updates transaction ledger, and records webhook audit entry.

### `GET /webhook/whatsapp`
- **Meta Verification:** Validates `hub.mode`, `hub.challenge`, and `hub.verify_token` against `WHATSAPP_VERIFY_TOKEN`.

### `POST /webhook/whatsapp`
- **Meta Inbound:** Processes incoming chat messages, runs the conversational state machine (`INIT` -> `MENU` -> `SERVICE` -> `PAY` -> `CONFIRM`), dispatches order, and replies via Meta Graph API.

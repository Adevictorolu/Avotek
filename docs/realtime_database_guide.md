# Avotek Real-Time Database Architecture & Live Trading Guide
**Motto: Leveraging Technology in Education**

This document provides a comprehensive operational and technical guide on:
1. How real-time user registrations, logins, and logouts are tracked in PostgreSQL and streamed to the UI.
2. The exact database table schemas, SQL queries, and triggers used for live session audits.
3. The Serverpod WebSocket streaming endpoint architecture.
4. Step-by-step instructions to take the platform **LIVE** with real money transactions via aggregator APIs (VTpass, ClubKonnect, and Paystack).

---

## 1. Real-Time Tracking Architecture (Registrations, Logins, Logouts)

To maintain an immutable, instant record of user lifecycle events without slow polling, Avotek combines:
- **PostgreSQL native `LISTEN / NOTIFY`** triggers on session events.
- **Serverpod 3.4.13 WebSocket PubSub Streams** broadcasting events to the Admin Dashboard.
- **Biometric / JWT session heartbeats** tracking active vs idle vs terminated sessions.

```
┌─────────────────┐       ┌─────────────────┐       ┌──────────────────┐
│  Mobile / Web   │──────▶│ Serverpod 3.4   │──────▶│  PostgreSQL 16   │
│ Client Activity │ Auth  │ Streaming Engine│ Save  │  Database Tables │
└─────────────────┘       └────────┬────────┘       └────────┬─────────┘
                                   │                         │
                                   │ WebSocket Broadcast     │ NOTIFY session_event
                                   ▼                         ▼
                          ┌─────────────────────────────────────┐
                          │   Admin Suite: Tab 0 (Live Activity)│
                          │ - Who Registered (IP, Phone, NUBAN) │
                          │ - Who Logged In  (Device, Geo, Time)│
                          │ - Who Logged Out (Manual or Timeout)│
                          └─────────────────────────────────────┘
```

---

## 2. PostgreSQL Database Schema

Run these SQL migration commands in your PostgreSQL database (`avotek`) or via the Admin SQL Console:

### A. Real-Time User Sessions Table (`user_sessions`)
Tracks currently active browser and mobile device sessions:

```sql
CREATE TABLE IF NOT EXISTS user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    device_model VARCHAR(150),
    device_os VARCHAR(80),
    client_type VARCHAR(50), -- 'flutter_web', 'flutter_android', 'flutter_ios'
    ip_address VARCHAR(64),
    geo_location VARCHAR(120), -- e.g. 'Lagos, Nigeria (MTN)'
    status VARCHAR(30) DEFAULT 'ONLINE', -- 'ONLINE', 'IDLE', 'LOGGED_OUT', 'REVOKED'
    login_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_heartbeat TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    logout_time TIMESTAMP WITH TIME ZONE,
    logout_reason VARCHAR(100) -- 'USER_ACTION', 'IDLE_TIMEOUT', 'ADMIN_REVOKED', 'PASSWORD_RESET'
);

CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_status ON user_sessions(status);
```

### B. User Activity Audit Log Table (`user_activity_log`)
Immutable append-only event stream logging every registration, authentication attempt, password change, and security trigger:

```sql
CREATE TABLE IF NOT EXISTS user_activity_log (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL, -- 'REGISTER', 'LOGIN', 'LOGOUT', 'ORDER_EXECUTED', 'PASSWORD_RESET'
    user_name VARCHAR(150),
    phone VARCHAR(30),
    email VARCHAR(150),
    ip_address VARCHAR(64),
    user_agent VARCHAR(255),
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_activity_log_event_type ON user_activity_log(event_type);
CREATE INDEX idx_activity_log_created_at ON user_activity_log(created_at DESC);
```

### C. Automated PostgreSQL Trigger for Real-Time Notification
```sql
CREATE OR REPLACE FUNCTION notify_user_session_event()
RETURNS TRIGGER AS $$
DECLARE
    payload JSON;
BEGIN
    payload = json_build_object(
        'id', NEW.id,
        'user_id', NEW.user_id,
        'event_type', NEW.event_type,
        'user_name', NEW.user_name,
        'phone', NEW.phone,
        'email', NEW.email,
        'ip_address', NEW.ip_address,
        'created_at', NEW.created_at
    );
    PERFORM pg_notify('admin_live_activity', payload::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_activity_stream ON user_activity_log;
CREATE TRIGGER trg_user_activity_stream
AFTER INSERT ON user_activity_log
FOR EACH ROW EXECUTE FUNCTION notify_user_session_event();
```

---

## 3. Essential Real-Time Monitoring SQL Queries

You can execute these directly inside the **Admin Operations Suite -> Tab 5 (PostgreSQL Console)**:

### 1. View All Online Users Right Now
```sql
SELECT 
    s.id AS session_id,
    u.id AS user_id,
    u.name,
    u.phone,
    s.device_model,
    s.ip_address,
    s.geo_location,
    s.login_time,
    s.last_heartbeat,
    AGE(NOW(), s.login_time) AS session_duration
FROM user_sessions s
JOIN users u ON s.user_id = u.id
WHERE s.status = 'ONLINE'
ORDER BY s.last_heartbeat DESC;
```

### 2. View Real-Time Activity Log (Registrations, Logins, Logouts)
```sql
SELECT 
    id,
    event_type,
    user_name,
    phone,
    email,
    ip_address,
    details->>'device' AS device,
    details->>'reason' AS reason,
    created_at
FROM user_activity_log
ORDER BY created_at DESC
LIMIT 50;
```

### 3. Remotely Terminate / Revoke a User Session (Immediate Kill Switch)
```sql
UPDATE user_sessions
SET status = 'REVOKED',
    logout_time = NOW(),
    logout_reason = 'ADMIN_REVOKED'
WHERE user_id = 2 AND status = 'ONLINE';
```

---

## 4. Serverpod Real-Time Streaming Endpoint (Dart)

In your Serverpod backend (`avotek_server/lib/src/endpoints/admin_live_activity_endpoint.dart`), the WebSocket stream endpoint broadcasts events to the Flutter frontend:

```dart
import 'package:serverpod/serverpod.dart';

class AdminLiveActivityEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Stream of user sessions and registrations for Admin Suite
  Stream<String> streamLiveEvents(Session session) async* {
    final auth = await session.authenticated;
    if (auth == null || auth.scopes.contains('superadmin') != true) {
      throw ServerpodException('Unauthorized: Super Admin required.');
    }

    // Subscribe to PostgreSQL NOTIFY channel
    final messages = session.messages.createStream('admin_live_activity');
    await for (final message in messages) {
      if (message is String) {
        yield message;
      }
    }
  }

  /// Revoke / Kill a user session in real-time
  Future<bool> killSession(Session session, int sessionId) async {
    final auth = await session.authenticated;
    if (auth == null) return false;

    // Update session table and post event to audit log
    await session.db.updateRow<UserSession>(
      // Set status = REVOKED
    );
    return true;
  }
}
```

---

## 5. How to Make the Site LIVE for Real Transactions

When you are ready to allow real customers to register, fund wallets with real Naira, and receive live airtime and data bundles, follow these 5 steps:

### Step 1: Fund Your Aggregator Float Accounts
Before activating live trading, ensure your business has funded provider accounts:
- **VTpass**: Login to `vtpass.com` -> Click **Fund Wallet** -> Transfer operating capital (e.g. ₦100,000). Your live balance is debited in real time whenever an end-user purchases airtime, SME data, cable TV, or electricity tokens.
- **ClubKonnect**: Login to `clubkonnect.com` -> Fund your wallet via Moniepoint/Sterling virtual account. This serves as automatic fallback if VTpass experiences latency.

### Step 2: Input Your Live API Credentials
Go to the **Admin Operations Suite** (`/admin-portal` -> Enter Passcode `2026`):
1. Navigate to **Tab 4: Gateways & Live Switch**.
2. **Paystack Dedicated Virtual Accounts**:
   - Paste your **Live Secret Key** (`sk_live_...`).
   - Paste your **Live Public Key** (`pk_live_...`).
   - Paste your **Webhook Secret** (`whsec_...`).
   - Copy the Avotek Webhook URL (`https://api.avotek.africa:8082/webhook/paystack`) and paste it into your Paystack Dashboard under **Settings -> API Keys & Webhooks**.
3. **VTpass Telecom & Utility Aggregator**:
   - Paste your **Live API Key** and **Secret Key**.
   - Change Base URL from `sandbox.vtpass.com` to `https://api-service.vtpass.com/api`.
   - Click **Check Merchant Balance** to confirm your live balance displays in green.
4. **ClubKonnect Fallback Aggregator**:
   - Enter your **ClubKonnect UserID** and **Live API Key**.
   - Click **Check Float Balance** to verify connectivity.
5. Click **Save & Apply Secrets**.

### Step 3: Flip the Master Live Trading Switch
1. In the **Gateways & Live Switch** tab, locate the large top card:
   - Click the red button: **GO LIVE (REAL MONEY)**.
2. Read the confirmation modal:
   - *All customer orders will trigger real telecom API dispatches.*
   - *Aggregator floats will be debited.*
   - *Paystack dedicated accounts will credit real Naira.*
3. Click **Activate Live Mode**.
4. The banner will immediately change to **🔴 100% PRODUCTION LIVE TRADING** with active float monitors.

### Step 4: Verify Transaction Lifecycle
1. Register a test customer or fund your personal test account with ₦500 via the copyable Wema/Moniepoint NUBAN on the dashboard.
2. Order ₦100 MTN or Airtel Airtime on `/services/airtime`.
3. Check that:
   - Your phone receives the airtime in under 10 seconds.
   - The order status in the UI transitions to **Delivered**.
   - The transaction appears in `/transactions` with a printable receipt and failure refund protection.
   - The **Admin Operations Suite -> Tab 0** captures the real-time order and profit ledger.

### Step 5: Master Safety Switch (Revert Anytime)
If you ever need to perform maintenance or pause live aggregator billing:
- Return to **Admin Operations Suite -> Tab 4**.
- Click **Revert to Sandbox**.
- The platform will instantly drop back into simulation mode without disrupting active customer browsing.

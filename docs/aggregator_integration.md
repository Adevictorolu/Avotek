# AVOTEK Aggregator Integration & Routing Architecture

The AVOTEK platform does not depend on any single third-party provider. All external telecom, DISCO, and cable networks are encapsulated behind an abstract provider layer with **automatic failover** and **idempotent retry capabilities**.

---

## 1. The Unified Interface (`VtuAggregatorInterface`)

All adapters implement `VtuAggregatorInterface`:

```dart
abstract class VtuAggregatorInterface {
  String get name;
  Future<AggregatorResult> purchaseAirtime(String network, String phone, double amount, String reference);
  Future<AggregatorResult> purchaseData(String network, String phone, String variationCode, double amount, String reference);
  Future<AggregatorResult> payElectricity(String disco, String meterNumber, String meterType, double amount, String reference);
  Future<ValidationResult> verifyMeter(String disco, String meterNumber, String meterType);
  Future<AggregatorResult> payCable(String provider, String smartcardNumber, String variationCode, double amount, String reference);
  Future<ValidationResult> verifySmartcard(String provider, String smartcardNumber);
  Future<AggregatorResult> buyExamPin(String examType, int quantity, double amount, String reference);
  Future<AggregatorResult> fundBetting(String provider, String customerId, double amount, String reference);
  Future<double> checkBalance();
}
```

---

## 2. Integrated Adapters

| Adapter | Role | Status | Description |
| :--- | :---: | :---: | :--- |
| **VTpassAdapter** | Primary | Live & Sandbox | Connects to VTpass REST API with Basic Auth & JSON payloads. Maps VTpass response codes (`000` = success). |
| **ClubKonnectAdapter** | Secondary / Fallback | Live | Connects to ClubKonnect HTTP query interface. Maps ClubKonnect status codes (`100` = success). |
| **MockAggregator** | Development / Test | Active | Generates high-fidelity simulated 20-digit electricity tokens, exam scratch PINs, and simulated receipts without consuming real money. |

---

## 3. The Failover Router (`AggregatorRouter`)

The `AggregatorRouter` is injected into `OrderEngine`. Its logic flow:

```mermaid
flowchart TD
    Order[Customer Order Initiated] --> Engine[OrderEngine Atomic Debit]
    Engine --> Router[AggregatorRouter]
    Router --> Primary{Call Primary: VTpass}
    Primary -->|Success (000)| Finish[Mark Order SUCCESS & Notify Customer]
    Primary -->|Timeout / 5xx / Maintenance| Fallback{Call Fallback: ClubKonnect}
    Fallback -->|Success| Finish
    Fallback -->|Failure / Exhausted| AutoReverse[Atomic Wallet Credit Reversal & Audit Log]
    AutoReverse --> Error[Notify Customer of Provider Downtime]
```

### Key Principles:
1. **Never Double-Debit:** The user's wallet is debited inside a transactional snapshot before calling external networks.
2. **Auto-Reversal on Failure:** If both primary and fallback aggregators fail or time out, `OrderEngine` immediately issues an atomic `reverseDebit` back to the customer's wallet and logs the root cause to `AuditLog`.
3. **Idempotency Safeguard:** Every order carries a unique `idempotencyKey`. Resubmitted requests with duplicate keys return the existing transaction record rather than executing a second purchase.

---

## 4. How to Add a New Aggregator (e.g. Baxi, SafeMart)

1. Create a new file in `avotek_server/lib/src/aggregators/baxi_aggregator.dart`.
2. Implement `VtuAggregatorInterface`.
3. Map external HTTP request and response structures into `AggregatorResult`.
4. Register the new provider in `AggregatorRouter` priority list:
   ```dart
   final router = AggregatorRouter(
     primary: VtpassAggregator(...),
     fallback: BaxiAggregator(...),
   );
   ```
5. Run unit tests in `avotek_server/test/unit/aggregator_test.dart` to verify compliance.

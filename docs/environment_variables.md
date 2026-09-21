# AVOTEK Environment Variables & Configuration Guide

All platform secrets and configuration values reside on the backend. No secret keys or aggregator API credentials ever touch the Flutter client.

---

## Variable Reference Table

| Variable | Required | Default / Example | Purpose |
| :--- | :---: | :--- | :--- |
| `SERVERPOD_RUNMODE` | Yes | `development` | Environment mode (`development`, `staging`, `production`). |
| `SERVERPOD_PORT` | No | `8080` | Primary RPC & WebSocket server port. |
| `SERVERPOD_WEB_PORT` | No | `8082` | HTTP Web server port for webhooks & healthchecks. |
| `SERVERPOD_INSIGHTS_PORT` | No | `8081` | Serverpod Insights administrative monitoring port. |
| `SERVERPOD_DATABASE_HOST` | Yes | `localhost` or `postgres` | Hostname of the PostgreSQL 15 database. |
| `SERVERPOD_DATABASE_PORT` | No | `5432` | Port of PostgreSQL. |
| `SERVERPOD_DATABASE_NAME` | Yes | `avotek` | Database name. |
| `SERVERPOD_DATABASE_USER` | Yes | `avotek_user` | Database user with migration & write permissions. |
| `SERVERPOD_DATABASE_PASSWORD`| Yes | `avotek_secret_password` | Database user password. |
| `REDIS_HOST` | No | `localhost` or `redis` | Redis server hostname for distributed locks. |
| `REDIS_PORT` | No | `6379` | Redis port. |
| `REDIS_PASSWORD` | No | `redis_secret_password` | Redis authentication password. |
| `VTPASS_API_KEY` | Prod | `your_api_key` | VTpass primary aggregator API key. |
| `VTPASS_PUBLIC_KEY` | Prod | `your_public_key` | VTpass public key. |
| `VTPASS_SECRET_KEY` | Prod | `your_secret_key` | VTpass secret key for signature calculation. |
| `VTPASS_BASE_URL` | No | `https://sandbox.vtpass.com/api` | VTpass gateway endpoint (`https://api-service.vtpass.com/api` in production). |
| `CK_USER_ID` | Prod | `your_userid` | ClubKonnect user ID for secondary fallback routing. |
| `CK_API_KEY` | Prod | `your_apikey` | ClubKonnect API secret key. |
| `CK_BASE_URL` | No | `https://www.clubkonnect.com/api` | ClubKonnect endpoint URL. |
| `PAYSTACK_SECRET_KEY` | Prod | `sk_test_...` / `sk_live_...` | Paystack secret key used for dedicated virtual accounts & verification. |
| `PAYSTACK_PUBLIC_KEY` | No | `pk_test_...` / `pk_live_...` | Paystack public key. |
| `PAYSTACK_WEBHOOK_SECRET` | Prod | `whsec_...` | Secret token to verify `X-Paystack-Signature` HMAC. |
| `WHATSAPP_TOKEN` | Prod | `EAAG...` | Meta Graph API permanent System User Access Token. |
| `WHATSAPP_PHONE_NUMBER_ID` | Prod | `102938475610293` | Meta WhatsApp Cloud API Phone Number ID. |
| `WHATSAPP_VERIFY_TOKEN` | Prod | `avotek_whatsapp_secure_2026` | Custom challenge token for Meta webhook subscription verification. |
| `TERMII_API_KEY` | Prod | `your_termii_key` | Nigerian SMS gateway key for phone OTP verification. |
| `TERMII_SENDER_ID` | No | `AVOTEK` | Registered alphanumeric sender ID on Termii. |

---

## Production Recommendations

1. **Database Secrets:**
   - Store all passwords in Docker secrets, AWS Secrets Manager, or Google Secret Manager.
   - Restrict PostgreSQL port 5432 to internal Docker networks or VPC security groups only.

2. **Serverpod Server Modes:**
   - In `production`, Serverpod enforces SSL certificates, strict CORS origins, and requires a valid password salt in `config/production.yaml`.

3. **Fallback Simulation:**
   - When running in `development` mode without third-party credentials, the `MockAggregator` automatically intercepts calls, returning successful test tokens and simulated utility receipts.

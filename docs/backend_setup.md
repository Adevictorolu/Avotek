# Avotek backend setup

## What is in this repository

There is no `avotek_server` Serverpod project here. The deployable backend
starting point is a Supabase Edge Function at
`avotek/supabase/functions/bigisub-proxy/index.ts`.

This function:

- verifies each caller's Supabase access token against Supabase Auth;
- accepts only listed Bigisub catalog and account-verification endpoints;
- stores and sends the Bigisub token only on the server;
- applies CORS origin and input allowlists; and
- returns `503` for every purchase endpoint.

The purchase block is intentional. Atomic wallet debits/refunds, idempotent
orders, backend transaction-PIN verification, reconciliation, Paystack wallet
funding, and a signed webhook processor are not implemented. Until they are,
the app must not submit a real purchase or display a manual transfer account.

## Deploy the proxy

Prerequisites: a Supabase project, Node.js/npm, and the Supabase CLI (the
`npx supabase` form below can invoke the CLI).

1. Rotate the Bigisub API token previously shared in chat or ever embedded in
   source/builds. Use only the rotated token. Never commit it or paste it into
   Flutter settings.
2. From the repository root, enter the Supabase project directory and link it
   to the right Supabase project:

   ```powershell
   Set-Location avotek
   npx supabase login
   npx supabase link --project-ref YOUR_PROJECT_REF
   ```

   Find `YOUR_PROJECT_REF` in Supabase **Project Settings → API**.
3. Create `supabase/.env` locally (it is git-ignored) with the real values:

   ```dotenv
   BIGISUB_API_TOKEN=put-your-rotated-token-here
   ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,https://your-app-domain.example
   ```

   Replace the examples with your own values. Do not upload this file or share
   its contents. For development, remove the production origin; for production,
   remove localhost origins.
4. Upload the values as Supabase Function secrets and deploy:

   ```powershell
   npx supabase secrets set --env-file supabase/.env
   npx supabase functions deploy bigisub-proxy
   ```

   Supabase validates JWTs at the gateway and the handler also validates the
   signed-in user with Supabase Auth. Do not add or expose
   `SUPABASE_SERVICE_ROLE_KEY`.
5. Start the Flutter app with the proxy URL:

   ```powershell
   Set-Location ..\avotek_flutter
   flutter run -d chrome --dart-define=VTU_BACKEND_URL=https://YOUR_PROJECT_REF.supabase.co/functions/v1/bigisub-proxy
   ```

   For release builds, use the same define with `flutter build web`. Set the
   exact web origin (scheme, host, and port) in `ALLOWED_ORIGINS` before
   deploying the function. A CORS error means the current browser origin is not
   on that list. Do not point a phone at `localhost`; use a deployed HTTPS site
   or a protected development tunnel.
6. Apply and review `avotek/supabase_schema.sql` in the Supabase SQL Editor.
   The migration removes the made-up virtual bank-account values and revokes
   direct client writes to wallets, transactions, and VTU orders. It does not
   create real virtual accounts or payment processing.
7. Confirm a signed-in user's catalog/verification calls reach the function.
   Purchase endpoints should still respond `503`; that is expected until the
   financial backend is complete.

## Choosing a deposit/payment provider

Paystack is the first candidate described in this repository's payment setup
notes. Before selecting it, confirm in your own Paystack dashboard that your
business is eligible for the required transfer/virtual-account product and
review current fees, settlement timing, and webhook requirements. Alternatives
may be evaluated against those requirements; no alternative is integrated in
this code today.

Do not credit a wallet from a client button, screenshot, or unverified webhook.
The production payment flow needs provider-side event signature validation,
duplicate-event protection, server-verified transaction status and amount,
and one database transaction that records the unique payment reference and
credits the user's balance exactly once.

## What is still required for live purchases

Before enabling a purchase route, implement and test a trusted database/backend
operation that validates the signed-in user and PIN server-side, confirms the
catalog price on the backend, reserves/debits wallet funds atomically with a
unique idempotency key, submits the provider purchase, persists its provider
reference/status, and reconciles pending/failure/refund outcomes without
double-charging or false success. Configure monitoring and provider float, then
perform small provider-approved sandbox tests before live mode. The Bigisub
proxy currently does not do these financial steps and will intentionally reject
all purchases.

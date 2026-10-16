# Avotek: what remains before going live

This is the deployment checklist for the current code. A GitHub push does not
deploy Supabase functions, configure Auth redirects, or activate payment
providers. No real wallet top-up or provider purchase should be enabled until
the relevant server configuration and provider tests below pass.

## Current linked-project status

The latest check of the linked Supabase project found:

- Migrations `20261010120000`, `20261012140000`, and `20261014180000` are
  applied, and the core profile, wallet, transaction, and VTU tables/RPCs exist.
- `identifier-login`, `vtu-provider`, and `paystack-payments` are active.
  `paystack-payments` was deployed, but a request returns HTTP 503 because its
  required payment secrets are not configured. This is fail-closed behavior.
- The app calls the `vtu-provider` Edge Function by its deployed name. Its
  endpoint responds to CORS preflight and rejects unauthenticated requests;
  the Bigisub secret names are configured, but credentials and provider
  operations have not been validated with an authenticated account.
- Paystack callback `PAYSTACK_CALLBACK_URL` is configured. The required
  `PAYSTACK_SECRET_KEY` name is absent; a legacy-labelled `Live secret key`
  does not configure this function.
- No authenticated provider purchase or Paystack Test-mode transaction has
  been run. The provider endpoints and credentials still need verification
  before customer transactions are enabled.

Credentials previously shared in chat, and any credential material returned
by CLI secret-list output, should be treated as exposed and rotated before use.
Add replacement values directly in Supabase Dashboard → Edge Functions →
Secrets; do not send them in chat, source control, or logs.

## 1. Fix the localhost authentication callback

The attached `ERR_CONNECTION_REFUSED` page means the browser was sent to a
`localhost` address where no web server is listening. This commonly happens
when Supabase Auth still has a local development URL as its Site URL or when a
confirmation link was generated with a localhost redirect.

1. The GitHub Pages deployment for this repository is hosted at
   `https://adevictorolu.github.io/Avotek/`. Use that project URL, not the
   account root `https://adevictorolu.github.io/`, which has no Pages site.
   A `localhost` URL only works while the local web server is running.
2. In Supabase Dashboard, open **Authentication → URL Configuration**:
   - Set **Site URL** to `https://adevictorolu.github.io/Avotek/`.
   - Add these exact hash-route URLs to **Redirect URLs**:
     `https://adevictorolu.github.io/Avotek/#/login-callback` and
     `https://adevictorolu.github.io/Avotek/#/reset-password`.
   - Add the exact local development origin only if local testing is needed.
3. In **Authentication → Providers → Google**, enable Google and set its
   provider credentials. In Google Cloud, allow the Supabase callback URL
   displayed by Supabase; this is different from the app's `login-callback`.
4. The app keeps the GitHub Pages project path when it generates email signup,
   Google OAuth, and password-reset redirects. The OAuth callback waits for
   Supabase to establish a session before navigating to the protected dashboard.
   After deploying this change, test a new signup, confirmation email, Google
   sign-in, password reset, and email/password sign-in on the production URL.
   Authenticated visits to the site root go to the dashboard; signing out goes
   to the sign-in screen. On mobile, allow the exact callback URLs
   `io.supabase.avotek:///login-callback` and
   `io.supabase.avotek:///reset-password`.
5. If the browser still opens localhost, inspect the email's actual link and
   Supabase **Site URL / Redirect URLs**. Do not work around it by turning off
   authentication or accepting an unverified signup.

## 2. Apply the Supabase database changes

The database migration adds durable Avotek IDs/usernames to new profiles,
clears wallet account numbers generated locally by older app versions, and
blocks authenticated clients from writing wallet balances or ledger rows
directly. Those old numbers were not assigned by a bank and must not be used
for transfers.

From the `avotek` directory, after installing and authenticating the Supabase
CLI for the correct project:

```powershell
supabase link --project-ref <your-project-ref>
supabase db push
```

Alternatively, review and run
[`avotek/supabase/migrations/20261012140000_fix_auth_profiles_and_unverified_wallets.sql`](../avotek/supabase/migrations/20261012140000_fix_auth_profiles_and_unverified_wallets.sql)
in the intended project's SQL editor. Back up production data first and verify
the rows affected by the wallet cleanup before applying it. Do not grant
clients permission to update wallet balances directly.

## 3. Configure Auth and VTU functions securely

1. Confirm the Supabase Auth redirect allow-list from step 1.
2. Set `BIGISUB_API_TOKEN` and `BIGISUB_TRANSACTION_PIN` as Supabase Edge
   Function secrets for the upstream provider adapter. Rotate any token
   previously pasted into chat or source control; do not paste secrets into
   GitHub, this document, or Flutter.
3. Set the service-role key only as a Supabase-managed function secret when
   needed by trusted server code; never embed it in the app.
4. Deploy the functions:

   ```powershell
   supabase functions deploy identifier-login
   supabase functions deploy vtu-provider
   supabase functions deploy paystack-payments
   ```

### Function names currently used by the app

| Supabase function | Purpose |
| --- | --- |
| `identifier-login` | Resolves the app's identifier-based sign-in flow. |
| `vtu-provider` | Authenticated server adapter for wallet balance, airtime, data plans and purchase, cable plans/verification/purchase, electricity provider lookup/verification/payment, and transaction requery. |
| `paystack-payments` | Authenticated checkout initialization and verification, plus Paystack signature-verified webhook delivery for wallet funding. |

The adapter currently accepts these action names: `wallet.balance`,
`airtime.purchase`, `data.plans`, `data.purchase`, `cable.plans`,
`cable.verify`, `cable.purchase`, `electricity.providers`,
`electricity.verify`, `electricity.purchase`, and `transaction.requery`.
Keep provider credentials and service-role credentials in Supabase secrets;
never put them in Flutter or the repository.

5. Confirm the adapter paths, payload fields, plan-price fields, transaction
   status meanings, and live behavior with the upstream provider. The public
   documentation URL provided in chat did not expose enough endpoint detail
   to verify those contracts. Although `vtu-provider` is now active in the
   linked project, no authenticated end-to-end purchase test has been run.
   Do not claim purchase flows are live until the contracts are confirmed and
   controlled tests succeed.

6. Education PINs, ISP, bulk SMS, and airtime PIN generation do not have
   verified contracts implemented in the VTU adapter. Obtain endpoint paths,
   required fields, response examples, error/status meanings, and test
   credentials from the provider before adding those services. Do not infer
   the contracts from the category list.
7. With a funded provider float, test one low-value transaction for each
   available service. Check provider references/status, customer wallet,
   ledger, confirmed-failure refunds, and duplicate/retry behavior. Do not
   release a transaction whose status is ambiguous; reconcile it with Bigisub.

## 4. Paystack wallet funding setup

The repository now contains a Paystack checkout flow, authenticated server
verification, signed webhook handling, and an atomic/idempotent wallet credit
RPC. This code is **not live until the migration, function deployment, and
Paystack dashboard setup below are complete and tested**.

1. Apply migrations to the linked Supabase project:

   ```powershell
   supabase db push
   ```

   This includes
   `avotek/supabase/migrations/20261014180000_add_paystack_wallet_funding.sql`.
   Verify the migration succeeded before deploying the function.
2. In Supabase **Edge Functions → Secrets**, configure:
   - `PAYSTACK_SECRET_KEY`: use the Paystack **Test Secret Key** while testing.
   - `PAYSTACK_CALLBACK_URL`: `https://adevictorolu.github.io/Avotek/#/wallet/fund`
   - The existing Supabase environment variables `SUPABASE_URL`,
     `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` must be available to
     the function runtime. Never put service-role or Paystack secret keys in
     Flutter or Git. Supabase intentionally hides saved secret values; a secrets
     listing can confirm names exist, not reveal their contents. To replace a
     value, set it again in the dashboard.
3. Deploy the function:

   ```powershell
   supabase functions deploy paystack-payments
   ```

4. In Paystack **Test** settings, set the callback URL to the same Avotek
   wallet URL. Set the **Webhook URL** to:

   `https://gcixbqrridzgobkqnlfz.supabase.co/functions/v1/paystack-payments`

   The webhook URL is an HTTPS endpoint, not a short code. Paystack signs
   webhook requests in `x-paystack-signature` using the Paystack secret key;
   this function verifies that signature and then independently verifies
   successful transactions with Paystack. Do not treat a `WHK_...` value as
   the webhook URL or put it in app code. If that value is a credential rather
   than a dashboard identifier, rotate it in Paystack.
   Leave Paystack IP whitelisting disabled unless you have confirmed a stable
   outbound IP for the Supabase function runtime; the customer's IP is not the
   server IP used for Paystack API requests.
5. Test in Test mode using Paystack's test payment details. Confirm the
   checkout returns to the app, the server verifies the reference and exact
   amount/currency, the wallet and ledger update once, and duplicate webhooks
   do not add another credit. Also test failed, abandoned, delayed, and
   signature-invalid callbacks. A return to the app alone never credits funds.
6. For Live mode, use a separate production Supabase project where possible.
   Set its `PAYSTACK_SECRET_KEY` to the Live Secret Key in Supabase Secrets,
   apply the reviewed migration, deploy `paystack-payments`, and point the Live
   Paystack webhook/callback settings at the production function and app URLs.
   Verify with a controlled low-value real payment before enabling public
   wallet funding. Never paste either secret key into chat or commit it.

Wallet funding in the app redirects to Paystack checkout. The app no longer
displays or relies on unverified virtual bank account details. Paystack wallet
funding does not itself deploy or validate the separate VTU provider function.

## 5. WhatsApp notifications are not live

WhatsApp Cloud API sending and webhook verification are also not implemented.
Create/configure the Meta business app, approved sender, templates, and
server-side secrets, then implement and test delivery/failure handling before
claiming that receipts or alerts are sent. Keep access tokens on the server.

## 6. Final verification and web deployment

1. Run `flutter analyze`, `flutter test`, and `flutter build web --release` in
   `avotek/avotek_flutter`.
2. Test production signup, confirmation, sign-in, Google OAuth, password
   recovery, Avotek ID display, and theme switching on phone and desktop.
3. Confirm production database RLS, Edge Function secrets, and function logs.
   Never use a client-side admin passkey or a manually entered wallet credit
   as proof that a payment integration works.
4. Verify the deployed GitHub Pages build opens at
   `https://adevictorolu.github.io/Avotek/` and does not redirect to localhost.
   A successful GitHub push is not proof that Supabase configuration or secrets
   have been applied.

## 7. Current service coverage and remaining launch work

The public Bigisub documentation page describes the available product
categories, but the supplied Bigisub dashboard settings URL redirects to its
login page. The public page does not provide the exact request fields and
response semantics for every product. Do not guess an endpoint or mark a
service live based on the category list alone.

The app has Edge Function adapters for Paystack wallet funding (checkout,
server verification and signed webhook) and for airtime, data plans and
purchases, cable plans/verification/purchases, electricity providers,
verification/purchases, and transaction requery. The core database migrations
are applied; `vtu-provider` and `paystack-payments` are deployed. The VTU
endpoint responds to CORS preflight and rejects unauthenticated requests, but
no authenticated provider operation has been run. Paystack has not been
configured with `PAYSTACK_SECRET_KEY`, so its endpoint fails closed. Neither
integration has passed authenticated end-to-end transaction testing. The VTU
adapter does not provide airtime PIN generation, result-checker PINs, bulk SMS,
ISP subscriptions, betting, transactional email, or gift voucher
issuance/redemption. Betting has been removed from the service menu;
unintegrated services are shown as coming soon instead of reporting fake
success.

**Latest linked-project check:** the migrations are applied and
`identifier-login`, `vtu-provider`, and `paystack-payments` are active. The
`vtu-provider` endpoint returned HTTP 200 for its CORS preflight and HTTP 401
for an unauthenticated read request, confirming endpoint routing and the
authentication boundary without performing a purchase. `BIGISUB_API_TOKEN`
and `BIGISUB_TRANSACTION_PIN` secret names exist, but their values and upstream
operations have not been authenticated or validated. A direct request to
`paystack-payments` returned HTTP 503, “Payment service is not configured,”
because `PAYSTACK_SECRET_KEY` is absent. `PAYSTACK_CALLBACK_URL` is configured.
These checks confirm deployment/routing and fail-closed behavior only; they do
not confirm successful transactions. No low-value provider or Paystack Test
transaction has been run.

Before enabling customers to transact:

1. **Rotate the Bigisub token and transaction PIN previously shared in chat
   or returned in CLI output.** Store the rotated token and provider transaction
   PIN only as Supabase Edge Function secrets. Never put either value in
   Flutter, Git, logs, or support messages. Confirm the provider PIN is the
   upstream API transaction PIN, not a customer's Avotek purchase PIN.
2. Verify the migrations and active functions in Supabase. `vtu-provider` has
   been deployed with the current adapter; after rotating provider credentials,
   redeploy it and perform authenticated non-purchase checks. Set the rotated
   Paystack key under `PAYSTACK_SECRET_KEY` and redeploy `paystack-payments`.
   Confirm functions authorize signed-in users where required.
3. Confirm Bigisub's exact endpoint, field names, price rules, PIN-generation
   quantity contract, and status/refund meanings from the authenticated
   provider documentation. The customer phone number must not be sent for
   airtime PIN generation unless Bigisub's contract requires it.
4. Test provider balance, each supported service, pending/requery behavior,
   wallet reservation and refund idempotency, and reconciliation using a
   funded test account. Keep ambiguous results pending; do not retry them as a
   new purchase.
5. Complete the Paystack Test-mode scenarios in section 4 before entering Live
   credentials or accepting customer wallet funding.
6. Select and configure a transactional email provider plus server-side
   purchase events before enabling email receipts. The current Email/Push
   preference switches are intentionally disabled because no delivery backend
   is configured. SMS transaction notifications have been removed.
7. Implement and test server-backed gifts, coupon redemption, referral
   commissions/AVO Token rewards, account KYC, and push notifications before
   presenting them as completed features. The short Avotek ID format also
   needs a collision-safe database migration and identifier-login update;
   existing IDs must not be changed by a client-only formatter.
8. Provide and verify the official support WhatsApp number before enabling a
   WhatsApp link. The current help panel can answer basic FAQs and launch an
   email to support; it does not claim to be an AI agent.
9. Use the GitHub Pages URL for referral registration links until a custom
   `avotek.com` domain is owned, configured, and deployed. The Bigisub
   dashboard URL cannot be inspected without a provider login.
10. Review the in-app Terms of Service and Privacy Policy drafts with the
   correct legal business identity, governing jurisdiction, privacy contact,
   data retention, and provider list before publication.

# Avotek: deployment and go-live status

This status document records what is implemented and what still blocks live
transactions. A successful deployment or an unauthenticated HTTP response does
not prove that a provider credential is valid or that a real transaction works.

## Completed and verified

- The Flutter application is published through GitHub Pages, with maintained
  CI and deployment workflows. The duplicate broken Dart workflow was removed.
- The three core database migrations are applied to the linked Supabase project.
- `identifier-login`, `vtu-provider`, and `paystack-payments` are deployed.
- The VTU function answers CORS preflight and rejects unauthenticated requests.
  The Paystack function also rejects unauthenticated initialization requests.
  These checks verify routing and authentication boundaries only.
- The app has server-side adapters for airtime, data, cable, electricity,
  transaction requery, and Paystack checkout/webhook handling.
- Unsupported provider products are not advertised as working: result-checker
  PINs, bulk SMS, and airtime PIN generation remain disabled until their exact
  provider API contracts are available and implemented.

## Not yet verified or implemented

- No authenticated Bigisub service operation or Paystack Test/Live payment has
  been completed. The current deployment is **not certified ready for live
  transactions**.
- The public Bigisub documentation does not expose the request/response
  contracts needed to implement result-checker PINs, bulk SMS, or airtime PIN
  generation. No endpoint or purchase payload has been guessed.
- The Avotek admin page links to provider/project consoles; it is not yet a
  server-authorized console for global activity, user creation/deletion, or
  service-price changes. Do not expose those operations using the client-side
  admin email check alone.
- The transaction history has individual receipt details and downloadable
  text receipts/CSV statements, but automatic email delivery is not configured.
- Account notification choices for email, push, and WhatsApp are saved in the
  signed-in user's Supabase Auth metadata. They are preferences only; they do
  not send messages until transactional email, push, and WhatsApp Business API
  delivery providers are separately configured and server-side event dispatch
  is implemented. The Settings page links to the supplied WhatsApp support
  contact for user-initiated support chats.
- Following the Settings and receipt updates, targeted Flutter analysis passed,
  all 21 Flutter tests passed, and `flutter build web --release --no-pub`
  completed successfully on 2026-10-19. The Cable TV and Electricity screens
  were restyled and targeted Dart analysis plus all 21 Flutter tests passed.
  This verifies the local build, not a deployment or an end-to-end transaction.
- Provider credentials and Paystack keys have not been validated by completing
  an authenticated test transaction.

## Current linked-project status

The latest check of the linked Supabase project found:

- Migrations `20261010120000`, `20261012140000`, and `20261014180000` are
  applied, and the core profile, wallet, transaction, and VTU tables/RPCs exist.
- `identifier-login`, `vtu-provider`, and `paystack-payments` are active.
  A valid unauthenticated initialization request to `paystack-payments` reaches
  the authentication check (HTTP 401), indicating its required server
  configuration names are present. This does not validate the Paystack key or
  prove a transaction can complete.
- The app calls the `vtu-provider` Edge Function by its deployed name. Its
  endpoint responds to CORS preflight and rejects unauthenticated requests;
  the Bigisub secret names are configured, but credentials and provider
  operations have not been validated with an authenticated account.
- Paystack callback `PAYSTACK_CALLBACK_URL` is configured. An unauthenticated
  initialization request now reaches the authentication check, showing the
  function has the required server configuration names. This does not verify
  that the Paystack key is valid, which account mode it belongs to, or that a
  payment can complete.
- No authenticated provider purchase or Paystack Test-mode transaction has
  been run. The provider endpoints and credentials still need verification
  before customer transactions are enabled.
- On 2026-10-19, the supplied Paystack Test secret was accepted by Paystack's
  read-only balance API check, saved as the Supabase `PAYSTACK_SECRET_KEY`, and
  `paystack-payments` was redeployed (version 9). An unauthenticated
  initialization request still returns HTTP 401, as required. These checks
  verify Test-key authentication, secret wiring, deployment, and fail-closed
  access only; they do not prove an authenticated checkout or wallet credit.
  The public key was not added because this server-created hosted-checkout
  integration does not use it.

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

6. The service page lists Result Checker PINs, Bulk SMS, and Airtime PIN
   Generation as disabled until their provider contracts are verified. These
   actions are not implemented in the VTU adapter. Obtain endpoint paths,
   required fields, response examples, price rules, quantity limits,
   error/status meanings, and provider-approved test credentials from the
   authenticated provider documentation before adding them. Do not infer
   contracts from the category list.
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
   supabase db push --project-ref gcixbqrridzgobkqnlfz
   ```

   This includes
   `avotek/supabase/migrations/20261014180000_add_paystack_wallet_funding.sql`.
   Verify the migration succeeded before deploying the function.
2. In Supabase **Edge Functions → Secrets**, configure:
   - `PAYSTACK_SECRET_KEY`: use the Paystack **Test Secret Key** while testing.
     The project has been configured with a Test key; this does not prove that
     an authenticated checkout can complete.
   - `PAYSTACK_CALLBACK_URL`: `https://adevictorolu.github.io/Avotek/#/wallet/fund`
   - The Paystack public key is not needed for this server-created checkout
     flow and must not be put in the Flutter app for this integration. Do not
     configure a separate `PAYSTACK_WEBHOOK_SECRET`: webhook signatures are
     checked with the same `PAYSTACK_SECRET_KEY`.
   - The existing Supabase environment variables `SUPABASE_URL`,
     `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` must be available to
     the function runtime. Never put service-role or Paystack secret keys in
     Flutter or Git. Supabase intentionally hides saved secret values; a secrets
     listing can confirm names exist, not reveal their contents. To replace a
     value, set it again in the dashboard.
3. Deploy the function:

   ```powershell
   supabase functions deploy paystack-payments --project-ref gcixbqrridzgobkqnlfz
   ```

   The function uses Paystack's `POST /transaction/initialize` endpoint. It
   sends the amount in kobo (`NGN` × 100) and returns the hosted authorization
   URL. The signed-in app then calls the function to verify the reference,
   which uses Paystack's `GET /transaction/verify/{reference}` endpoint. The
   function checks the Paystack API response status, transaction status,
   reference, NGN currency, and exact amount before calling the server-only
   wallet-credit RPC.

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
5. Test in Test mode using Paystack's test payment details and an authenticated
   Avotek test account. Confirm initialization returns a hosted checkout URL,
   checkout returns to the app with its reference, server verification matches
   the reference and exact amount/currency, and the wallet and ledger update
   once. Confirm the signed `charge.success` webhook also completes the flow,
   and duplicate webhook/verification calls do not add another credit. Test
   declined/failed, abandoned, delayed, wrong-amount, wrong-currency,
   unknown-reference, and invalid-signature cases; none may credit the wallet.
   A return to the app alone never credits funds. Do not move to Live until all
   Test-mode checks pass.
6. The Admin page's **Paystack mode & secrets** button opens Supabase's Edge
   Function secrets page; the app deliberately does not provide a browser-side
   switch that can expose or silently change payment credentials. After the
   Test-mode checks above pass, activate Live by replacing only
   `PAYSTACK_SECRET_KEY` with the Live Secret Key in Supabase. The Paystack
   public key does not control this hosted-checkout flow. Verify the signed
   webhook and complete a controlled low-value Live payment before opening
   funding to customers. If any check is incomplete, keep the Test key active.
7. For Live mode, use a separate production Supabase project where possible.
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
are applied; `vtu-provider` and `paystack-payments` are deployed. The VTU endpoint responds
to CORS preflight and rejects unauthenticated requests, but no authenticated
provider operation has been run. Paystack's callback is configured, and its
unauthenticated initialization request reaches the authentication check. This
does not validate the Paystack key or prove that wallet funding works. Neither
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
`paystack-payments` with a valid JSON body and no user token returned HTTP 401,
“Authentication is required,” reaching the authentication check rather than
the missing-configuration response. `PAYSTACK_CALLBACK_URL` is configured.
This does not establish that the Paystack key is valid, whether it is Test or
Live mode, or that a transaction succeeds. These checks confirm
deployment/routing and fail-closed behavior only. No low-value provider or
Paystack Test transaction has been run.

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

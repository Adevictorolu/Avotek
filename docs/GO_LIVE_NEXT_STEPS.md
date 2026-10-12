# Avotek: what remains before going live

This is the deployment checklist for the current code. A GitHub push does not
deploy Supabase functions, configure Auth redirects, or activate payment
providers. No real wallet top-up or Bigisub purchase should be enabled until
the relevant server configuration and provider tests below pass.

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
2. Set the Bigisub token and aggregator transaction PIN as Supabase Edge
   Function secrets. Rotate any token previously pasted into chat or source
   control; do not paste secrets into GitHub, this document, or Flutter.
3. Set the service-role key only as a Supabase-managed function secret when
   needed by trusted server code; never embed it in the app.
4. Deploy the functions:

   ```powershell
   supabase functions deploy identifier-login
   supabase functions deploy bigisub
   ```

5. Confirm the exact Bigisub endpoint, payload fields, plan-price fields, and
   provider status meanings with Bigisub. The adapter paths were not verified
   against live credentials in this workspace.
6. With a funded provider float, test one low-value transaction for each
   available service. Check provider references/status, customer wallet,
   ledger, confirmed-failure refunds, and duplicate/retry behavior. Do not
   release a transaction whose status is ambiguous; reconcile it with Bigisub.

## 4. Payments and wallet top-ups are still future work

Paystack checkout, dedicated virtual-account creation, webhook signature
verification, webhook idempotency, and verified wallet crediting are **not
implemented** in this repository. Wallet funding must remain disabled until
all of the following are done:

- Select/confirm the payment provider and complete its merchant onboarding.
- Implement server-side payment initialization and a signed, idempotent
  provider webhook, plus atomic database crediting and reconciliation.
- Store provider secrets only in Supabase secrets and deploy the functions.
- Test successful, failed, duplicate, delayed, and tampered webhook events in
  the provider's test environment, then complete a controlled live transaction.
- Only then enable a real provider-assigned funding method in the app.

The app no longer generates pretend bank account numbers. Never ask customers
to transfer to an account displayed by an older deployed build.

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

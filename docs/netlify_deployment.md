# Deploying Avotek on Netlify

The existing Flutter web application is published from the repository root.
The root `netlify.toml` configures the build and publishes only the generated
`avotek/avotek_flutter/build/web` directory, not the Dart source files.

## Automatic deployment

Push the changes to the connected `main` branch. Netlify runs
`scripts/netlify-build.sh`, installs Flutter 3.44.0, restores the committed
workspace dependencies without changing the lockfile, and creates a release
web application. This Flutter version satisfies the SDK requirements in
`avotek/pubspec.lock`.

The workspace lockfile is resolved specifically for Flutter 3.44.0. Flutter
pins some transitive packages, so a lockfile generated with another SDK may
not be compatible even when its minimum SDK requirement is satisfied. Keep
`--enforce-lockfile` enabled during deployment. When updating dependencies or
the deployment SDK, run `flutter pub get` with the same Flutter version used
by the deployment script and include the updated `avotek/pubspec.lock` in
the changes. Verify it with `flutter pub get --enforce-lockfile` before
deploying. Run these commands from `avotek/avotek_flutter`; the shared lockfile
is stored in its parent workspace directory.

The SDK is downloaded from Flutter's official Linux release archive rather
than cloned with Git, so installation works where Git write operations are
restricted. Its SHA-256 checksum is verified before extraction. Installation
is staged in a temporary directory before being moved into the SDK cache,
and temporary files are cleaned up when the script exits.

Before reuse, the SDK cache is checked for valid release metadata, its Dart
runtime, and its packaged Flutter tool. Invalid caches are replaced from the
verified archive. The build runs the packaged Flutter tool directly with its
bundled Dart runtime instead of invoking the Git-dependent shell launcher.
This preserves the archive's real SDK version during dependency resolution
without modifying application SDK constraints or fabricating version data.

The web base path is `/`, unlike the separate GitHub Pages build. Netlify
serves `index.html` for application routes, so direct visits and refreshes
resolve correctly. The build disables generated offline service-worker
caching, and responses revalidate with the server to avoid stale releases.

The build fails if the generated HTML, bootstrap script, or application
JavaScript is missing. Check the Netlify deploy log if the deployment fails;
do not publish the source `web` directory as a substitute for a release build.

## Verify the published site

After Netlify publishes the deployment, run:

```bash
bash scripts/verify-deploy.sh
```

To verify a deploy preview instead, pass its HTTPS URL as the first argument.
The script checks the home page, both JavaScript entry points, and direct
application routes. It verifies response types and content as well as HTTP
success, so a missing script rewritten to HTML does not count as a pass.

In a browser, confirm that the landing page renders, assets load, refreshing
routes works, and the developer console has no startup errors. If an older
release installed a service worker, clear site data before retesting.

## Backend and authentication readiness

Publishing the frontend does not deploy its existing Supabase functions,
apply database migrations, or configure payment providers. Netlify hosting
alone does not establish that sign-in, wallet funding, or purchases work.

In the existing authentication provider's dashboard, set the production Site
URL to `https://avotek.netlify.app/` and allow
`https://avotek.netlify.app/#/login-callback` and
`https://avotek.netlify.app/#/reset-password`. Keep any GitHub Pages callbacks
only if that deployment is still used. Add explicitly approved preview URLs
when testing authentication on deploy previews.

Test a new signup confirmation, email/password login, Google login, password
recovery, and sign-out against the deployed site. Review
`docs/AVOTEK_GO_LIVE_STATUS.md` for existing backend prerequisites before enabling
real financial transactions. No backend data migration or payment activation
is performed by the frontend deployment script.

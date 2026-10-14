#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_version="3.44.0"
flutter_archive_sha256="e1ec95e6c550458a34de93580cb85dac24da0e9bedb9bb42811f050ac5a0c7d5"
flutter_directory="${HOME}/.cache/avotek/flutter-${flutter_version}"

if ! node "${repository_root}/scripts/check-flutter-sdk.cjs" "${flutter_directory}" "${flutter_version}"; then
  mkdir -p "$(dirname "${flutter_directory}")"
  installation_directory="$(mktemp -d "${flutter_directory}.install.XXXXXX")"
  trap 'rm -rf "${installation_directory}"' EXIT
  curl --fail --location --silent --show-error --retry 3 --connect-timeout 30 \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${flutter_version}-stable.tar.xz" \
    --output "${installation_directory}/flutter.tar.xz"
  printf '%s  %s\n' "${flutter_archive_sha256}" \
    "${installation_directory}/flutter.tar.xz" | sha256sum --check --status
  tar -xJf "${installation_directory}/flutter.tar.xz" -C "${installation_directory}"
  if ! node "${repository_root}/scripts/check-flutter-sdk.cjs" "${installation_directory}/flutter" "${flutter_version}"; then
    printf 'Flutter archive is missing valid version metadata or packaged tools.\n' >&2
    exit 1
  fi
  if [[ -e "${flutter_directory}" ]]; then
    rm -rf "${flutter_directory}"
  fi
  mv "${installation_directory}/flutter" "${flutter_directory}"
fi

export FLUTTER_ROOT="${flutter_directory}"
export PATH="${flutter_directory}/bin/cache/dart-sdk/bin:${flutter_directory}/bin:${PATH}"
export CI=true

flutter() {
  "${flutter_directory}/bin/cache/dart-sdk/bin/dart" \
    "${flutter_directory}/bin/cache/flutter_tools.snapshot" \
    --no-version-check "$@"
}

flutter config --no-analytics --enable-web
cd "${repository_root}/avotek/avotek_flutter"
flutter pub get --enforce-lockfile
flutter build web --release --base-href / --pwa-strategy=none

for artifact in index.html flutter_bootstrap.js main.dart.js; do
  if [[ ! -s "build/web/${artifact}" ]]; then
    printf 'Missing Flutter web artifact: %s\n' "${artifact}" >&2
    exit 1
  fi
done

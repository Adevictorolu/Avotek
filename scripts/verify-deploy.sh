#!/usr/bin/env bash
set -euo pipefail

site_url="${1:-https://avotek.netlify.app}"
site_url="${site_url%/}"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "${temporary_directory}"' EXIT

check_response() {
  local route="$1"
  local expected_type="$2"
  local expected_content="$3"
  local response_type

  if ! response_type="$(curl --fail --silent --show-error --location \
    --connect-timeout 10 --max-time 60 \
    --output "${temporary_directory}/response" \
    --write-out '%{content_type}' "${site_url}${route}")"; then
    printf 'FAIL %s: HTTP request failed\n' "${route}" >&2
    exit 1
  fi

  if [[ "${response_type}" != *"${expected_type}"* ]]; then
    printf 'FAIL %s: unexpected response type\n' "${route}" >&2
    exit 1
  fi

  if ! grep -Fq "${expected_content}" "${temporary_directory}/response"; then
    printf 'FAIL %s: expected deployment content is missing\n' "${route}" >&2
    exit 1
  fi

  printf 'PASS %s\n' "${route}"
}

check_response / text/html flutter_bootstrap.js
check_response /flutter_bootstrap.js javascript _flutter
check_response /main.dart.js javascript flutter
check_response /login-callback text/html flutter_bootstrap.js
check_response /reset-password text/html flutter_bootstrap.js
check_response /dashboard text/html flutter_bootstrap.js
printf 'Deployment HTTP checks passed. Browser and backend checks are still required.\n'

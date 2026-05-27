#!/usr/bin/env bash
# Run inside android-emulator-runner (one script invocation — exports persist).
# Expects TEST_PASSWORD_B64 and TEST_SEED_PHRASE_B64 from the Prepare test credentials step.

set -euo pipefail

export PATH="${HOME}/.maestro/bin:${PATH}"

if [[ -z "${TEST_PASSWORD_B64:-}" || -z "${TEST_SEED_PHRASE_B64:-}" ]]; then
  echo "ERROR: TEST_PASSWORD_B64 or TEST_SEED_PHRASE_B64 is not set"
  exit 1
fi

export TEST_PASSWORD="$(printf '%s' "${TEST_PASSWORD_B64}" | base64 -d)"
export TEST_SEED_PHRASE="$(printf '%s' "${TEST_SEED_PHRASE_B64}" | base64 -d)"

if [[ -z "${TEST_PASSWORD}" || -z "${TEST_SEED_PHRASE}" ]]; then
  echo "ERROR: decoded credentials are empty"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

MAESTRO_OUT="${REPO_ROOT}/maestro-ci-output"
mkdir -p "${MAESTRO_OUT}/artifacts" "${MAESTRO_OUT}/reports"

collect_artifacts() {
  if [[ -d "${HOME}/.maestro/tests" ]]; then
    mkdir -p "${MAESTRO_OUT}/maestro-debug"
    cp -a "${HOME}/.maestro/tests/." "${MAESTRO_OUT}/maestro-debug/" || true
  fi
  echo "CI artifact layout:"
  find "${MAESTRO_OUT}" -type f 2>/dev/null | head -50 || true
}
trap collect_artifacts EXIT

adb install -r apps/metamask.apk

MAESTRO_ENV=(
  -e "TEST_PASSWORD=${TEST_PASSWORD}"
  -e "TEST_SEED_PHRASE=${TEST_SEED_PHRASE}"
)

run_maestro_flow() {
  local slug="$1"
  local flow="$2"
  local art_dir="${MAESTRO_OUT}/artifacts/${slug}"
  mkdir -p "${art_dir}"

  echo "=== Maestro: ${slug} ==="
  maestro test "${flow}" "${MAESTRO_ENV[@]}" \
    --test-output-dir "${art_dir}" \
    --debug-output "${art_dir}" \
    --flatten-debug-output \
    --format html-detailed \
    --output "${MAESTRO_OUT}/reports/${slug}.html"
}

run_maestro_flow "01-import-wallet" maestro/flows/01-import-wallet.yaml
run_maestro_flow "02-login-with-password" maestro/flows/02-login-with-password.yaml

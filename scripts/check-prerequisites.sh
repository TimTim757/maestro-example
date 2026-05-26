#!/usr/bin/env bash
# Quick check before running tests. Prints what is missing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=env.sh
source "${SCRIPT_DIR}/env.sh"
# shellcheck source=android-sdk-path.sh
source "${SCRIPT_DIR}/android-sdk-path.sh"

ok=true

echo "=== Maestro MetaMask — prerequisite check ==="
echo ""

if [[ -z "${ANDROID_HOME:-}" ]]; then
  echo "[FAIL] ANDROID_HOME is not set. Add it to ~/.zshrc and run: source ~/.zshrc"
  ok=false
else
  echo "[OK]   ANDROID_HOME=${ANDROID_HOME}"
fi

_setup_java 2>/dev/null || true
_setup_android_path 2>/dev/null || true

if command -v java >/dev/null 2>&1 && java -version >/dev/null 2>&1; then
  echo "[OK]   java found: $(command -v java)"
  java -version 2>&1 | head -1 | sed 's/^/[OK]   /'
else
  echo "[FAIL] java not found — set JAVA_HOME (Android Studio includes a JDK)"
  ok=false
fi

for tool in adb emulator; do
  if command -v "${tool}" >/dev/null 2>&1; then
    echo "[OK]   ${tool} found: $(command -v "${tool}")"
  else
    echo "[FAIL] ${tool} not found"
    ok=false
  fi
done

if command -v sdkmanager >/dev/null 2>&1; then
  echo "[OK]   sdkmanager found: $(command -v sdkmanager)"
else
  echo "[FAIL] sdkmanager not found — install Command-line Tools in Android Studio (SDK Tools tab)"
  ok=false
fi

if command -v avdmanager >/dev/null 2>&1; then
  echo "[OK]   avdmanager found"
else
  echo "[FAIL] avdmanager not found (install Command-line Tools)"
  ok=false
fi

if [[ -f "${APK_PATH}" ]]; then
  echo "[OK]   APK at ${APK_PATH}"
else
  echo "[FAIL] APK missing — copy to apps/metamask.apk"
  ok=false
fi

if [[ -f "${REPO_ROOT}/.env.local" ]]; then
  echo "[OK]   .env.local found"
else
  echo "[WARN] .env.local missing — copy from .env.example"
fi

if [[ -n "${TEST_PASSWORD}" ]]; then
  echo "[OK]   TEST_PASSWORD is set"
else
  echo "[FAIL] TEST_PASSWORD not set — add to .env.local"
  ok=false
fi

if [[ -n "${TEST_SEED_PHRASE}" ]]; then
  echo "[OK]   TEST_SEED_PHRASE is set"
else
  echo "[FAIL] TEST_SEED_PHRASE not set — add to .env.local"
  ok=false
fi

echo ""
echo "System image pin: ${ANDROID_SYSTEM_IMAGE}"
echo "Machine arch:     $(uname -m)"
echo ""

if [[ "${ok}" == true ]]; then
  echo "All checks passed. Run: ./scripts/start-emulator.sh"
  exit 0
fi

echo "Fix the [FAIL] items above, then run this script again."
exit 1

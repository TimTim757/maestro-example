# Shared pinned configuration for local scripts and documentation.
# Source this file from other scripts; do not execute directly.

# Repository root (parent of scripts/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load local secrets (gitignored). Use .env.example as a template.
# Parses KEY=value lines safely (values with spaces must be quoted or use KEY=word1 word2 ...).
_load_dotenv() {
  local file="$1"
  local line key val
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Strip comments and blank lines
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" != *"="* ]] && continue

    key="${line%%=*}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    val="${line#*=}"
    val="${val#"${val%%[![:space:]]*}"}"

    # Strip optional surrounding quotes
    if [[ "$val" =~ ^\".*\"$ ]]; then
      val="${val:1:-1}"
    elif [[ "$val" =~ ^\'.*\'$ ]]; then
      val="${val:1:-1}"
    fi

    export "${key}=${val}"
  done < "$file"
}
_load_dotenv "${REPO_ROOT}/.env.local"

# --- Pinned versions (update deliberately) ---
# Prod APK used locally and in CI (.github/workflows/maestro-android.yml).
METAMASK_APK_VERSION="v7.72.0 (prod)"
METAMASK_APK_URL="https://github.com/MetaMask/metamask-mobile/releases/download/v7.72.0/metamask-blockchain-wall-android3-7.72.0-metamask-main-prod-4333.apk"

ANDROID_API_LEVEL="34"
# CI uses x86_64; Apple Silicon Macs need arm64-v8a (auto-detected below)
if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
  ANDROID_SYSTEM_IMAGE="system-images;android-34;google_apis;arm64-v8a"
else
  ANDROID_SYSTEM_IMAGE="system-images;android-34;google_apis;x86_64"
fi

AVD_NAME="metamask_maestro"
EMULATOR_PROFILE="pixel_6"

MAESTRO_VERSION="2.5.1"

# App under test
APP_ID="io.metamask"
APK_PATH="${REPO_ROOT}/apps/metamask.apk"

# Test credentials: set in .env.local (local) or export / CI -e flags. Never use real funds.
TEST_PASSWORD="${TEST_PASSWORD:-}"
TEST_SEED_PHRASE="${TEST_SEED_PHRASE:-}"

export REPO_ROOT METAMASK_APK_VERSION METAMASK_APK_URL ANDROID_API_LEVEL ANDROID_SYSTEM_IMAGE \
  AVD_NAME EMULATOR_PROFILE MAESTRO_VERSION APP_ID APK_PATH TEST_PASSWORD TEST_SEED_PHRASE

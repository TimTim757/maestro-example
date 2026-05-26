# Resolve Android SDK tool paths and Java (JAVA_HOME). Source from other scripts after env.sh.

_setup_java() {
  if command -v java >/dev/null 2>&1 && java -version >/dev/null 2>&1; then
    return 0
  fi

  local studio_jbr="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  if [[ -x "${studio_jbr}/bin/java" ]]; then
    export JAVA_HOME="${studio_jbr}"
    export PATH="${JAVA_HOME}/bin:${PATH}"
    return 0
  fi

  if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/java" ]]; then
    export PATH="${JAVA_HOME}/bin:${PATH}"
    return 0
  fi

  cat <<'EOF'

ERROR: Java (JDK) not found. sdkmanager and Maestro need it.

Easiest fix on Mac (Android Studio already installed):

  Add to ~/.zshrc:

    export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    export PATH="$JAVA_HOME/bin:$PATH"

  Then run: source ~/.zshrc

Or install JDK 17+ from https://adoptium.net/ and set JAVA_HOME.

EOF
  return 1
}

_setup_android_path() {
  if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
    echo "ERROR: ANDROID_HOME is not set. Run: source ~/.zshrc"
    return 1
  fi

  export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT}}"

  local cmdline_bin=""
  if [[ -x "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" ]]; then
    cmdline_bin="${ANDROID_HOME}/cmdline-tools/latest/bin"
  else
    # Android Studio sometimes installs versioned cmdline-tools (e.g. 17.0)
    local versioned
    versioned="$(find "${ANDROID_HOME}/cmdline-tools" -maxdepth 2 -type f -name sdkmanager 2>/dev/null | head -1 || true)"
    if [[ -n "${versioned}" ]]; then
      cmdline_bin="$(dirname "${versioned}")"
    fi
  fi

  export PATH="${cmdline_bin}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools/bin:${PATH}"
}

_require_sdkmanager() {
  _setup_java || return 1
  _setup_android_path || return 1

  if command -v sdkmanager >/dev/null 2>&1; then
    return 0
  fi

  cat <<'EOF'

ERROR: sdkmanager not found.

Install "Android SDK Command-line Tools" in Android Studio:

  1. Open Android Studio
  2. Settings (macOS: Android Studio → Settings)
  3. Languages & Frameworks → Android SDK
  4. Open the "SDK Tools" tab
  5. Check: "Android SDK Command-line Tools (latest)"
  6. Click Apply → OK and wait for the download

Also install emulator packages on the "SDK Platforms" tab:
  - Android 14.0 ("UpsideDownCake") — API Level 34
  - Expand it → check "Google APIs ARM 64 v8a System Image" (Apple Silicon Mac)

Then open a NEW Terminal window and run:

  source ~/.zshrc
  ./scripts/start-emulator.sh

EOF
  return 1
}

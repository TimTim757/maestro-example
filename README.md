# Maestro MetaMask Mobile — E2E test framework

A reproducible **end-to-end UI test harness** for [MetaMask Mobile](https://github.com/MetaMask/metamask-mobile) on Android. Tests are written in [Maestro](https://maestro.mobile.dev/) YAML flows and executed against a **pinned production APK** on a local emulator or in GitHub Actions.

This repo is a **demo / interview-friendly framework**: shell scripts wrap the Android SDK emulator, APK install, and Maestro CLI so you can run two wallet scenarios with one command.

---

## What this framework does

| Goal | How |
|------|-----|
| **Repeatable runs** | Pinned Maestro CLI (`1.40.0`), API 34 emulator, fixed `apps/metamask.apk` |
| **Safe test data** | Disposable seed + password in `.env.local` (gitignored); never use real funds |
| **Local + CI** | Same flows locally (`./scripts/run-scenarios.sh`) and in [`.github/workflows/maestro-android.yml`](.github/workflows/maestro-android.yml) |
| **Inspectable failures** | Maestro debug output under `~/.maestro/tests/<timestamp>/`; optional **Debugging and Maestro Studio** section for selectors |

**Out of scope:** unit tests inside the MetaMask app, iOS, Maestro Cloud, or shipping the APK in git.

---

## Maestro — short review

[Maestro](https://maestro.mobile.dev/) is an open-source **mobile UI test runner**. You describe user journeys in YAML (`tapOn`, `inputText`, `assertVisible`, …); Maestro drives the app through **adb** (Android) with built-in waits and retries.

**Strengths**

- **Readable flows** — no Page Object boilerplate; good for smoke / regression paths.
- **Fast iteration** — flows are interpreted; edit YAML and re-run.
- **Resilient timing** — automatic waiting reduces flaky `sleep()` calls.
- **Cross-platform** — same idea for Android, iOS, and web (this repo uses Android only).

**Trade-offs**

- **UI coupling** — labels and screens change between app versions; flows must be updated when MetaMask UI changes.
- **Selector strategy** — prefer stable `id:` and text; coordinates (`point:`) are brittle across devices.
- **CLI vs Studio** — `maestro test` does not load `.env.local` by itself; this repo’s scripts pass secrets with `-e` (see **Credentials** section below).
- **No classic breakpoints** in CLI — debug by partial flows, screenshots, Studio, or Maestro’s failure artifacts.

**Why Maestro here:** MetaMask onboarding (seed import, password, modals) is a linear E2E path that Maestro expresses well in ~50 lines of YAML per scenario, with minimal infrastructure beyond an emulator.

---

## How it runs

```
┌──────────────────────────────────────────────────────────────────┐
│  You: ./scripts/run-scenarios.sh                                 │
└────────────────────────────┬─────────────────────────────────────┘
                             │
     ┌───────────────────────┼───────────────────────┐
     ▼                       ▼                       ▼
 start-emulator      wait-for-device          install-app
 (AVD API 34)        (boot + adb ready)       (apps/metamask.apk)
                             │
                             ▼
                    run-maestro.sh
                    maestro test 01-import-wallet.yaml  (-e TEST_*)
                    maestro test 02-login-with-password.yaml
                             │
                             ▼
                    MetaMask (io.metamask) on emulator
```

1. **Emulator** — `scripts/start-emulator.sh` creates/starts AVD `metamask_maestro` (Pixel 6, API 34).
2. **App** — `scripts/install-app.sh` installs `apps/metamask.apk` (`io.metamask`).
3. **Maestro** — `scripts/run-maestro.sh` runs flows in order; stops if scenario 1 fails (`set -e`).
4. **Teardown** — `run-scenarios.sh` stops the emulator on exit.

Configuration and secrets: [`scripts/env.sh`](scripts/env.sh) + [`.env.local`](.env.example) (copy from `.env.example`).

---

## Commands to run

| Command | When to use |
|---------|-------------|
| **`./scripts/run-scenarios.sh`** | **Default** — start emulator, install APK, run both scenarios, stop emulator |
| `./scripts/check-prerequisites.sh` | Verify Java, SDK, APK, `.env.local`, Maestro |
| `./scripts/run-maestro.sh` | Tests only (emulator already running + app installed) |
| `./scripts/maestro-studio.sh` | Visual selector helper (loads `TEST_*` from `.env.local`) |
| `./scripts/start-emulator.sh` | Start emulator only |
| `./scripts/wait-for-device.sh` | Wait until device is booted |
| `./scripts/install-app.sh` | Install / reinstall APK |
| `./scripts/stop-emulator.sh` | Stop emulator |

**First-time setup**

```bash
cp .env.example .env.local
# Edit .env.local — test wallet only (see .env.example)
# Place production APK at apps/metamask.apk (see apps/README.md)
./scripts/check-prerequisites.sh
./scripts/run-scenarios.sh
```

**Emulator already running**

```bash
./scripts/wait-for-device.sh
./scripts/install-app.sh
./scripts/run-maestro.sh
```

**Single scenario** (with credentials; scenario 2 needs 1 in the same session)

```bash
source scripts/env.sh   # loads .env.local
maestro test maestro/flows/01-import-wallet.yaml \
  -e "TEST_PASSWORD=${TEST_PASSWORD}" \
  -e "TEST_SEED_PHRASE=${TEST_SEED_PHRASE}"
```

Close **Maestro Studio** before `maestro test` — both use `adb` and can conflict.

---

## Test scenarios (current implementation)

Verified against **MetaMask production APK** (~7.72.x): import wallet, then unlock after relaunch.

### Scenario 1 — `01-import-wallet.yaml`

`launchApp` with **`clearState: true`** (fresh install).

| Step | Action |
|------|--------|
| Onboarding | Tap **I have an existing wallet** → **Import using Secret Recovery Phrase** |
| Seed | Focus hint field → `inputText: ${TEST_SEED_PHRASE}` → Enter → **Continue** |
| Password | Assert **MetaMask password** → fill `create-password-first-input-field` / `create-password-second-input-field` → tap acknowledgment checkbox (`point: 8%,47%`) → **Create password** (button, `index: 1`) |
| Post-setup | **Continue** (Improve MetaMask) → **Done** (wallet ready) |
| Modals | Close update modal `id: update-needed-modal-close-button` → dismiss **PREDICT AND WIN** with **Not now** |
| Assert | **Add funds** (wallet home) |

### Scenario 2 — `02-login-with-password.yaml`

`launchApp` with **`clearState: false`** (keeps wallet from scenario 1).

| Step | Action |
|------|--------|
| Unlock | **Enter password** → `inputText: ${TEST_PASSWORD}` → **Unlock** |
| Modals | Optional close `update-needed-modal-close-button` |
| Assert | **Add funds** |

Execution order is enforced in [`scripts/run-maestro.sh`](scripts/run-maestro.sh) and [`.maestro/config.yaml`](.maestro/config.yaml).

---

## Project layout

| Path | Role |
|------|------|
| [`maestro/flows/`](maestro/flows/) | Maestro YAML scenarios |
| [`scripts/`](scripts/) | Emulator, install, test runner, Studio helper |
| [`apps/metamask.apk`](apps/metamask.apk) | Pinned APK (you add; gitignored) |
| [`.env.example`](.env.example) | Template for `.env.local` |
| [`.maestro/config.yaml`](.maestro/config.yaml) | Flow execution order |
| [`.github/workflows/maestro-android.yml`](.github/workflows/maestro-android.yml) | CI on Ubuntu + KVM emulator |

Optional local notes: `docs/SETUP_FROM_SCRATCH.md` (gitignored — personal setup walkthrough, not required to run tests).

---

## Credentials

Flows use **`${TEST_SEED_PHRASE}`** and **`${TEST_PASSWORD}`**.

| Environment | How variables are set |
|-------------|------------------------|
| **Scripts** | `.env.local` loaded by `scripts/env.sh` → `maestro test -e ...` in `run-maestro.sh` |
| **CI** | GitHub Actions secrets `TEST_PASSWORD` and `TEST_SEED_PHRASE` (Settings → Secrets and variables → Actions) |
| **Maestro Studio** | Does **not** read `.env.local` — use `./scripts/maestro-studio.sh` or Studio **Env** → add the same keys |

```bash
cp .env.example .env.local
```

Never commit real seeds or mainnet wallets.

---

## APK setup

Pinned **production** build: **v7.72.0** (`io.metamask`).

**Download (same file as CI):**

https://github.com/MetaMask/metamask-mobile/releases/download/v7.72.0/metamask-blockchain-wall-android3-7.72.0-metamask-main-prod-4333.apk

**Local install:**

```bash
mkdir -p apps
curl -fL "https://github.com/MetaMask/metamask-mobile/releases/download/v7.72.0/metamask-blockchain-wall-android3-7.72.0-metamask-main-prod-4333.apk" -o apps/metamask.apk
```

Or download from the [v7.72.0 release page](https://github.com/MetaMask/metamask-mobile/releases/tag/v7.72.0) and save as **`apps/metamask.apk`** (symlink is fine).

Verify: `aapt dump badging apps/metamask.apk | grep package` → `io.metamask`.

See [apps/README.md](apps/README.md). **Do not** use a dev/Expo APK (**Development servers** screen).

---

## Pinned versions

Update deliberately; keep local and CI aligned.

| Component | Value |
|-----------|--------|
| **Maestro CLI** | `1.40.0` (`MAESTRO_VERSION` in `scripts/env.sh`) |
| **Android API** | `34` |
| **System image** | `google_apis` — `arm64-v8a` on Apple Silicon, `x86_64` elsewhere / CI |
| **AVD** | `metamask_maestro`, profile `pixel_6` |
| **App package** | `io.metamask` |
| **MetaMask APK** | `v7.72.0` prod — [direct APK](https://github.com/MetaMask/metamask-mobile/releases/download/v7.72.0/metamask-blockchain-wall-android3-7.72.0-metamask-main-prod-4333.apk) |

---

## Prerequisites

- **JDK 17+**
- **Android SDK** — `ANDROID_HOME`, `adb`, `emulator`, `sdkmanager`
- **curl** (Maestro installer)

**macOS (Apple Silicon):** `scripts/env.sh` selects `arm64-v8a` system image automatically.

**Linux CI:** KVM enabled in the workflow for emulator speed.

**Windows:** Scripts target bash (macOS/Linux/WSL2).

---

## Debugging and Maestro Studio

| Technique | Use |
|-----------|-----|
| **Failure bundle** | After a failed `maestro test`, open the path printed under `~/.maestro/tests/...` (screenshots + logs) |
| **`takeScreenshot`** | Add `- takeScreenshot: name` in YAML at a checkpoint |
| **Partial flow** | Copy steps into `debug-*.yaml` and stop before the step you are fixing |
| **Studio** | `./scripts/maestro-studio.sh` — inspect hierarchy, try `tapOn` / `id:` |

Studio **Env**: add `TEST_SEED_PHRASE` and `TEST_PASSWORD` if variables show as `undefined`.

---

## GitHub Actions

On push/PR to `main`:

1. KVM + Java 17  
2. Download [MetaMask APK v7.72.0](https://github.com/MetaMask/metamask-mobile/releases/download/v7.72.0/metamask-blockchain-wall-android3-7.72.0-metamask-main-prod-4333.apk) into `apps/metamask.apk` (`METAMASK_APK_URL` in [`.github/workflows/maestro-android.yml`](.github/workflows/maestro-android.yml))  
3. Install Maestro `1.40.0`  
4. `android-emulator-runner` — API 34, install APK, run `01-import-wallet.yaml` then `02-login-with-password.yaml`  
5. Upload JUnit artifact from scenario 2  

The APK is **not** in git (too large); CI downloads it from the MetaMask Mobile release URL on each run.

---

## Troubleshooting

| Issue | What to try |
|-------|-------------|
| `APK not found` | `apps/metamask.apk` |
| `TEST_*` not set | `cp .env.example .env.local` |
| `${TEST_SEED_PHRASE}` undefined in Studio | `./scripts/maestro-studio.sh` or Studio Env variables |
| Expo / **Development servers** | Wrong APK — use production build |
| `Unable to launch app io.metamask: null` | Close Studio; `adb devices`; reinstall APK |
| Scenario 2 fails alone | Run scenario 1 first in the same emulator session |
| Assertion on **Add funds** / **MetaMask password** | UI changed — update YAML; use Studio for selectors |
| Apple Silicon image error | Confirm `arm64-v8a` in `scripts/env.sh` |
| Slow emulator (Linux) | KVM / host acceleration |

---

## Safety

- **Disposable** test wallet on emulators only.  
- **Do not** commit APKs, `.env.local`, or real recovery phrases.  
- Passwords in `.env.example` are fake placeholders.

---

## License

Demo / educational use. MetaMask is a trademark of its respective owners; this repository is not affiliated with MetaMask.

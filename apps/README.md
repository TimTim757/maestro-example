# MetaMask APK

Tests expect a **fixed production** APK at:

```
apps/metamask.apk
```

## Pinned download (v7.72.0)

**Direct link (used by GitHub Actions and recommended locally):**

https://github.com/MetaMask/metamask-mobile/releases/download/v7.72.0/metamask-blockchain-wall-android3-7.72.0-metamask-main-prod-4333.apk

**One-line install:**

```bash
mkdir -p apps
curl -fL "https://github.com/MetaMask/metamask-mobile/releases/download/v7.72.0/metamask-blockchain-wall-android3-7.72.0-metamask-main-prod-4333.apk" -o apps/metamask.apk
```

Release page: https://github.com/MetaMask/metamask-mobile/releases/tag/v7.72.0

The same URL is defined as `METAMASK_APK_URL` in [`scripts/env.sh`](../scripts/env.sh) and [`.github/workflows/maestro-android.yml`](../.github/workflows/maestro-android.yml). When upgrading MetaMask, update all three places and re-check Maestro flows.

## Verify package name (optional)

```bash
aapt dump badging apps/metamask.apk | grep package
# Expected: package: name='io.metamask'
```

## CI (GitHub Actions)

Each pipeline run downloads the URL above into `apps/metamask.apk` before `adb install`. The APK is not stored in git (~241MB; over GitHub’s 100MB file limit).

## Important

- **Never commit** `*.apk` to git (see `.gitignore`).
- **Never** use a real Secret Recovery Phrase or funded wallet for these tests.
- **Do not** use a **dev/Expo** APK — you will see **Development servers**, not the wallet UI.

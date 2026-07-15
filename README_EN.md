# CleanBox (净匣)

[中文](./README.md) · [Releases](https://github.com/o2ol/clearnbox/releases) · [MIT](./LICENSE)

TrollStore app that safely cleans reclaimable system/user app caches to free storage.

- **Author:** [o2ol](https://github.com/o2ol)
- **Version:** 0.0.1
- **Bundle:** `com.o2ol.cleanbox`

## Support

| Item | Requirement |
|------|-------------|
| OS | iOS / iPadOS 15.0+ |
| Arch | arm64 |
| Devices | iPhone / iPad |
| Install | TrollStore |

## Features

- Storage overview and reclaimable scan
- System/user app list, search, filter, sort
- Per-app / batch safe clean
- Light/dark mode, URL schemes

## Safety

Default clean: `Caches` (skips login-related paths), `tmp`, `Logs`, snapshots, optional App Groups.

Never: `Documents`, `Preferences`, Cookies, Keychain, WebKit/HTTP storage, app binaries.

## Install

1. Download `.tipa` / `.ipa` from [Releases](https://github.com/o2ol/clearnbox/releases)
2. Install with TrollStore
3. Open → Scan → Clean

## Build

```bash
export THEOS=/path/to/theos
./scripts/build_ipa.sh
```

```bash
./scripts/publish_github_release.sh   # requires gh auth login
```

## Scheme

```
cleanbox://list
cleanbox://settings
cleanbox://app?bundle=com.apple.MobileSMS
```

## Disclaimer

For personal maintenance only. Use at your own risk.

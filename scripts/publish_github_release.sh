#!/bin/bash
set -euo pipefail
# Usage: ./scripts/publish_github_release.sh [version]
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VER="${1:-}"
if [[ -z "$VER" ]]; then
  VER=$(grep '^Version:' control | awk '{print $2}')
fi
TAG="v${VER}"
IPA="$ROOT/CleanBox_${VER}.ipa"
TIPA="$ROOT/CleanBox_${VER}.tipa"
[[ -f "$IPA" ]] || { echo "missing $IPA — run ./scripts/build_ipa.sh first"; exit 1; }
[[ -f "$TIPA" ]] || cp -f "$IPA" "$TIPA"

export PATH="/opt/homebrew/bin:$PATH"
gh auth status >/dev/null

NOTES="CleanBox ${VER}

- TrollStore safe cache cleaner
- iOS / iPadOS 15+ · arm64
- Prefer .tipa

https://github.com/o2ol/clearnbox
"

if gh release view "$TAG" >/dev/null 2>&1; then
  gh release upload "$TAG" "$IPA" "$TIPA" --clobber
else
  gh release create "$TAG" "$IPA" "$TIPA" \
    --title "CleanBox ${VER}" \
    --notes "$NOTES"
fi
echo "OK: https://github.com/o2ol/clearnbox/releases/tag/${TAG}"

#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export THEOS="${THEOS:-/Users/macmini/work/theos}"
export PATH="/opt/homebrew/opt/make/libexec/gnubin:/opt/homebrew/bin:$THEOS/bin:$PATH"
# avoid module cache permission issues in some sandboxes
export HOME="${HOME_OVERRIDE:-$ROOT/.home}"
mkdir -p "$HOME"

make clean
make package FINALPACKAGE=1

DEB=$(ls -t packages/com.o2ol.cleanbox_*.deb | head -1)
echo "DEB=$DEB"

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
dpkg-deb -x "$DEB" "$STAGE"

APP="$STAGE/Applications/CleanBox.app"
if [[ ! -d "$APP" ]]; then
  echo "CleanBox.app not found in deb" >&2
  ls -laR "$STAGE" | head -80
  exit 1
fi

if command -v ldid >/dev/null 2>&1; then
  ldid -Sentitlements.plist "$APP/CleanBox"
fi

IPA_DIR=$(mktemp -d)
mkdir -p "$IPA_DIR/Payload"
cp -a "$APP" "$IPA_DIR/Payload/"

VER=$(grep '^Version:' control | awk '{print $2}')
OUT_IPA="$ROOT/CleanBox_${VER}.ipa"
OUT_TIPA="$ROOT/CleanBox_${VER}.tipa"
rm -f "$OUT_IPA" "$OUT_TIPA"
(
  cd "$IPA_DIR"
  zip -qr "$OUT_IPA" Payload
)
cp -f "$OUT_IPA" "$OUT_TIPA"
ls -lh "$OUT_IPA" "$OUT_TIPA"
echo "OK: $OUT_IPA"

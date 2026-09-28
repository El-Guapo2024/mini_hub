#!/usr/bin/env bash
# Puts Anki's core for Android in place
# (android/app/src/main/jniLibs/<abi>/libmini_hub_bridge.so) from the GitHub
# release the Android Anki bridge workflow published for this exact version
# of the bridge. Needs the gh CLI signed in (GH_TOKEN in CI).
#
# Libraries already there — say, built locally with
# tool/build_anki_bridge_android.sh — are left alone unless FORCE=1.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/android/app/src/main/jniLibs"
ASSET=MiniHubAnkiBridge-android.zip

if [[ -f "$OUT/arm64-v8a/libmini_hub_bridge.so" && "${FORCE:-}" != 1 ]]; then
  echo "Anki bridge already present in $OUT"
  exit 0
fi

tag="anki-bridge-android-$("$ROOT/tool/anki_bridge_key.sh" android)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading ${tag}…"
if ! (cd "$ROOT" && gh release download "$tag" -p "$ASSET" -D "$TMP"); then
  echo "No release $tag. Run the Anki bridge (Android) workflow, or build it" \
    "here with tool/build_anki_bridge_android.sh." >&2
  exit 1
fi

rm -rf "$OUT"
unzip -q "$TMP/$ASSET" -d "$(dirname "$OUT")"
echo "Anki bridge ready in $OUT"

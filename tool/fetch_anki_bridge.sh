#!/usr/bin/env bash
# Puts Anki's core for iOS in place (ios/AnkiBridge/MiniHubAnkiBridge.xcframework)
# from the GitHub release the Anki bridge workflow published for this exact
# version of the bridge. Needs the gh CLI signed in (GH_TOKEN in CI).
#
# A framework already there — say, one built locally with
# tool/build_anki_bridge.sh — is left alone unless FORCE=1.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/ios/AnkiBridge/MiniHubAnkiBridge.xcframework"
ASSET=MiniHubAnkiBridge.xcframework.zip

if [[ -d "$OUT" && "${FORCE:-}" != 1 ]]; then
  echo "Anki bridge already present at $OUT"
  exit 0
fi

tag="anki-bridge-$("$ROOT/tool/anki_bridge_key.sh")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading $tag…"
if ! (cd "$ROOT" && gh release download "$tag" -p "$ASSET" -D "$TMP"); then
  echo "No release $tag. Run the Anki bridge workflow, or build it here" \
    "with tool/build_anki_bridge.sh." >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
ditto -x -k "$TMP/$ASSET" "$(dirname "$OUT")"
echo "Anki bridge ready at $OUT"

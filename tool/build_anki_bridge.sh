#!/usr/bin/env bash
# Builds Anki's core (the mini_hub_bridge crate in an Anki checkout) for the
# iOS simulator and devices, and packs it as ios/AnkiBridge/
# MiniHubAnkiBridge.xcframework. Gitignored: large, and AGPL-licensed.
#
#   ANKI_DIR=~/ws/anki-sync-poc/anki tool/build_anki_bridge.sh
set -euo pipefail

ANKI_DIR="${ANKI_DIR:-$HOME/ws/anki-sync-poc/anki}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/ios/AnkiBridge/MiniHubAnkiBridge.xcframework"
PROFILE="${PROFILE:-release}"
export PROTOC="${PROTOC:-$(command -v protoc || echo /usr/local/bin/protoc)}"
export IPHONEOS_DEPLOYMENT_TARGET=15.6

# Flutter builds the simulator for both arm64 and x86_64 even on an Intel
# Mac, and CocoaPods skips a slice missing either — "Library not found" at
# link. So the simulator slice is a fat library of both.
SIM_TARGETS=(x86_64-apple-ios aarch64-apple-ios-sim)
TARGETS=("${SIM_TARGETS[@]}" aarch64-apple-ios)
[[ "${SIM_ONLY:-}" == 1 ]] && TARGETS=("${SIM_TARGETS[@]}")

flag=()
[[ "$PROFILE" == release ]] && flag=(--release)

for t in "${TARGETS[@]}"; do
  echo "Building for $t ($PROFILE)…"
  (cd "$ANKI_DIR" && cargo build -p mini_hub_bridge --target "$t" ${flag[@]+"${flag[@]}"})
done

lib() { echo "$ANKI_DIR/target/$1/$PROFILE/libmini_hub_bridge.a"; }
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/sim"
lipo -create "$(lib x86_64-apple-ios)" "$(lib aarch64-apple-ios-sim)" \
  -output "$STAGE/sim/libmini_hub_bridge.a"
libs=(-library "$STAGE/sim/libmini_hub_bridge.a")
[[ "${SIM_ONLY:-}" == 1 ]] || libs+=(-library "$(lib aarch64-apple-ios)")

rm -rf "$OUT"
xcodebuild -create-xcframework "${libs[@]}" -output "$OUT"
echo "Anki bridge ready at $OUT"

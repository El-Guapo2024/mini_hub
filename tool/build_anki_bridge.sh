#!/usr/bin/env bash
# Builds Anki's core for iOS: the bridge crate in native/anki_bridge,
# compiled inside a checkout of Anki at the commit pinned in
# native/anki_bridge/ANKI_COMMIT, packed as
# ios/AnkiBridge/MiniHubAnkiBridge.xcframework. Gitignored: large, and
# AGPL-licensed.
#
# App builds in CI don't run this: .github/workflows/anki_bridge.yml runs it
# once per version and publishes the result, and tool/fetch_anki_bridge.sh
# downloads it.
#
#   tool/build_anki_bridge.sh                          # device + simulator
#   SIM_ONLY=1 PROFILE=debug tool/build_anki_bridge.sh # quick, simulator
#   DEVICE_ONLY=1 tool/build_anki_bridge.sh            # iPhone only
#   ZIP=out.zip tool/build_anki_bridge.sh              # also zip it
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANKI_DIR="${ANKI_DIR:-$HOME/ws/anki-sync-poc/anki}"
COMMIT="$(cat "$ROOT/native/anki_bridge/ANKI_COMMIT")"
OUT="$ROOT/ios/AnkiBridge/MiniHubAnkiBridge.xcframework"
PROFILE="${PROFILE:-release}"
export PROTOC="${PROTOC:-$(command -v protoc || echo /usr/local/bin/protoc)}"
export IPHONEOS_DEPLOYMENT_TARGET=15.6

# Anki itself at the pinned commit, with the translation files its build reads.
if [[ ! -d "$ANKI_DIR/.git" ]]; then
  echo "Fetching Anki ${COMMIT}…"
  git init -q "$ANKI_DIR"
  git -C "$ANKI_DIR" remote add origin https://github.com/ankitects/anki.git
  git -C "$ANKI_DIR" fetch -q --depth 1 origin "$COMMIT"
  git -C "$ANKI_DIR" checkout -q FETCH_HEAD
  git -C "$ANKI_DIR" submodule update -q --init --depth 1 ftl/core-repo ftl/qt-repo
fi
have="$(git -C "$ANKI_DIR" rev-parse HEAD)"
if [[ "$have" != "$COMMIT" ]]; then
  echo "Anki checkout is at $have, but ANKI_COMMIT pins $COMMIT" >&2
  exit 1
fi

# The bridge's source lives in this repo; Anki's workspace compiles it.
rm -rf "$ANKI_DIR/mini_hub_bridge"
cp -R "$ROOT/native/anki_bridge" "$ANKI_DIR/mini_hub_bridge"
grep -q '"mini_hub_bridge"' "$ANKI_DIR/Cargo.toml" ||
  perl -0pi -e 's/members = \[/members = [\n  "mini_hub_bridge",/' "$ANKI_DIR/Cargo.toml"

# Flutter builds the simulator for both arm64 and x86_64 even on an Intel
# Mac, and CocoaPods skips a slice missing either — "Library not found" at
# link. So the simulator slice is a fat library of both. Devices are arm64.
SIM_TARGETS=(x86_64-apple-ios aarch64-apple-ios-sim)
DEVICE=aarch64-apple-ios
if [[ "${SIM_ONLY:-}" == 1 ]]; then
  TARGETS=("${SIM_TARGETS[@]}")
elif [[ "${DEVICE_ONLY:-}" == 1 ]]; then
  TARGETS=("$DEVICE")
else
  TARGETS=("${SIM_TARGETS[@]}" "$DEVICE")
fi

# Targets for the toolchain Anki pins (rust-toolchain.toml), not the default.
(cd "$ANKI_DIR" && rustup target add "${TARGETS[@]}" >/dev/null)

flag=()
[[ "$PROFILE" == release ]] && flag=(--release)

for t in "${TARGETS[@]}"; do
  echo "Building for $t ($PROFILE)…"
  (cd "$ANKI_DIR" && cargo build -p mini_hub_bridge --target "$t" ${flag[@]+"${flag[@]}"})
done

lib() { echo "$ANKI_DIR/target/$1/$PROFILE/libmini_hub_bridge.a"; }
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
libs=()
if [[ "${DEVICE_ONLY:-}" != 1 ]]; then
  mkdir -p "$STAGE/sim"
  lipo -create "$(lib x86_64-apple-ios)" "$(lib aarch64-apple-ios-sim)" \
    -output "$STAGE/sim/libmini_hub_bridge.a"
  libs+=(-library "$STAGE/sim/libmini_hub_bridge.a")
fi
if [[ "${SIM_ONLY:-}" != 1 ]]; then
  libs+=(-library "$(lib "$DEVICE")")
fi

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
xcodebuild -create-xcframework "${libs[@]}" -output "$OUT"
echo "Anki bridge ready at $OUT"

if [[ -n "${ZIP:-}" ]]; then
  rm -f "$ZIP"
  ditto -c -k --keepParent "$OUT" "$ZIP"
  echo "Zipped to $ZIP"
fi

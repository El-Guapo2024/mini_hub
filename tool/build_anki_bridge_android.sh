#!/usr/bin/env bash
# Builds Anki's core for Android: the same bridge crate as
# tool/build_anki_bridge.sh, compiled inside a checkout of Anki at the commit
# pinned in native/anki_bridge/ANKI_COMMIT, as one shared library per ABI in
# android/app/src/main/jniLibs/<abi>/libmini_hub_bridge.so. Gitignored: large,
# and AGPL-licensed.
#
# iOS links the core statically into the app binary and Dart finds it in the
# process. Android has no equivalent, so here it is a shared library that
# Gradle packs from jniLibs and Dart opens by name.
#
# App builds in CI don't run this: .github/workflows/anki_bridge_android.yml
# runs it once per version and publishes the result, and
# tool/fetch_anki_bridge_android.sh downloads it.
#
#   tool/build_anki_bridge_android.sh                           # every ABI shipped
#   ABIS=x86_64 PROFILE=debug tool/build_anki_bridge_android.sh # quick, emulator
#   ZIP=out.zip tool/build_anki_bridge_android.sh               # also zip it
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANKI_DIR="${ANKI_DIR:-$HOME/ws/anki-sync-poc/anki}"
COMMIT="$(cat "$ROOT/native/anki_bridge/ANKI_COMMIT")"
OUT="$ROOT/android/app/src/main/jniLibs"
PROFILE="${PROFILE:-release}"
export PROTOC="${PROTOC:-$(command -v protoc || echo /usr/local/bin/protoc)}"

# The oldest Android the app installs on: Flutter's minSdk. Compiled against a
# newer level, the library can call a libc function an older phone lacks and
# fail to load there, and only there.
API=24

# The NDK Flutter itself builds with (flutter.ndkVersion). r28 and later align
# ELF segments to 16 KB by default, which Google Play requires of every native
# library for Android 15 and later; the link flag below says so explicitly
# anyway, so an older NDK cannot quietly produce a library Play refuses.
NDK_VERSION="${NDK_VERSION:-28.2.13676358}"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
NDK="${ANDROID_NDK_ROOT:-$SDK/ndk/$NDK_VERSION}"
if [[ ! -d "$NDK" ]]; then
  echo "No NDK at $NDK. Install it with: sdkmanager \"ndk;$NDK_VERSION\"" >&2
  exit 1
fi
case "$(uname -s)" in
  Darwin) HOST=darwin-x86_64 ;; # also the Apple silicon NDK's name
  *) HOST=linux-x86_64 ;;
esac
BIN="$NDK/toolchains/llvm/prebuilt/$HOST/bin"

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

# The ABIs Flutter puts in a release app bundle. Play serves each phone only
# its own, so shipping all three costs the download nothing.
ABIS=(${ABIS:-arm64-v8a armeabi-v7a x86_64})

triple() {
  case "$1" in
    arm64-v8a) echo aarch64-linux-android ;;
    armeabi-v7a) echo armv7-linux-androideabi ;;
    x86_64) echo x86_64-linux-android ;;
    *) echo "Unknown ABI $1" >&2 && exit 1 ;;
  esac
}
# The NDK's compiler is named for the ABI and API level; for 32-bit ARM the
# prefix differs from Rust's target name.
clang_prefix() {
  case "$1" in
    armeabi-v7a) echo "armv7a-linux-androideabi$API" ;;
    *) echo "$(triple "$1")$API" ;;
  esac
}

targets=()
for abi in "${ABIS[@]}"; do targets+=("$(triple "$abi")"); done
# Targets for the toolchain Anki pins (rust-toolchain.toml), not the default.
(cd "$ANKI_DIR" && rustup target add "${targets[@]}" >/dev/null)

flag=()
[[ "$PROFILE" == release ]] && flag=(--release)

for abi in "${ABIS[@]}"; do
  t="$(triple "$abi")"
  cc="$BIN/$(clang_prefix "$abi")-clang"
  under="${t//-/_}"
  upper="$(echo "$under" | tr '[:lower:]' '[:upper:]')"
  echo "Building for $abi ($t, $PROFILE)…"
  # SQLite, zstd and ring's assembly are C, compiled by the cc crate, which
  # reads these; Cargo reads the linker and flags.
  env "CC_$under=$cc" "CXX_$under=$cc++" "AR_$under=$BIN/llvm-ar" \
    "CARGO_TARGET_${upper}_LINKER=$cc" \
    "CARGO_TARGET_${upper}_RUSTFLAGS=-C link-arg=-Wl,-z,max-page-size=16384" \
    bash -c "cd '$ANKI_DIR' && cargo rustc -p mini_hub_bridge --lib \
      --crate-type cdylib --target '$t' ${flag[*]:-}"
  # cdylib here rather than in Cargo.toml: the crate's manifest is part of
  # the iOS build's key, and editing it would rebuild iOS for nothing.
  so="$ANKI_DIR/target/$t/$PROFILE/libmini_hub_bridge.so"
  mkdir -p "$OUT/$abi"
  # Debug info off, exported symbols kept: Dart looks anki_bridge_call up
  # by name, through the dynamic symbol table, which this leaves alone.
  "$BIN/llvm-strip" --strip-unneeded -o "$OUT/$abi/libmini_hub_bridge.so" "$so"
done

echo "Anki bridge ready in $OUT"
ls -l "$OUT"/*/libmini_hub_bridge.so

if [[ -n "${ZIP:-}" ]]; then
  zip_path="$(cd "$(dirname "$ZIP")" && pwd)/$(basename "$ZIP")"
  rm -f "$zip_path"
  (cd "$(dirname "$OUT")" && zip -qr "$zip_path" "$(basename "$OUT")")
  echo "Zipped to $zip_path"
fi

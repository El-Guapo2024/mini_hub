#!/usr/bin/env bash
# Fails when any native library in an app bundle or APK is not aligned for
# 16 KB memory pages.
#
# Google Play refuses an app for Android 15 and later whose native libraries
# assume 4 KB pages, and says so only after the upload. This app carries
# several: Flutter's engine, sherpa-onnx's speech runtime, Anki's core. Any
# one of them updated to a build made the old way would do it, so every
# bundle is checked before it is sent.
#
#   tool/check_page_size.sh build/app/outputs/bundle/release/app-release.aab
set -euo pipefail

bundle="${1:?usage: $0 <app.aab|app.apk>}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
unzip -q -o "$bundle" 'lib/*.so' 'base/lib/*.so' -d "$TMP" 2>/dev/null || true

readelf="$(command -v readelf || command -v llvm-readelf || true)"
if [[ -z "$readelf" ]]; then
  echo "No readelf on PATH (binutils, or the NDK's llvm-readelf)." >&2
  exit 1
fi

bad=0
count=0
while IFS= read -r -d '' so; do
  count=$((count + 1))
  # Every loadable segment's alignment, as a number of bytes.
  for align in $("$readelf" -lW "$so" | awk '$1 == "LOAD" { print $NF }'); do
    if (( align < 16384 )); then
      echo "4 KB aligned ($align): ${so#"$TMP"/}"
      bad=1
      break
    fi
  done
done < <(find "$TMP" -name '*.so' -print0)

if (( count == 0 )); then
  echo "No native libraries found in $bundle." >&2
  exit 1
fi
if (( bad )); then
  echo "Play will refuse this bundle for Android 15 and later." >&2
  exit 1
fi
echo "All $count native libraries are 16 KB aligned."

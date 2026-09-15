#!/usr/bin/env bash
# Fetches the streaming Chinese+English speech model the companion's mic uses
# into assets/chinese/asr/. The files are ~170MB, so they are gitignored and
# must be fetched before building (locally and in CI).
set -euo pipefail

NAME=sherpa-onnx-x-asr-480ms-streaming-zipformer-transducer-zh-en-punct-int8-2026-06-05
URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/$NAME.tar.bz2"
DEST="$(cd "$(dirname "$0")/.." && pwd)/assets/chinese/asr"
FILES=(encoder.int8.onnx decoder.onnx joiner.int8.onnx tokens.txt)

if [[ -f "$DEST/encoder.int8.onnx" && -f "$DEST/tokens.txt" ]]; then
  echo "ASR model already present in $DEST"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Downloading ${NAME}…"
curl -fL --retry 3 -o "$TMP/model.tar.bz2" "$URL"
tar xjf "$TMP/model.tar.bz2" -C "$TMP"
mkdir -p "$DEST"
for f in "${FILES[@]}"; do
  cp "$TMP/$NAME/$f" "$DEST/$f"
done
echo "ASR model installed in $DEST"

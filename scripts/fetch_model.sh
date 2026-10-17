#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/VietVoice/Resources/Supertonic"
MODEL_DIR="sherpa-onnx-supertonic-3-tts-int8-2026-05-11"
ARCHIVE="$ROOT/.supertonic.tar.bz2"
URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/${MODEL_DIR}.tar.bz2"

mkdir -p "$DEST"

if [[ -f "$DEST/duration_predictor.int8.onnx" && -f "$DEST/voice.bin" ]]; then
  echo "Supertonic model already present."
  exit 0
fi

echo "Downloading Supertonic INT8 model…"
curl -L --fail --retry 3 "$URL" -o "$ARCHIVE"
TMP="$(mktemp -d)"
tar -xjf "$ARCHIVE" -C "$TMP"

for file in \
  duration_predictor.int8.onnx \
  text_encoder.int8.onnx \
  vector_estimator.int8.onnx \
  vocoder.int8.onnx \
  tts.json \
  unicode_indexer.bin \
  voice.bin; do
  cp "$TMP/$MODEL_DIR/$file" "$DEST/$file"
done

rm -rf "$TMP" "$ARCHIVE"
echo "Model installed in $DEST"

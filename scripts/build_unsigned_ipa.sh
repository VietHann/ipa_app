#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This build script requires macOS + Xcode."
  exit 1
fi

command -v xcodegen >/dev/null || { echo "Install XcodeGen: brew install xcodegen"; exit 1; }

./scripts/fetch_model.sh
xcodegen generate
xcodebuild -resolvePackageDependencies -project VietVoice.xcodeproj -scheme VietVoice
rm -rf build Payload VietVoice-unsigned.ipa
xcodebuild \
  -project VietVoice.xcodeproj \
  -scheme VietVoice \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  clean build

APP="build/Build/Products/Release-iphoneos/VietVoice.app"
for file in \
  duration_predictor.int8.onnx \
  text_encoder.int8.onnx \
  vector_estimator.int8.onnx \
  vocoder.int8.onnx \
  tts.json \
  unicode_indexer.bin \
  voice.bin; do
  if [[ ! -f "$APP/$file" && ! -f "$APP/Supertonic/$file" ]]; then
    echo "ERROR: Missing bundled model file: $file"
    find "$APP" -maxdepth 2 -type f | sort
    exit 1
  fi
done

echo "All local TTS model files are bundled."
du -sh "$APP"

mkdir Payload
cp -R "$APP" Payload/
zip -qry VietVoice-unsigned.ipa Payload
ls -lh VietVoice-unsigned.ipa

echo "Created: $ROOT/VietVoice-unsigned.ipa"

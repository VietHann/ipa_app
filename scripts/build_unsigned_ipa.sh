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

mkdir Payload
cp -R build/Build/Products/Release-iphoneos/VietVoice.app Payload/
zip -qry VietVoice-unsigned.ipa Payload

echo "Created: $ROOT/VietVoice-unsigned.ipa"

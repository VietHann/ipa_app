# VietVoice

Native iOS Vietnamese text-to-speech app that runs inference locally on-device.

## Included features

- Vietnamese TTS fully local after installation
- 10 Supertonic speaker IDs
- Speed control (0.75x–1.50x)
- Quality / inference-step control
- WAV playback, seek, export/share
- Local generation history in `Documents/VietVoice`
- No account, API key, backend, analytics, or network call during inference
- iPhone + iPad, iOS 16+

## Stack

- SwiftUI + AVFoundation
- `sherpa-onnx` Swift Package
- Supertonic 3 INT8 multilingual TTS model
- Vietnamese generation via `lang = vi`

## Build on a Mac

```bash
brew install xcodegen
./scripts/fetch_model.sh
xcodegen generate
open VietVoice.xcodeproj
```

Select your Apple Development team in Xcode, choose a connected iPhone, then Run/Archive.

## Build an unsigned IPA

```bash
brew install xcodegen
./scripts/build_unsigned_ipa.sh
```

Output: `VietVoice-unsigned.ipa`.

Unsigned IPA still needs signing before normal installation on a physical iPhone (for example with your own Apple development certificate / sideloading setup).

## GitHub Actions

Push this folder to GitHub and run **Build unsigned IPA** from the Actions tab. The workflow downloads the model, builds the device app on a macOS runner, packages it into an IPA, and uploads it as an artifact.

## Model files

`scripts/fetch_model.sh` downloads:

`sherpa-onnx-supertonic-3-tts-int8-2026-05-11`

The script copies these into the app bundle:

- `duration_predictor.int8.onnx`
- `text_encoder.int8.onnx`
- `vector_estimator.int8.onnx`
- `vocoder.int8.onnx`
- `tts.json`
- `unicode_indexer.bin`
- `voice.bin`

Once they are bundled into the IPA, synthesis works offline.

## Bundle ID

Default: `xyz.noxhub.vietvoice`

Change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` if needed.

## Distribution note

Before redistributing the app publicly, review and comply with the licenses/notices of sherpa-onnx, ONNX Runtime, and the selected TTS model.

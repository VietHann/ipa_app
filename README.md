# VietVoice 2.0

Native iOS Vietnamese text-to-speech app that runs fully on-device after installation.

## 2.0 highlights

- Redesigned three-tab SwiftUI interface: **Studio / Library / Settings**
- Cute glass/pastel visual system with animated waveform/orb and tactile button animations
- Fixed playback state: play/pause now tracks the actual loaded file and supports ±5 second seeking
- Sentence-aware local synthesis: long text is split into manageable phrases before inference
- Smoother output: short edge fades, punctuation-aware pauses, peak normalization, then one WAV is written locally
- Reading presets: Natural, Narration, Soft, Brisk
- Speed, quality/inference-step, sentence-pause controls
- Text normalization for more stable Vietnamese reading
- Clipboard paste, TXT import, demo text, quick clear
- Auto-play after synthesis
- WAV library with search, rename, share, delete, and delete-all
- Persistent settings and optional haptic feedback
- Background audio playback
- No backend, API key, analytics, or network call during inference

## Stack

- SwiftUI + AVFoundation
- `sherpa-onnx` Swift Package
- Supertonic 3 INT8 multilingual TTS model
- Vietnamese generation via `lang = vi`

## Build unsigned IPA with GitHub Actions

Every push to `main` triggers **Build unsigned IPA**. The workflow downloads the TTS model, verifies all model files are bundled into the app, builds for iPhone, and uploads `VietVoice-2.0-unsigned-ipa` as an artifact.

## Build locally on macOS

```bash
brew install xcodegen
./scripts/fetch_model.sh
xcodegen generate
open VietVoice.xcodeproj
```

or:

```bash
./scripts/build_unsigned_ipa.sh
```

The unsigned IPA still needs signing before normal installation on a physical iPhone.

## Local privacy

Once the model is bundled into the installed IPA, text-to-speech synthesis happens on the device. Generated WAV files are saved under the app Documents/VietVoice directory.

## Bundle ID

`xyz.noxhub.vietvoice`

## Credit

`cre: VietHannn`

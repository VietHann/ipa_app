# VietVoice 2.1 — Single Narrator

Native Vietnamese text-to-speech for iPhone, using **one fixed male narrator voice** entirely on-device.

## Voice choice

The app uses Supertonic 3 INT8, voice **M2 (James)**, fixed in code at **sherpa-onnx speaker ID 6**. Its preset is described as *deep, composed male*. In the UI it is called **Trầm · Cinematic Narrator**. This is an **original preset from Supertonic**, **not Adam from ElevenLabs**, and it is not an audio clone or sound-alike guarantee.

- No voice selector or configurable voice ID. Previous user defaults for voice choice are ignored.
- Reading styles change speaking speed, diffusion steps, and sentence pauses **without changing the voice**.
- Vietnamese inference is always local with `lang = vi`, model weights bundled in the IPA.
- Short edge fades and sentence-aware pauses produce WAV PCM16 recordings.
- Studio, search/rename/export/delete library, playback, import TXT, haptics and persisted settings.
- Supports iOS 16+; designed with iPhone 11 in mind, but audio naturalness and runtime speed require device testing.

## Build

GitHub Actions runs automatically on pushes to `main`, verifies the model and narrator configuration, and uploads `VietVoice-2.1-unsigned-ipa`.

For macOS local builds:

```bash
brew install xcodegen
./scripts/fetch_model.sh
./scripts/build_unsigned_ipa.sh
```

Unsigned IPA still requires signing/sideloading to install on a physical iPhone.

## Research

- [Supertonic 3](https://github.com/supertone-oss-archive/supertonic) — offline 31-language open-weight voice engine.
- [sherpa-onnx Supertonic docs](https://github.com/k2-fsa/sherpa/blob/master/docs/source/onnx/tts/supertonic.rst) — iOS-compatible model config.
- [Speaker ID map](https://www.npmjs.com/package/@zhenryx/react-native-sherpa-tts) — F1–F5 = 0–4; M1–M5 = 5–9. Thus M2 = 6.
- [Voice style descriptions](https://huggingface.co/Kyumdroid/supertonic-3-quant) — M2 James: deep, composed male.

Note: Models include all ten speaker embeddings internally; app always selects only M2. Repacking the internal `voice.bin` could break the runtime, so we do not alter it.

## Credits

Model: Supertone / sherpa-onnx. App: **cre: VietHannn**.

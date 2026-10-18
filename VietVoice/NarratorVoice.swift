import Foundation

/// One curated, fixed Supertonic 3 voice. The bundled voice.bin contains 10
/// original presets, but the UI and inference deliberately select only M2.
/// sherpa-onnx maps F1...F5 to 0...4 and M1...M5 to 5...9.
enum NarratorVoice {
    static let speakerID = 6 // M2 / James: deep, composed male
    static let title = "Trầm"
    static let subtitle = "Cinematic Narrator"
    static let description = "Nam trầm · điềm tĩnh · hợp kể chuyện"
}

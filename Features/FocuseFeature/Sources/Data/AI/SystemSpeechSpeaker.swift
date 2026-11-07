//
//  SystemSpeechSpeaker.swift
//  FocuseFeature · Data
//
//  Membacakan balasan asisten (AVSpeechSynthesizer, suara bahasa perangkat). Tidak butuh internet.
//
import AVFoundation
import Combine

final class SystemSpeechSpeaker: NSObject, SpeechSpeaker, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private let speaking = CurrentValueSubject<Bool, Never>(false)

    var isSpeakingPublisher: AnyPublisher<Bool, Never> { speaking.removeDuplicates().eraseToAnyPublisher() }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        // Tanda Markdown dari model jangan ikut dibacakan.
        let plain = text.replacingOccurrences(of: "[*#`_]", with: "", options: .regularExpression)
        // Pencarian suara meninggalkan kategori .record (tanpa output); .playback juga tetap bunyi saat mode senyap.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? session.setActive(true)
        let utterance = AVSpeechUtterance(string: plain)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        speaking.send(true)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speaking.send(synthesizer.isSpeaking)
        // Musik app lain kembali ke volume normal.
        if !synthesizer.isSpeaking { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        speaking.send(synthesizer.isSpeaking)
    }
}

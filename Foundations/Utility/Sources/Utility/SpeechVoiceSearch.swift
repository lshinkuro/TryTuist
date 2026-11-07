//
//  SpeechVoiceSearch.swift
//  Utility
//
//  Ucapan → teks (Speech framework, bahasa Indonesia) untuk pencarian suara & chat asisten.
//  Hanya mendengarkan setelah tombol mic ditekan, dan berhenti sendiri setelah 1,5 detik hening
//  atau saat tombol ditekan lagi.
//
import AVFoundation
import Combine
import Foundation
import Speech

public enum VoiceSearchEvent: Equatable {
    /// Teks sementara selama bicara; `isFinal` = selesai mendengarkan.
    case transcript(String, isFinal: Bool)
    case failed(String)
}

/// Input suara: dimulai hanya dari aksi user (tombol mic).
@MainActor
public protocol VoiceSearch {
    var events: AnyPublisher<VoiceSearchEvent, Never> { get }
    func start() async
    /// Berhenti mendengarkan; teks terakhir dikirim sebagai final.
    func finish()
}

@MainActor
public final class SpeechVoiceSearch: VoiceSearch {
    private static let silenceTimeout: TimeInterval = 1.5

    private let subject = PassthroughSubject<VoiceSearchEvent, Never>()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "id-ID")) ?? SFSpeechRecognizer()
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var lastTranscript = ""

    public init() {}

    public var events: AnyPublisher<VoiceSearchEvent, Never> { subject.eraseToAnyPublisher() }

    public func start() async {
        teardown()
        guard await Self.authorize() else {
            return fail(String(localized: "Izinkan Mikrofon & Pengenalan Suara di Pengaturan untuk cari dengan suara."))
        }
        guard let recognizer, recognizer.isAvailable else {
            return fail(String(localized: "Pencarian suara sedang tidak tersedia. Coba lagi nanti."))
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            // Di perangkat bila didukung: suara tidak dikirim ke server Apple.
            if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            // Tanpa input mic (sering di simulator) format-nya 0 Hz / 0 channel → installTap crash.
            guard format.sampleRate > 0, format.channelCount > 0 else {
                return fail(String(localized: "Mikrofon tidak tersedia di perangkat ini."))
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            engine.prepare()
            try engine.start()
            self.request = request
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let isFinal = result?.isFinal ?? false
                let failed = error != nil
                Task { @MainActor in self?.handle(text: text, isFinal: isFinal, failed: failed) }
            }
            resetSilenceTimer()
        } catch {
            fail(String(localized: "Mikrofon tidak bisa dipakai saat ini."))
        }
    }

    /// Berhenti mendengarkan; hasil terakhir dikirim sebagai final.
    public func finish() {
        silenceTimer?.invalidate()
        guard request != nil else { return }
        stopAudio()
        request?.endAudio()
    }

    private func handle(text: String?, isFinal: Bool, failed: Bool) {
        guard request != nil else { return }   // sudah selesai / dibatalkan
        if let text, !text.isEmpty {
            lastTranscript = text
            subject.send(.transcript(text, isFinal: isFinal))
            resetSilenceTimer()
        }
        guard isFinal || failed else { return }
        if !isFinal {
            // Error (mis. tidak ada suara): pakai yang sudah terdengar, kalau ada.
            if lastTranscript.isEmpty {
                fail(String(localized: "Suaranya belum terdengar. Coba lagi."))
                return
            }
            subject.send(.transcript(lastTranscript, isFinal: true))
        }
        teardown()
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: Self.silenceTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.finish() }
        }
    }

    private func fail(_ message: String) {
        teardown()
        subject.send(.failed(message))
    }

    private func stopAudio() {
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func teardown() {
        silenceTimer?.invalidate()
        stopAudio()
        task?.cancel()
        task = nil
        request = nil
        lastTranscript = ""
    }

    private static func authorize() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        guard speech else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }
}

import AVFoundation
import MWDATCamera
import MWDATCore
import SwiftUI

@MainActor
class GlassesSessionViewModel: ObservableObject {
    @Published var currentVideoFrame: UIImage?
    @Published var isStreaming = false
    @Published var capturedPhoto: UIImage?
    @Published var responseText: String = ""
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage = ""

    private var streamSession: StreamSession
    private var stateToken: AnyListenerToken?
    private var frameToken: AnyListenerToken?
    private var errorToken: AnyListenerToken?
    private var photoToken: AnyListenerToken?
    private let wearables: WearablesInterface
    private let niaService: NiaBackendService
    private let speechSynth = AVSpeechSynthesizer()

    init(wearables: WearablesInterface) {
        self.wearables = wearables
        self.niaService = NiaBackendService()
        let deviceSelector = AutoDeviceSelector(wearables: wearables)
        let config = StreamSessionConfig(
            videoCodec: .raw,
            resolution: .low,
            frameRate: 15
        )
        streamSession = StreamSession(streamSessionConfig: config, deviceSelector: deviceSelector)

        stateToken = streamSession.statePublisher.listen { [weak self] state in
            Task { @MainActor [weak self] in
                self?.isStreaming = (state == .streaming)
            }
        }

        frameToken = streamSession.videoFramePublisher.listen { [weak self] frame in
            Task { @MainActor [weak self] in
                if let image = frame.makeUIImage() {
                    self?.currentVideoFrame = image
                }
            }
        }

        errorToken = streamSession.errorPublisher.listen { [weak self] error in
            Task { @MainActor [weak self] in
                self?.errorMessage = "Stream error: \(error)"
                self?.showError = true
            }
        }

        photoToken = streamSession.photoDataPublisher.listen { [weak self] photoData in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let image = UIImage(data: photoData.data) {
                    self.capturedPhoto = image
                    await self.sendToNia(imageData: photoData.data)
                }
            }
        }
    }

    func startStreaming() async {
        do {
            let status = try await wearables.checkPermissionStatus(.camera)
            if status != .granted {
                let result = try await wearables.requestPermission(.camera)
                guard result == .granted else {
                    errorMessage = "Camera permission denied"
                    showError = true
                    return
                }
            }
            await streamSession.start()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func stopStreaming() async {
        await streamSession.stop()
    }

    func captureAndAsk(prompt: String = "What am I looking at? Describe it concisely.") {
        streamSession.capturePhoto(format: .jpeg)
    }

    private func sendToNia(imageData: Data, prompt: String = "What am I looking at? Describe it concisely.") async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let response = try await niaService.analyzeImage(imageData: imageData, prompt: prompt)
            responseText = response
            speak(response)
        } catch {
            responseText = "Error: \(error.localizedDescription)"
        }
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynth.speak(utterance)
    }

    func dismissError() {
        showError = false
        errorMessage = ""
    }
}

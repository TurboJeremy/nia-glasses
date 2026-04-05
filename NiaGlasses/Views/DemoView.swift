import AVFoundation
import SwiftUI

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Demo ViewModel

@MainActor
class DemoViewModel: NSObject, ObservableObject {
    @Published var responseText: String = ""
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isCameraReady = false

    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let niaService = NiaBackendService()
    private let speechSynth = AVSpeechSynthesizer()
    private var pendingPrompt = "What am I looking at? Describe it concisely."

    func setupCamera() {
        captureSession.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            errorMessage = "Can't access camera"
            showError = true
            return
        }

        if captureSession.canAddInput(input) { captureSession.addInput(input) }
        if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }

        Task.detached { [captureSession] in
            captureSession.startRunning()
            await MainActor.run { self.isCameraReady = true }
        }
    }

    func captureAndAsk(prompt: String = "What am I looking at? Describe it concisely.") {
        pendingPrompt = prompt
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func sendToNia(imageData: Data) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let response = try await niaService.analyzeImage(imageData: imageData, prompt: pendingPrompt)
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

    func stopCamera() {
        captureSession.stopRunning()
    }
}

extension DemoViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        Task { @MainActor in
            await sendToNia(imageData: data)
        }
    }
}

// MARK: - Demo View

struct DemoView: View {
    @StateObject private var viewModel = DemoViewModel()
    @State private var customPrompt = ""
    @State private var showPromptField = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Camera preview
            if viewModel.isCameraReady {
                CameraPreview(session: viewModel.captureSession)
                    .ignoresSafeArea()
            } else {
                ProgressView("Starting camera...")
                    .tint(.white)
                    .foregroundColor(.white)
            }

            // Overlay
            VStack {
                // Demo mode badge
                Text("DEMO MODE — iPhone Camera")
                    .font(.caption2.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    .padding(.top, 60)

                if !viewModel.responseText.isEmpty {
                    Text(viewModel.responseText)
                        .font(.body)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()

                // Controls
                VStack(spacing: 16) {
                    if viewModel.isProcessing {
                        HStack {
                            ProgressView().tint(.white)
                            Text("Nia is thinking...")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }

                    if showPromptField {
                        HStack {
                            TextField("Ask Nia...", text: $customPrompt)
                                .textFieldStyle(.roundedBorder)
                            Button("Send") {
                                viewModel.captureAndAsk(prompt: customPrompt.isEmpty ? "What am I looking at?" : customPrompt)
                                customPrompt = ""
                                showPromptField = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.horizontal)
                    }

                    HStack(spacing: 20) {
                        // Ask Nia
                        Button {
                            viewModel.captureAndAsk()
                        } label: {
                            VStack {
                                Image(systemName: "eye.fill")
                                    .font(.title)
                                Text("Ask Nia")
                                    .font(.caption)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                        }
                        .disabled(viewModel.isProcessing)

                        // Custom prompt
                        Button {
                            showPromptField.toggle()
                        } label: {
                            VStack {
                                Image(systemName: "text.bubble.fill")
                                    .font(.title2)
                                Text("Custom")
                                    .font(.caption)
                            }
                            .frame(width: 70, height: 70)
                            .background(Color.purple.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                        }
                    }
                }
                .padding(.bottom, 40)
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.setupCamera() }
        .onDisappear { viewModel.stopCamera() }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

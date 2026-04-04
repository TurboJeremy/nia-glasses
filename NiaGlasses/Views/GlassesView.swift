import MWDATCore
import SwiftUI

struct GlassesView: View {
    @StateObject private var viewModel: GlassesSessionViewModel
    @State private var customPrompt = ""
    @State private var showPromptField = false

    init(wearables: WearablesInterface) {
        self._viewModel = StateObject(wrappedValue: GlassesSessionViewModel(wearables: wearables))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Live video feed
            if let frame = viewModel.currentVideoFrame {
                GeometryReader { geo in
                    Image(uiImage: frame)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
            } else if viewModel.isStreaming {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }

            // Response overlay
            VStack {
                if !viewModel.responseText.isEmpty {
                    Text(viewModel.responseText)
                        .font(.body)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Controls
                VStack(spacing: 16) {
                    if viewModel.isProcessing {
                        HStack {
                            ProgressView()
                                .tint(.white)
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
                        if viewModel.isStreaming {
                            // Ask Nia button (capture + analyze)
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

                            // Stop
                            Button {
                                Task { await viewModel.stopStreaming() }
                            } label: {
                                VStack {
                                    Image(systemName: "stop.fill")
                                        .font(.title2)
                                    Text("Stop")
                                        .font(.caption)
                                }
                                .frame(width: 70, height: 70)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                            }
                        } else {
                            Button {
                                Task { await viewModel.startStreaming() }
                            } label: {
                                Label("Start Streaming", systemImage: "video.fill")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

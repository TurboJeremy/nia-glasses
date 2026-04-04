import MWDATCore
import SwiftUI

struct MainView: View {
    let wearables: WearablesInterface
    @ObservedObject var viewModel: WearablesViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Status header
                VStack(spacing: 8) {
                    Image(systemName: "eyeglasses")
                        .font(.system(size: 60))
                        .foregroundColor(viewModel.devices.isEmpty ? .gray : .blue)

                    Text("Nia Glasses")
                        .font(.largeTitle.bold())

                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                Spacer()

                // Connection controls
                if viewModel.registrationState == .registered {
                    if viewModel.devices.isEmpty {
                        Text("Waiting for glasses...")
                            .foregroundColor(.secondary)
                        ProgressView()
                    } else {
                        NavigationLink {
                            GlassesView(wearables: wearables)
                        } label: {
                            Label("Open Camera", systemImage: "camera.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }

                    Button("Disconnect") {
                        viewModel.disconnectGlasses()
                    }
                    .foregroundColor(.red)
                } else {
                    Button {
                        viewModel.connectGlasses()
                    } label: {
                        Label("Connect Glasses", systemImage: "link")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.registrationState == .registering)

                    if viewModel.registrationState == .registering {
                        ProgressView("Connecting...")
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    private var statusText: String {
        switch viewModel.registrationState {
        case .registered:
            return viewModel.devices.isEmpty
                ? "Connected — no glasses detected"
                : "\(viewModel.devices.count) device(s) ready"
        case .registering:
            return "Connecting to Meta AI..."
        case .unregistered:
            return "Tap to connect your Ray-Ban Meta glasses"
        @unknown default:
            return ""
        }
    }
}

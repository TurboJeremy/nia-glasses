import Combine
import MWDATCore
import SwiftUI

#if DEBUG
import MWDATMockDevice
#endif

/// Debug menu for testing without physical glasses connected.
@MainActor
class DebugMenuViewModel: ObservableObject {
    @Published var isSimulating = false
    @Published var statusMessage = "Not connected"

    private let wearables: WearablesInterface

    init(wearables: WearablesInterface) {
        self.wearables = wearables
    }

    #if DEBUG
    /// Start a mock device session for testing without real glasses
    func startMockSession() {
        guard !isSimulating else { return }
        isSimulating = true
        statusMessage = "Mock device active"

        Task {
            do {
                let mockDevice = MockDeviceBuilder()
                    .setName("Mock Ray-Ban")
                    .build()
                try await mockDevice.connect()
                statusMessage = "Mock device connected"
            } catch {
                statusMessage = "Mock failed: \(error.localizedDescription)"
                isSimulating = false
            }
        }
    }

    func stopMockSession() {
        isSimulating = false
        statusMessage = "Disconnected"
    }
    #endif
}

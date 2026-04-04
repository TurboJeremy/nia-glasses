#if DEBUG
import Combine
import MWDATMockDevice
import SwiftUI

@MainActor
class DebugMenuViewModel: ObservableObject {
    @Published var showDebugMenu: Bool = false

    let mockDeviceKitViewModel: MockDeviceKitViewModel

    init(mockDeviceKit: MockDeviceKit) {
        self.mockDeviceKitViewModel = MockDeviceKitViewModel(mockDeviceKit: mockDeviceKit)
    }
}
#endif

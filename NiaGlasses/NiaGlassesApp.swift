import Foundation
import MWDATCore
import SwiftUI

#if DEBUG
import MWDATMockDevice
#endif

@main
struct NiaGlassesApp: App {
    #if DEBUG
    @StateObject private var debugMenuViewModel = DebugMenuViewModel(mockDeviceKit: MockDeviceKit.shared)
    #endif
    private let wearables: WearablesInterface
    @StateObject private var wearablesViewModel: WearablesViewModel

    init() {
        do {
            try Wearables.configure()
        } catch {
            #if DEBUG
            NSLog("[NiaGlasses] Failed to configure Wearables SDK: \(error)")
            #endif
        }

        let wearables = Wearables.shared
        self.wearables = wearables
        self._wearablesViewModel = StateObject(wrappedValue: WearablesViewModel(wearables: wearables))
    }

    var body: some Scene {
        WindowGroup {
            MainView(wearables: wearables, viewModel: wearablesViewModel)
                .alert("Error", isPresented: $wearablesViewModel.showError) {
                    Button("OK") { wearablesViewModel.dismissError() }
                } message: {
                    Text(wearablesViewModel.errorMessage)
                }
                #if DEBUG
                .overlay(alignment: .topTrailing) {
                    Button("Mock Device") {
                        debugMenuViewModel.showDebugMenu = true
                    }
                    .padding()
                    .font(.caption)
                }
                .sheet(isPresented: $debugMenuViewModel.showDebugMenu) {
                    MockDeviceKitView(viewModel: debugMenuViewModel.mockDeviceKitViewModel)
                }
                #endif
        }
    }
}

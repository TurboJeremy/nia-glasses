import Foundation
import MWDATCore
import SwiftUI

@main
struct NiaGlassesApp: App {
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
                .onOpenURL { url in
                    #if DEBUG
                    NSLog("[NiaGlasses] Received deep link: \(url)")
                    #endif
                    // Forward the callback URL to the Wearables SDK
                    // so it can complete the registration flow
                    Wearables.handleURL(url)
                }
                .alert("Error", isPresented: $wearablesViewModel.showError) {
                    Button("OK") { wearablesViewModel.dismissError() }
                } message: {
                    Text(wearablesViewModel.errorMessage)
                }
        }
    }
}

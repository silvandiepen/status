import Foundation
import Testing
import StatusCore
@testable import StatusUI

@MainActor
@Test func pluginStoreViewModelLoadsRuntimeStatusesForInstalledPlugins() async throws {
    let plugin = InstalledPlugin(
        id: "com.status.github",
        name: "GitHub",
        author: "Status Foundry",
        description: "GitHub repository checks.",
        category: "development",
        trustLevel: .official,
        installedVersion: "0.1.0",
        installPath: "/tmp/com.status.github",
        installedAt: Date(timeIntervalSince1970: 1_783_433_520),
        updatedAt: Date(timeIntervalSince1970: 1_783_433_520)
    )
    let runtimeStatus = PluginRuntimeStatus(
        pluginID: plugin.id,
        status: .failed,
        detail: "Missing network permission.",
        timestamp: Date(timeIntervalSince1970: 1_783_433_530)
    )
    var loadedStatusPluginIDs: [[String]] = []
    let viewModel = PluginStoreViewModel(
        loadInstalled: { [plugin] },
        loadAvailable: { [] },
        loadRuntimeStatuses: { plugins in
            loadedStatusPluginIDs.append(plugins.map(\.id))
            return [plugin.id: runtimeStatus]
        },
        installPlugin: { _ in }
    )

    await viewModel.reload()

    #expect(loadedStatusPluginIDs == [[plugin.id]])
    #expect(viewModel.runtimeStatuses == [plugin.id: runtimeStatus])
}

import StatusCore
import StatusUI
import SwiftUI

@main
struct StatusMacApp: App {
    var body: some Scene {
        WindowGroup {
            MacRootView()
        }
        .windowStyle(.titleBar)
    }
}

private struct MacRootView: View {
    @State private var selection: MacSection? = .overview

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: MacSection.overview) {
                    Label("Overview", systemImage: "rectangle.grid.2x2")
                }
                NavigationLink(value: MacSection.integrations) {
                    Label("Integrations", systemImage: "puzzlepiece.extension")
                }
                NavigationLink(value: MacSection.audit) {
                    Label("Audit Log", systemImage: "list.bullet.rectangle")
                }
                NavigationLink(value: MacSection.settings) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .navigationTitle("Status")
        } detail: {
            switch selection ?? .overview {
            case .overview:
                DashboardContainerView(viewModel: makeDashboardViewModel())
                    .navigationTitle("Overview")
            case .integrations:
                PluginStoreContainerView(viewModel: makePluginStoreViewModel(platform: .macOS))
                    .navigationTitle("Integrations")
            case .audit:
                DashboardContainerView(viewModel: makeDashboardViewModel())
                    .navigationTitle("Audit Log")
            case .settings:
                Text("Settings")
                    .navigationTitle("Settings")
            }
        }
    }

    private func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel {
            try LocalStatusStore.openApplicationSupportStore().dashboardSnapshot()
        }
    }

    private func makePluginStoreViewModel(platform: PluginPlatform) -> PluginStoreViewModel {
        let registry = PluginRegistryClient(baseURL: registryBaseURL)
        return PluginStoreViewModel {
            try LocalStatusStore.openApplicationSupportStore().installedPlugins()
        } loadAvailable: {
            try await registry.plugins(platform: platform, coreVersion: "0.1.0")
        } installPlugin: { plugin in
            guard let latestVersion = plugin.latestVersion else { return }
            let store = try LocalStatusStore.openApplicationSupportStore()
            let installRoot = try pluginInstallRoot()
            let installer = PluginInstaller(
                registry: registry,
                store: store,
                installRoot: installRoot
            )
            _ = try await installer.install(
                pluginID: plugin.id,
                version: latestVersion,
                trustLevel: plugin.trustLevel
            )
        }
    }

    private var registryBaseURL: URL {
        URL(string: "https://status-registry.hakobs.com")!
    }

    private func pluginInstallRoot() throws -> URL {
        let databaseURL = try LocalStatusStore.applicationSupportDatabaseURL()
        let directory = databaseURL.deletingLastPathComponent().appendingPathComponent("Plugins", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private enum MacSection: Hashable {
    case overview
    case integrations
    case audit
    case settings
}

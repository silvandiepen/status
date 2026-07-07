import StatusCore
import StatusUI
import SwiftUI

@main
struct StatusiOSApp: App {
    var body: some Scene {
        WindowGroup {
            IOSRootView()
        }
    }
}

private struct IOSRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardContainerView(viewModel: makeDashboardViewModel())
                    .navigationTitle("Overview")
            }
            .tabItem {
                Label("Overview", systemImage: "rectangle.grid.2x2")
            }

            NavigationStack {
                AlertsView(items: loadOpenAlerts())
                    .navigationTitle("Alerts")
            }
            .tabItem {
                Label("Alerts", systemImage: "bell")
            }

            NavigationStack {
                PluginStoreContainerView(viewModel: makePluginStoreViewModel(platform: .iOS))
                    .navigationTitle("Integrations")
            }
            .tabItem {
                Label("Integrations", systemImage: "puzzlepiece.extension")
            }

            NavigationStack {
                RulesListView(rules: loadRules())
                    .navigationTitle("Rules")
            }
            .tabItem {
                Label("Rules", systemImage: "slider.horizontal.3")
            }

            NavigationStack {
                StatusSettingsView(
                    registryURL: registryBaseURL,
                    databasePath: applicationDatabasePath(),
                    pluginInstallPath: applicationPluginInstallPath()
                )
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
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

    private func loadOpenAlerts() -> [StatusItem] {
        ((try? LocalStatusStore.openApplicationSupportStore().statusItems(limit: 50)) ?? [])
            .filter { $0.severity >= .warning }
    }

    private func loadRules() -> [Rule] {
        (try? LocalStatusStore.openApplicationSupportStore().rules()) ?? []
    }

    private func applicationDatabasePath() -> String {
        (try? LocalStatusStore.applicationSupportDatabaseURL().path) ?? "Unavailable"
    }

    private func applicationPluginInstallPath() -> String {
        (try? pluginInstallRoot().path) ?? "Unavailable"
    }

    private func pluginInstallRoot() throws -> URL {
        let databaseURL = try LocalStatusStore.applicationSupportDatabaseURL()
        let directory = databaseURL.deletingLastPathComponent().appendingPathComponent("Plugins", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

import StatusCore
import SwiftUI

public struct PluginStoreCatalog: Equatable, Sendable {
    public var installed: [InstalledPlugin]
    public var available: [RegistryPluginSummary]

    public init(installed: [InstalledPlugin] = [], available: [RegistryPluginSummary] = []) {
        self.installed = installed
        self.available = available
    }
}

@MainActor
public final class PluginStoreViewModel: ObservableObject {
    @Published public private(set) var catalog: PluginStoreCatalog
    @Published public private(set) var loadError: String?
    @Published public private(set) var installingPluginID: String?

    private let loadInstalled: () throws -> [InstalledPlugin]
    private let loadAvailable: () async throws -> [RegistryPluginSummary]
    private let installPlugin: (RegistryPluginSummary) async throws -> Void

    public init(
        initialCatalog: PluginStoreCatalog = PluginStoreCatalog(),
        loadInstalled: @escaping () throws -> [InstalledPlugin],
        loadAvailable: @escaping () async throws -> [RegistryPluginSummary],
        installPlugin: @escaping (RegistryPluginSummary) async throws -> Void
    ) {
        self.catalog = initialCatalog
        self.loadInstalled = loadInstalled
        self.loadAvailable = loadAvailable
        self.installPlugin = installPlugin
    }

    public func reload() async {
        do {
            let installed = try loadInstalled()
            let available = try await loadAvailable()
            catalog = PluginStoreCatalog(installed: installed, available: available)
            loadError = nil
        } catch {
            catalog = PluginStoreCatalog(installed: (try? loadInstalled()) ?? [], available: [])
            loadError = error.localizedDescription
        }
    }

    public func install(_ plugin: RegistryPluginSummary) async {
        guard installingPluginID == nil else { return }
        guard plugin.latestVersion != nil else {
            loadError = "Plugin has no installable version."
            return
        }

        installingPluginID = plugin.id
        defer { installingPluginID = nil }

        do {
            try await installPlugin(plugin)
            await reload()
        } catch {
            loadError = error.localizedDescription
        }
    }
}

public struct PluginStoreContainerView: View {
    @StateObject private var viewModel: PluginStoreViewModel

    public init(viewModel: @autoclosure @escaping () -> PluginStoreViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        PluginStoreView(
            catalog: viewModel.catalog,
            installingPluginID: viewModel.installingPluginID,
            install: { plugin in
                Task {
                    await viewModel.install(plugin)
                }
            }
        )
        .overlay(alignment: .bottom) {
            if let loadError = viewModel.loadError {
                Text(loadError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(10)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
        }
        .task {
            await viewModel.reload()
        }
        .refreshable {
            await viewModel.reload()
        }
    }
}

public struct PluginStoreView: View {
    private let catalog: PluginStoreCatalog
    private let installingPluginID: String?
    private let install: (RegistryPluginSummary) -> Void

    public init(
        catalog: PluginStoreCatalog,
        installingPluginID: String? = nil,
        install: @escaping (RegistryPluginSummary) -> Void = { _ in }
    ) {
        self.catalog = catalog
        self.installingPluginID = installingPluginID
        self.install = install
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PluginStoreHeader(installedCount: catalog.installed.count, availableCount: catalog.available.count)
                InstalledPluginSection(plugins: catalog.installed)
                AvailablePluginSection(
                    plugins: catalog.available,
                    installedPluginIDs: Set(catalog.installed.map(\.id)),
                    installingPluginID: installingPluginID,
                    install: install
                )
            }
            .padding(24)
            .frame(maxWidth: 1120, alignment: .leading)
        }
        .background(Color.statusBackground)
    }
}

private struct PluginStoreHeader: View {
    let installedCount: Int
    let availableCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Integrations")
                .font(.system(size: 42, weight: .semibold, design: .default))
            Text("\(installedCount) installed, \(availableCount) available from the Status registry.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InstalledPluginSection: View {
    let plugins: [InstalledPlugin]

    var body: some View {
        PluginSection(title: "Installed") {
            if plugins.isEmpty {
                EmptyPluginState(
                    title: "No plugins installed",
                    detail: "Install read-only integrations from the registry to start collecting status events."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(plugins) { plugin in
                        InstalledPluginRow(plugin: plugin)
                    }
                }
            }
        }
    }
}

private struct AvailablePluginSection: View {
    let plugins: [RegistryPluginSummary]
    let installedPluginIDs: Set<String>
    let installingPluginID: String?
    let install: (RegistryPluginSummary) -> Void

    var body: some View {
        PluginSection(title: "Registry") {
            if plugins.isEmpty {
                EmptyPluginState(
                    title: "Registry unavailable",
                    detail: "Installed plugins still work locally. The registry can be refreshed when the network is available."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(plugins) { plugin in
                        AvailablePluginRow(
                            plugin: plugin,
                            isInstalled: installedPluginIDs.contains(plugin.id),
                            isInstalling: installingPluginID == plugin.id,
                            install: install
                        )
                    }
                }
            }
        }
    }
}

private struct InstalledPluginRow: View {
    let plugin: InstalledPlugin

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PluginTrustIcon(trustLevel: plugin.trustLevel)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(plugin.name)
                        .font(.headline)
                    Text(plugin.installedVersion)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Text(plugin.description)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(plugin.enabled ? "Enabled" : "Disabled")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(plugin.enabled ? .green : .orange)
            }
            Spacer(minLength: 12)
            PluginTrustLabel(trustLevel: plugin.trustLevel)
        }
        .padding(14)
        .background(Color.statusSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AvailablePluginRow: View {
    let plugin: RegistryPluginSummary
    let isInstalled: Bool
    let isInstalling: Bool
    let install: (RegistryPluginSummary) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                PluginTrustIcon(trustLevel: plugin.trustLevel)
                    .padding(.top, 4)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(plugin.name)
                            .font(.headline)
                        if let latestVersion = plugin.latestVersion {
                            Text(latestVersion)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(plugin.summary)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                Button {
                    install(plugin)
                } label: {
                    if isInstalling {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(isInstalled ? "Installed" : "Install")
                    }
                }
                .disabled(isInstalled || isInstalling || plugin.latestVersion == nil)
                .buttonStyle(.borderedProminent)
            }

            PluginMetadataLine(label: "Permissions", values: plugin.permissions.map(\.rawValue))
            PluginMetadataLine(label: "Domains", values: plugin.domains)
        }
        .padding(14)
        .background(Color.statusSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PluginMetadataLine: View {
    let label: String
    let values: [String]

    var body: some View {
        if values.isEmpty == false {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(values.joined(separator: ", "))
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
    }
}

private struct PluginTrustLabel: View {
    let trustLevel: PluginTrustLevel

    var body: some View {
        Text(trustLevel.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(trustLevel.color)
            .background(trustLevel.color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct PluginTrustIcon: View {
    let trustLevel: PluginTrustLevel

    var body: some View {
        Image(systemName: trustLevel.iconName)
            .foregroundStyle(trustLevel.color)
            .frame(width: 22)
            .accessibilityLabel(Text(trustLevel.label))
    }
}

private struct EmptyPluginState: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(detail)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.statusSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PluginSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.weight(.semibold))
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension PluginTrustLevel {
    var label: String {
        switch self {
        case .official:
            "Official"
        case .verifiedThirdParty:
            "Verified"
        case .localDev:
            "Local"
        }
    }

    var iconName: String {
        switch self {
        case .official:
            "checkmark.seal.fill"
        case .verifiedThirdParty:
            "checkmark.shield.fill"
        case .localDev:
            "hammer.fill"
        }
    }

    var color: Color {
        switch self {
        case .official:
            .green
        case .verifiedThirdParty:
            .blue
        case .localDev:
            .orange
        }
    }
}

private extension Color {
    static let statusBackground = Color(red: 0.965, green: 0.965, blue: 0.945)
    static let statusSurface = Color.white.opacity(0.92)
}

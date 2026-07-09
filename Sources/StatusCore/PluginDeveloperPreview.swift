import Foundation

public struct PluginDeveloperPreviewResult: Equatable, Sendable {
    public var pluginID: String
    public var requestID: String
    public var accountID: String
    public var resources: [MappedPluginResource]
    public var events: [Event]
    public var metrics: [MappedPluginMetric]
    public var warnings: [PluginMappingWarning]

    public init(
        pluginID: String,
        requestID: String,
        accountID: String,
        resources: [MappedPluginResource],
        events: [Event],
        metrics: [MappedPluginMetric],
        warnings: [PluginMappingWarning]
    ) {
        self.pluginID = pluginID
        self.requestID = requestID
        self.accountID = accountID
        self.resources = resources
        self.events = events
        self.metrics = metrics
        self.warnings = warnings
    }

    public var summary: String {
        "\(resources.count) resources, \(events.count) events, \(metrics.count) metrics"
    }
}

public enum PluginDeveloperPreviewError: Error, Equatable, LocalizedError, Sendable {
    case pluginNotInstalled(String)
    case packageUnavailable(String)
    case requestUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .pluginNotInstalled(let pluginID):
            "Plugin is not installed: \(pluginID)"
        case .packageUnavailable(let pluginID):
            "Installed plugin package is unavailable: \(pluginID)"
        case .requestUnavailable(let pluginID):
            "Installed plugin has no request to preview: \(pluginID)"
        }
    }
}

public final class PluginDeveloperPreviewer {
    private let store: StatusPersistenceStore
    private let decoder = JSONDecoder()

    public init(store: StatusPersistenceStore) {
        self.store = store
    }

    public func previewFixture(
        pluginID: String,
        requestID: String? = nil,
        accountID: String? = nil,
        fixtureData: Data,
        capturedAt: Date = Date()
    ) throws -> PluginDeveloperPreviewResult {
        guard let plugin = try store.installedPlugin(id: pluginID), plugin.enabled else {
            throw PluginDeveloperPreviewError.pluginNotInstalled(pluginID)
        }
        guard let definition = try store.installedPluginDefinition(pluginID: pluginID) else {
            throw PluginDeveloperPreviewError.packageUnavailable(pluginID)
        }
        let resolvedRequestID = try requestID ?? firstRequestID(in: definition, pluginID: pluginID)
        let payload = try decoder.decode(MappingJSONValue.self, from: fixtureData)
        let account = try accountContext(pluginID: pluginID, accountID: accountID)

        let output = try PluginMappingExecutor.execute(
            definition.mappings,
            input: PluginMappingExecutionInput(
                pluginID: pluginID,
                accountID: account.id,
                provider: pluginID,
                requestID: resolvedRequestID,
                payload: payload,
                capturedAt: capturedAt,
                account: .object(account.variables.mapValues(MappingJSONValue.string))
            )
        )

        return PluginDeveloperPreviewResult(
            pluginID: pluginID,
            requestID: resolvedRequestID,
            accountID: account.id,
            resources: output.resources,
            events: output.events,
            metrics: output.metrics,
            warnings: output.warnings
        )
    }

    private func firstRequestID(in definition: PluginPackageDefinition, pluginID: String) throws -> String {
        guard let requestID = definition.requests.requests.keys.sorted().first else {
            throw PluginDeveloperPreviewError.requestUnavailable(pluginID)
        }
        return requestID
    }

    private func accountContext(pluginID: String, accountID: String?) throws -> PluginAccountConfiguration {
        if let accountID,
           let configuration = try store.accountConfiguration(accountID: accountID) {
            return configuration
        }
        if let configuration = try store.accountConfigurations(pluginID: pluginID).first {
            return configuration
        }
        return PluginAccountConfiguration(
            id: "preview_\(pluginID.replacingOccurrences(of: ".", with: "_"))",
            pluginID: pluginID,
            accountName: "Preview",
            variables: [:]
        )
    }
}

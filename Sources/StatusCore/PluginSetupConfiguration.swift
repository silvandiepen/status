import Foundation

public enum PluginSetupConfigurationError: Error, Equatable, LocalizedError, Sendable {
    case setupUnavailable(String)
    case missingRequiredField(String)
    case invalidHostname(String)
    case invalidURL(String)
    case secretFieldRequiresCredentialStore(String)

    public var errorDescription: String? {
        switch self {
        case .setupUnavailable(let pluginID):
            "Plugin has no setup form: \(pluginID)"
        case .missingRequiredField(let label):
            "Required setup field is empty: \(label)"
        case .invalidHostname(let label):
            "Enter a valid host name for \(label)."
        case .invalidURL(let label):
            "Enter a valid https URL for \(label)."
        case .secretFieldRequiresCredentialStore(let label):
            "Secret setup field requires Keychain storage: \(label)"
        }
    }
}

public enum PluginSetupConfiguration {
    public static func configuredValues(pluginID: String, store: StatusPersistenceStore) throws -> [String: String] {
        try store.accountConfigurations(pluginID: pluginID).first?.variables ?? [:]
    }

    public static func saveValues(
        _ values: [String: String],
        for plugin: InstalledPlugin,
        service: PluginRuntimeService,
        now: Date = Date()
    ) throws -> String {
        guard let setup = plugin.setup else {
            throw PluginSetupConfigurationError.setupUnavailable(plugin.id)
        }
        var normalized: [String: String] = [:]
        for field in setup.fields {
            let rawValue = values[field.id, default: field.defaultValue ?? ""]
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if field.required && trimmed.isEmpty {
                throw PluginSetupConfigurationError.missingRequiredField(field.label)
            }
            guard field.type.isPlainConfigurationField else {
                if trimmed.isEmpty == false {
                    throw PluginSetupConfigurationError.secretFieldRequiresCredentialStore(field.label)
                }
                continue
            }
            normalized[field.id] = try normalize(trimmed, field: field)
        }

        let displayName = displayName(for: plugin, values: normalized)
        try service.saveAccountConfiguration(
            PluginAccountConfiguration(
                id: accountID(pluginID: plugin.id, displayName: displayName),
                pluginID: plugin.id,
                accountName: displayName,
                variables: normalized
            ),
            now: now
        )
        return "Saved \(displayName)."
    }

    public static func accountID(pluginID: String, displayName: String) -> String {
        let raw = "\(pluginID)_\(displayName)"
        let sanitized = raw
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return "acct_\(sanitized)"
    }

    private static func normalize(_ value: String, field: PackagedPluginSetupField) throws -> String {
        switch field.type {
        case .hostname:
            return try normalizedHost(value, label: field.label)
        case .url:
            return try normalizedURL(value, label: field.label)
        case .toggle:
            return value == "true" ? "true" : "false"
        case .text, .number, .select:
            return value
        case .secret, .secretFile:
            return value
        }
    }

    private static func normalizedHost(_ value: String, label: String) throws -> String {
        var host = value.lowercased()
        if host.hasPrefix("https://") || host.hasPrefix("http://") {
            host = URL(string: host)?.host ?? host
        }
        host = host.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard host.contains("."),
              host.contains(" ") == false,
              host.contains("/") == false,
              host.contains(":") == false else {
            throw PluginSetupConfigurationError.invalidHostname(label)
        }
        return host
    }

    private static func normalizedURL(_ value: String, label: String) throws -> String {
        guard value.isEmpty == false else { return "" }
        guard let url = URL(string: value),
              url.scheme == "https",
              url.host?.isEmpty == false else {
            throw PluginSetupConfigurationError.invalidURL(label)
        }
        return url.absoluteString
    }

    private static func displayName(for plugin: InstalledPlugin, values: [String: String]) -> String {
        if plugin.id == WebsitePluginSetup.pluginID, let host = values["host"], host.isEmpty == false {
            return host
        }
        if let host = values["host"], host.isEmpty == false {
            return host
        }
        if let owner = values["owner"], let repo = values["repo"], owner.isEmpty == false, repo.isEmpty == false {
            return "\(owner)/\(repo)"
        }
        if let firstValue = values.sorted(by: { $0.key < $1.key }).first(where: { $0.value.isEmpty == false })?.value {
            return firstValue
        }
        return plugin.name
    }
}

public extension PackagedPluginSetupFieldType {
    var isPlainConfigurationField: Bool {
        switch self {
        case .text, .url, .hostname, .number, .toggle, .select:
            true
        case .secret, .secretFile:
            false
        }
    }
}

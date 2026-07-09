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
    public static let dashboardTileFieldsKey = "_status.dashboardTileFields"

    public static func configuredValues(pluginID: String, store: StatusPersistenceStore) throws -> [String: String] {
        try store.accountConfigurations(pluginID: pluginID).first?.variables ?? [:]
    }

    public static func configuredValues(pluginID: String, accountID: String, store: StatusPersistenceStore) throws -> [String: String] {
        try store.accountConfiguration(accountID: accountID)?.variables ?? [:]
    }

    public static func configuredAccount(pluginID: String, store: StatusPersistenceStore) throws -> PluginAccountConfiguration {
        guard let configuration = try store.accountConfigurations(pluginID: pluginID).first else {
            throw PluginRuntimeServiceError.accountNotConfigured(pluginID)
        }
        return configuration
    }

    public static func saveValues(
        _ values: [String: String],
        for plugin: InstalledPlugin,
        service: PluginRuntimeService,
        credentialStore: CredentialStore? = nil,
        accountID: String? = nil,
        displayNameOverride: String? = nil,
        now: Date = Date()
    ) throws -> String {
        guard plugin.setup != nil || plugin.auth != nil else {
            throw PluginSetupConfigurationError.setupUnavailable(plugin.id)
        }
        let normalized = try normalizedSetupValues(
            values,
            for: plugin,
            service: service,
            accountID: accountID
        )
        var credentialRef: String?
        var authType = "none"

        if let auth = plugin.auth, auth.type != .none {
            authType = auth.type.rawValue
            switch auth.type {
            case .bearerToken:
                credentialRef = try storeBearerToken(from: auth.fields, values: values, plugin: plugin, credentialStore: credentialStore)
            case .none:
                break
            case .apiKey, .basicAuth, .jwtAPIKey:
                credentialRef = try storeCredentialBundle(from: auth.fields, values: values, plugin: plugin, credentialStore: credentialStore)
            case .privateKeyJWT:
                throw PluginSetupConfigurationError.secretFieldRequiresCredentialStore(auth.type.rawValue)
            case .oauth2:
                credentialRef = try storeOAuthTokenSet(from: values, plugin: plugin, credentialStore: credentialStore)
            }
        }

        let displayName = displayNameOverride?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? displayName(for: plugin, values: normalized)
        try service.saveAccountConfiguration(
            PluginAccountConfiguration(
                id: accountID ?? self.accountID(pluginID: plugin.id, displayName: displayName),
                pluginID: plugin.id,
                accountName: displayName,
                variables: normalized,
                authType: authType,
                credentialRef: credentialRef
            ),
            now: now
        )
        return "Saved \(displayName)."
    }

    public static func saveOAuthTokenSet(
        _ tokenSet: PluginOAuthTokenSet,
        setupValues values: [String: String],
        for plugin: InstalledPlugin,
        service: PluginRuntimeService,
        credentialStore: CredentialStore,
        accountID: String? = nil,
        displayNameOverride: String? = nil,
        now: Date = Date()
    ) throws -> String {
        guard plugin.auth?.type == .oauth2 else {
            throw PluginSetupConfigurationError.setupUnavailable(plugin.id)
        }
        let normalized = try normalizedSetupValues(
            values,
            for: plugin,
            service: service,
            accountID: accountID
        )
        let data = try JSONEncoder().encode(tokenSet)
        let credentialRef = try credentialStore.store(data, label: "\(plugin.name) OAuth tokens")
        let displayName = displayNameOverride?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? displayName(for: plugin, values: normalized)
        try service.saveAccountConfiguration(
            PluginAccountConfiguration(
                id: accountID ?? self.accountID(pluginID: plugin.id, displayName: displayName),
                pluginID: plugin.id,
                accountName: displayName,
                variables: normalized,
                authType: AuthKind.oauth2.rawValue,
                credentialRef: credentialRef
            ),
            now: now
        )
        return "Saved \(displayName)."
    }

    @discardableResult
    public static func deleteAccountConfiguration(
        accountID: String,
        store: StatusPersistenceStore,
        credentialStore: CredentialStore
    ) throws -> String? {
        let configuration = try store.accountConfiguration(accountID: accountID)
        try store.deleteAccountConfiguration(accountID: accountID)
        if let credentialRef = configuration?.credentialRef {
            try credentialStore.delete(reference: credentialRef)
        }
        return configuration?.accountName
    }

    public static func accountID(pluginID: String, displayName: String) -> String {
        let raw = "\(pluginID)_\(displayName)"
        let sanitized = raw
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return "acct_\(sanitized)"
    }

    private static func normalizedSetupValues(
        _ values: [String: String],
        for plugin: InstalledPlugin,
        service: PluginRuntimeService,
        accountID: String?
    ) throws -> [String: String] {
        var normalized: [String: String] = [:]
        for field in plugin.setup?.fields ?? [] {
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
        if let accountID,
           let existing = try service.store.accountConfiguration(accountID: accountID) {
            for (key, value) in existing.variables where key.hasPrefix("_status.") {
                normalized[key] = value
            }
        }
        return normalized
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

    private static func storeBearerToken(
        from fields: [PackagedPluginSetupField],
        values: [String: String],
        plugin: InstalledPlugin,
        credentialStore: CredentialStore?
    ) throws -> String? {
        guard let tokenField = fields.first(where: { $0.type == .secret || $0.type == .text }) else {
            return nil
        }
        let token = values[tokenField.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        if tokenField.required && token.isEmpty {
            throw PluginSetupConfigurationError.missingRequiredField(tokenField.label)
        }
        guard token.isEmpty == false else {
            return nil
        }
        guard let credentialStore else {
            throw PluginSetupConfigurationError.secretFieldRequiresCredentialStore(tokenField.label)
        }
        return try credentialStore.store(Data(token.utf8), label: "\(plugin.name) \(tokenField.label)")
    }

    private static func storeCredentialBundle(
        from fields: [PackagedPluginSetupField],
        values: [String: String],
        plugin: InstalledPlugin,
        credentialStore: CredentialStore?
    ) throws -> String? {
        var credentialFields: [String: String] = [:]
        for field in fields {
            let value = values[field.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
            if field.required && value.isEmpty {
                throw PluginSetupConfigurationError.missingRequiredField(field.label)
            }
            if value.isEmpty == false {
                credentialFields[field.id] = value
            }
        }
        guard credentialFields.isEmpty == false else {
            return nil
        }
        guard let credentialStore else {
            throw PluginSetupConfigurationError.secretFieldRequiresCredentialStore(plugin.name)
        }
        let data = try JSONEncoder().encode(PluginAuthCredentialBundle(fields: credentialFields))
        return try credentialStore.store(data, label: "\(plugin.name) credentials")
    }

    private static func storeOAuthTokenSet(
        from values: [String: String],
        plugin: InstalledPlugin,
        credentialStore: CredentialStore?
    ) throws -> String? {
        let accessToken = values["accessToken", default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        guard accessToken.isEmpty == false else {
            return nil
        }
        guard let credentialStore else {
            throw PluginSetupConfigurationError.secretFieldRequiresCredentialStore("OAuth2")
        }
        let expiresAt: Date?
        if let expiresAtValue = values["expiresAt"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           expiresAtValue.isEmpty == false {
            expiresAt = ISO8601DateFormatter().date(from: expiresAtValue)
        } else if let expiresInValue = values["expiresIn"].flatMap(TimeInterval.init) {
            expiresAt = Date().addingTimeInterval(expiresInValue)
        } else {
            expiresAt = nil
        }
        let tokenSet = PluginOAuthTokenSet(
            accessToken: accessToken,
            refreshToken: values["refreshToken"]?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty,
            tokenType: values["tokenType"]?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Bearer",
            scope: values["scope"]?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty,
            expiresAt: expiresAt
        )
        let data = try JSONEncoder().encode(tokenSet)
        return try credentialStore.store(data, label: "\(plugin.name) OAuth tokens")
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

public struct PluginAuthCredentialBundle: Codable, Equatable, Sendable {
    public var fields: [String: String]

    public init(fields: [String: String]) {
        self.fields = fields
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

import Foundation

public enum PluginPlatform: String, Codable, CaseIterable, Sendable {
    case macOS
    case iOS
}

public enum PluginPermission: String, Codable, CaseIterable, Sendable {
    case network
    case keychain
    case oauth
    case apiKey = "api-key"
    case privateKey = "private-key"
    case backgroundRefresh = "background-refresh"
    case pushWebhook = "push-webhook"
    case userConfiguredDomains = "user-configured-domains"
    case writeActions = "write-actions"
    case localNotificationSuggestion = "local-notification-suggestion"
}

public enum PluginValidationError: Error, Equatable, LocalizedError, Sendable {
    case invalidIdentifier(String)
    case invalidVersion(String)
    case emptyField(String)
    case noPlatform
    case noDomainForNetworkPermission
    case domainContainsScheme(String)
    case domainContainsPath(String)
    case domainContainsWildcard(String)
    case undeclaredRequestDomain(String)
    case writeActionWithoutPermission(String)
    case unsupportedOAuthInV1

    public var errorDescription: String? {
        switch self {
        case .invalidIdentifier(let value):
            "Plugin id must be reverse-DNS style: \(value)"
        case .invalidVersion(let value):
            "Plugin version must be semver: \(value)"
        case .emptyField(let field):
            "Plugin manifest field is required: \(field)"
        case .noPlatform:
            "Plugin must support at least one platform."
        case .noDomainForNetworkPermission:
            "Plugins with network permission must declare domains."
        case .domainContainsScheme(let domain):
            "Plugin domains must be hosts, not URLs: \(domain)"
        case .domainContainsPath(let domain):
            "Plugin domains must not contain paths: \(domain)"
        case .domainContainsWildcard(let domain):
            "Plugin domains must not use wildcards in v1: \(domain)"
        case .undeclaredRequestDomain(let domain):
            "Plugin request uses undeclared domain: \(domain)"
        case .writeActionWithoutPermission(let action):
            "Plugin action requires write-actions permission: \(action)"
        case .unsupportedOAuthInV1:
            "OAuth2 is defined in schema but deferred past v1."
        }
    }
}

public struct PluginManifest: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var version: String
    public var author: String
    public var category: String
    public var description: String
    public var icon: String?
    public var minCoreVersion: String
    public var platforms: [PluginPlatform]
    public var permissions: [PluginPermission]
    public var domains: [String]

    public init(
        id: String,
        name: String,
        version: String,
        author: String,
        category: String,
        description: String,
        icon: String? = nil,
        minCoreVersion: String,
        platforms: [PluginPlatform],
        permissions: [PluginPermission],
        domains: [String]
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.category = category
        self.description = description
        self.icon = icon
        self.minCoreVersion = minCoreVersion
        self.platforms = platforms
        self.permissions = permissions
        self.domains = domains
    }
}

public enum AuthKind: String, Codable, Sendable {
    case none
    case apiKey = "api-key"
    case bearerToken = "bearer-token"
    case basicAuth = "basic-auth"
    case oauth2
    case jwtAPIKey = "jwt-api-key"
    case privateKeyJWT = "private-key-jwt"
}

public struct PluginRequestDefinition: Equatable, Sendable {
    public var id: String
    public var method: String
    public var url: URL

    public init(id: String, method: String, url: URL) {
        self.id = id
        self.method = method
        self.url = url
    }
}

public struct PluginActionDeclaration: Equatable, Sendable {
    public var type: String
    public var label: String
    public var requiresWritePermission: Bool

    public init(type: String, label: String, requiresWritePermission: Bool) {
        self.type = type
        self.label = label
        self.requiresWritePermission = requiresWritePermission
    }
}

public struct PluginValidationInput: Equatable, Sendable {
    public var manifest: PluginManifest
    public var authKinds: [AuthKind]
    public var requests: [PluginRequestDefinition]
    public var actions: [PluginActionDeclaration]

    public init(
        manifest: PluginManifest,
        authKinds: [AuthKind] = [],
        requests: [PluginRequestDefinition] = [],
        actions: [PluginActionDeclaration] = []
    ) {
        self.manifest = manifest
        self.authKinds = authKinds
        self.requests = requests
        self.actions = actions
    }
}

public enum PluginManifestValidator {
    public static func validate(_ input: PluginValidationInput) throws {
        let manifest = input.manifest

        try requireReverseDNS(manifest.id)
        try requireSemver(manifest.version)
        try requireSemver(manifest.minCoreVersion)
        try requireNonEmpty(manifest.name, field: "name")
        try requireNonEmpty(manifest.author, field: "author")
        try requireNonEmpty(manifest.category, field: "category")
        try requireNonEmpty(manifest.description, field: "description")

        guard manifest.platforms.isEmpty == false else {
            throw PluginValidationError.noPlatform
        }

        if manifest.permissions.contains(.network),
           manifest.permissions.contains(.userConfiguredDomains) == false,
           manifest.domains.isEmpty {
            throw PluginValidationError.noDomainForNetworkPermission
        }

        for domain in manifest.domains {
            try validateDomain(domain)
        }

        let declaredDomains = Set(manifest.domains.map { $0.lowercased() })
        for request in input.requests {
            let host = request.url.host?.lowercased() ?? ""
            if manifest.permissions.contains(.userConfiguredDomains) {
                continue
            }
            guard declaredDomains.contains(host) else {
                throw PluginValidationError.undeclaredRequestDomain(host)
            }
        }

        if input.authKinds.contains(.oauth2) {
            throw PluginValidationError.unsupportedOAuthInV1
        }

        let hasWritePermission = manifest.permissions.contains(.writeActions)
        for action in input.actions where action.requiresWritePermission && hasWritePermission == false {
            throw PluginValidationError.writeActionWithoutPermission(action.type)
        }
    }

    private static func requireNonEmpty(_ value: String, field: String) throws {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw PluginValidationError.emptyField(field)
        }
    }

    private static func requireReverseDNS(_ value: String) throws {
        let parts = value.split(separator: ".")
        let isValid = parts.count >= 3 && parts.allSatisfy { part in
            part.range(of: #"^[a-z][a-z0-9-]*$"#, options: .regularExpression) != nil
        }

        if isValid == false {
            throw PluginValidationError.invalidIdentifier(value)
        }
    }

    private static func requireSemver(_ value: String) throws {
        let isValid = value.range(of: #"^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$"#, options: .regularExpression) != nil
        if isValid == false {
            throw PluginValidationError.invalidVersion(value)
        }
    }

    private static func validateDomain(_ domain: String) throws {
        if domain.contains("://") {
            throw PluginValidationError.domainContainsScheme(domain)
        }
        if domain.contains("/") {
            throw PluginValidationError.domainContainsPath(domain)
        }
        if domain.contains("*") {
            throw PluginValidationError.domainContainsWildcard(domain)
        }
        try requireNonEmpty(domain, field: "domains")
    }
}

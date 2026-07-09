import Foundation

public struct LocalPluginInstallResult: Equatable, Sendable {
    public var plugin: InstalledPlugin
    public var version: InstalledPluginVersion
    public var warnings: [LocalPluginInstallWarning]

    public init(
        plugin: InstalledPlugin,
        version: InstalledPluginVersion,
        warnings: [LocalPluginInstallWarning]
    ) {
        self.plugin = plugin
        self.version = version
        self.warnings = warnings
    }
}

public enum LocalPluginInstallWarning: Equatable, Sendable {
    case unsignedLocalDevPlugin(pluginID: String, permissions: [PluginPermission], domains: [String])
}

public enum LocalPluginInstallerError: Error, Equatable, LocalizedError, Sendable {
    case invalidRequestURL(requestID: String, url: String)

    public var errorDescription: String? {
        switch self {
        case .invalidRequestURL(let requestID, let url):
            "Local plugin request \(requestID) has an invalid URL: \(url)"
        }
    }
}

public final class LocalPluginInstaller {
    private let store: StatusPersistenceStore
    private let installRoot: URL
    private let fileManager: FileManager
    private let decoder = JSONDecoder()

    public init(
        store: StatusPersistenceStore,
        installRoot: URL,
        fileManager: FileManager = .default
    ) {
        self.store = store
        self.installRoot = installRoot
        self.fileManager = fileManager
    }

    public func install(pluginDirectory: URL, installedAt: Date = Date()) throws -> LocalPluginInstallResult {
        let manifestURL = pluginDirectory.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try decoder.decode(PluginManifest.self, from: manifestData)

        let packageData = try PluginPackageBuilder.packageData(fromDirectory: pluginDirectory, fileManager: fileManager)
        let packageDefinition = try PluginPackageDefinition.decode(from: packageData)
        try PluginManifestValidator.validate(
            PluginValidationInput(
                manifest: manifest,
                authKinds: packageDefinition.auth.map { [$0.type] } ?? [],
                authDefinitions: packageDefinition.auth.map { [$0] } ?? [],
                requests: try validationRequests(from: packageDefinition.requests),
                actions: packageDefinition.actions.map { action in
                    PluginActionDeclaration(
                        type: action.id,
                        label: action.label,
                        requiresWritePermission: action.requiresWritePermission
                    )
                }
            )
        )
        let installDirectory = installRoot
            .appendingPathComponent(manifest.id, isDirectory: true)
            .appendingPathComponent(manifest.version, isDirectory: true)
        try fileManager.createDirectory(at: installDirectory, withIntermediateDirectories: true)

        let installedManifestURL = installDirectory.appendingPathComponent("manifest.json")
        let packageURL = installDirectory.appendingPathComponent("\(manifest.id)-\(manifest.version).statusplugin.zip")
        try manifestData.write(to: installedManifestURL, options: .atomic)
        try packageData.write(to: packageURL, options: .atomic)

        try store.installPlugin(
            PluginInstallRecord(
                manifest: manifest,
                trustLevel: .localDev,
                installPath: installDirectory.path,
                packagePath: packageURL.path,
                verification: PluginPackageVerificationResult(
                    pluginID: manifest.id,
                    version: manifest.version,
                    sha256: PluginPackageVerifier.sha256Hex(packageData),
                    signedBy: "local-dev"
                ),
                packageDefinition: packageDefinition,
                installedAt: installedAt
            )
        )

        guard let plugin = try store.installedPlugin(id: manifest.id),
              let version = try store.installedPluginVersions(pluginID: manifest.id).first(where: { $0.version == manifest.version }) else {
            throw PluginInstallerError.installRecordMissing(manifest.id, manifest.version)
        }

        return LocalPluginInstallResult(
            plugin: plugin,
            version: version,
            warnings: [
                .unsignedLocalDevPlugin(
                    pluginID: manifest.id,
                    permissions: manifest.permissions,
                    domains: manifest.domains
                )
            ]
        )
    }

    private func validationRequests(from requests: PackagedPluginRequests) throws -> [PluginRequestDefinition] {
        try requests.requests.map { requestID, request in
            guard let url = URL(string: request.url) else {
                throw LocalPluginInstallerError.invalidRequestURL(requestID: requestID, url: request.url)
            }
            return PluginRequestDefinition(id: requestID, method: request.method, url: url)
        }
    }
}

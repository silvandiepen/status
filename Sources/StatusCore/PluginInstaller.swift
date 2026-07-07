import Foundation

public protocol PluginRegistryMetadataProvider: Sendable {
    func version(pluginID: String, version: String) async throws -> RegistryPluginVersion
    func revocations() async throws -> RegistryRevocationsResponse
}

extension PluginRegistryClient: PluginRegistryMetadataProvider {}

public struct PluginInstallResult: Equatable, Sendable {
    public var plugin: InstalledPlugin
    public var version: InstalledPluginVersion
    public var verification: PluginPackageVerificationResult

    public init(plugin: InstalledPlugin, version: InstalledPluginVersion, verification: PluginPackageVerificationResult) {
        self.plugin = plugin
        self.version = version
        self.verification = verification
    }
}

public final class PluginInstaller {
    private let registry: PluginRegistryMetadataProvider
    private let packageTransport: RegistryHTTPTransport
    private let store: StatusPersistenceStore
    private let installRoot: URL
    private let fileManager: FileManager
    private let decoder = JSONDecoder()

    public init(
        registry: PluginRegistryMetadataProvider,
        packageTransport: RegistryHTTPTransport = URLSessionRegistryTransport(),
        store: StatusPersistenceStore,
        installRoot: URL,
        fileManager: FileManager = .default
    ) {
        self.registry = registry
        self.packageTransport = packageTransport
        self.store = store
        self.installRoot = installRoot
        self.fileManager = fileManager
    }

    public func install(pluginID: String, version requestedVersion: String, trustLevel: PluginTrustLevel, installedAt: Date = Date()) async throws -> PluginInstallResult {
        let version = try await registry.version(pluginID: pluginID, version: requestedVersion)
        let revocations = try await registry.revocations()
        let packageData = try await packageTransport.data(from: version.packageUrl)
        let manifestData = try await packageTransport.data(from: version.manifestUrl)
        let manifest = try decoder.decode(PluginManifest.self, from: manifestData)
        let verification = try PluginPackageVerifier.verify(
            packageData: packageData,
            version: version,
            revocations: revocations
        )
        let packageDefinition = try PluginPackageDefinition.decode(from: packageData)

        let installDirectory = installRoot
            .appendingPathComponent(manifest.id, isDirectory: true)
            .appendingPathComponent(manifest.version, isDirectory: true)
        try fileManager.createDirectory(at: installDirectory, withIntermediateDirectories: true)

        let manifestURL = installDirectory.appendingPathComponent("manifest.json")
        let packageURL = installDirectory.appendingPathComponent("\(manifest.id)-\(manifest.version).statusplugin.zip")
        try manifestData.write(to: manifestURL, options: .atomic)
        try packageData.write(to: packageURL, options: .atomic)

        let record = PluginInstallRecord(
            manifest: manifest,
            trustLevel: trustLevel,
            installPath: installDirectory.path,
            packagePath: packageURL.path,
            verification: verification,
            signature: version.signature,
            packageDefinition: packageDefinition,
            installedAt: installedAt
        )
        try store.installPlugin(record)

        guard let plugin = try store.installedPlugin(id: manifest.id),
              let installedVersion = try store.installedPluginVersions(pluginID: manifest.id).first(where: { $0.version == manifest.version }) else {
            throw PluginInstallerError.installRecordMissing(manifest.id, manifest.version)
        }

        return PluginInstallResult(plugin: plugin, version: installedVersion, verification: verification)
    }
}

public enum PluginInstallerError: Error, Equatable, LocalizedError, Sendable {
    case installRecordMissing(String, String)

    public var errorDescription: String? {
        switch self {
        case .installRecordMissing(let pluginID, let version):
            "Installed plugin record was not written for \(pluginID) \(version)."
        }
    }
}

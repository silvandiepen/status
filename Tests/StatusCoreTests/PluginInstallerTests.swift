import Foundation
import Testing
@testable import StatusCore

@Test func pluginInstallerDownloadsVerifiesWritesAndPersistsPlugin() async throws {
    let database = try temporaryDatabase()
    try StatusDatabaseMigrator.migrate(database)
    let store = StatusPersistenceStore(database: database)
    let packageData = Data("plugin package".utf8)
    let manifest = githubManifest()
    let manifestData = try JSONEncoder().encode(manifest)
    let version = RegistryPluginVersion(
        pluginId: manifest.id,
        version: manifest.version,
        minCoreVersion: manifest.minCoreVersion,
        platforms: manifest.platforms,
        packageUrl: try #require(URL(string: "https://status-registry.hakobs.com/package.zip")),
        manifestUrl: try #require(URL(string: "https://status-registry.hakobs.com/manifest.json")),
        sha256: PluginPackageVerifier.sha256Hex(packageData),
        signature: "dev-signature",
        signedBy: "status-foundry-dev",
        releasedAt: Date(timeIntervalSince1970: 1_783_433_520)
    )
    let registry = FakeRegistryMetadataProvider(version: version, revocations: emptyRevocations())
    let transport = FakePackageTransport(responses: [
        version.packageUrl: packageData,
        version.manifestUrl: manifestData
    ])
    let installRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("status-plugin-installer-\(UUID().uuidString)", isDirectory: true)
    let installer = PluginInstaller(
        registry: registry,
        packageTransport: transport,
        store: store,
        installRoot: installRoot
    )
    let installedAt = Date(timeIntervalSince1970: 1_783_433_520)

    let result = try await installer.install(pluginID: manifest.id, version: manifest.version, trustLevel: .official, installedAt: installedAt)

    #expect(result.plugin.id == manifest.id)
    #expect(result.plugin.installedVersion == manifest.version)
    #expect(result.version.manifest == manifest)
    #expect(result.verification.sha256 == PluginPackageVerifier.sha256Hex(packageData))
    #expect(FileManager.default.fileExists(atPath: result.plugin.installPath + "/manifest.json"))
    #expect(FileManager.default.fileExists(atPath: result.version.packagePath ?? ""))
    #expect(try store.pluginPermissions(pluginID: manifest.id).map(\.permission) == [.backgroundRefresh, .network])
}

@Test func pluginInstallerRejectsRevokedPackageBeforePersisting() async throws {
    let database = try temporaryDatabase()
    try StatusDatabaseMigrator.migrate(database)
    let store = StatusPersistenceStore(database: database)
    let packageData = Data("plugin package".utf8)
    let manifest = githubManifest()
    let manifestData = try JSONEncoder().encode(manifest)
    let version = RegistryPluginVersion(
        pluginId: manifest.id,
        version: manifest.version,
        minCoreVersion: manifest.minCoreVersion,
        platforms: manifest.platforms,
        packageUrl: try #require(URL(string: "https://status-registry.hakobs.com/package.zip")),
        manifestUrl: try #require(URL(string: "https://status-registry.hakobs.com/manifest.json")),
        sha256: PluginPackageVerifier.sha256Hex(packageData),
        signature: "dev-signature",
        signedBy: "status-foundry-dev",
        releasedAt: Date(timeIntervalSince1970: 1_783_433_520)
    )
    let registry = FakeRegistryMetadataProvider(
        version: version,
        revocations: RegistryRevocationsResponse(
            schemaVersion: "1.0.0",
            generatedAt: Date(timeIntervalSince1970: 1_783_433_520),
            revokedPlugins: [manifest.id],
            revokedVersions: [],
            revokedHashes: [],
            revokedSigningKeys: []
        )
    )
    let transport = FakePackageTransport(responses: [
        version.packageUrl: packageData,
        version.manifestUrl: manifestData
    ])
    let installer = PluginInstaller(
        registry: registry,
        packageTransport: transport,
        store: store,
        installRoot: FileManager.default.temporaryDirectory.appendingPathComponent("status-plugin-installer-\(UUID().uuidString)", isDirectory: true)
    )

    await #expect(throws: PluginPackageVerificationError.revokedPlugin(manifest.id)) {
        try await installer.install(pluginID: manifest.id, version: manifest.version, trustLevel: .official)
    }
    #expect(try store.installedPlugin(id: manifest.id) == nil)
}

private struct FakeRegistryMetadataProvider: PluginRegistryMetadataProvider {
    var version: RegistryPluginVersion
    var revocations: RegistryRevocationsResponse

    func version(pluginID: String, version: String) async throws -> RegistryPluginVersion {
        self.version
    }

    func revocations() async throws -> RegistryRevocationsResponse {
        revocations
    }
}

private struct FakePackageTransport: RegistryHTTPTransport {
    var responses: [URL: Data]

    func data(from url: URL) async throws -> Data {
        guard let response = responses[url] else {
            throw PluginRegistryError.httpStatus(404)
        }
        return response
    }
}

private func githubManifest() -> PluginManifest {
    PluginManifest(
        id: "com.status.github",
        name: "GitHub",
        version: "0.1.0",
        author: "Status Foundry",
        category: "developer",
        description: "Read-only GitHub status events.",
        minCoreVersion: "0.1.0",
        platforms: [.macOS, .iOS],
        permissions: [.network, .backgroundRefresh],
        domains: ["api.github.com"]
    )
}

private func emptyRevocations() -> RegistryRevocationsResponse {
    RegistryRevocationsResponse(
        schemaVersion: "1.0.0",
        generatedAt: Date(timeIntervalSince1970: 1_783_433_520),
        revokedPlugins: [],
        revokedVersions: [],
        revokedHashes: [],
        revokedSigningKeys: []
    )
}

private func temporaryDatabase() throws -> SQLiteDatabase {
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("status-\(UUID().uuidString).sqlite")
        .path
    return try SQLiteDatabase(path: path)
}

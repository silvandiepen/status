import Foundation
import Testing
@testable import StatusCore

@Test func credentialReferenceUsesKeychainReferenceShape() throws {
    let reference = try CredentialReference.make()

    #expect(reference.hasPrefix("kc_"))
    #expect(reference.count == 29)
    try CredentialReference.validate(reference)
}

@Test func invalidCredentialReferencesAreRejected() {
    #expect(throws: CredentialStoreError.invalidReference("token_123")) {
        try CredentialReference.validate("token_123")
    }
}

@Test func inMemoryCredentialStoreRoundTripsAndDeletesSecretsByReference() throws {
    let store = InMemoryCredentialStore()
    let secret = try #require("github_pat_example".data(using: .utf8))

    let reference = try store.store(secret, label: "GitHub token")

    #expect(try store.read(reference: reference) == secret)

    try store.delete(reference: reference)

    #expect(try store.read(reference: reference) == nil)
}

@Test func deletingAccountConfigurationDeletesStoredCredential() throws {
    let database = try temporaryCredentialDatabase()
    try StatusDatabaseMigrator.migrate(database)
    let store = StatusPersistenceStore(database: database)
    let credentials = InMemoryCredentialStore()
    let now = Date(timeIntervalSince1970: 1_783_433_520)
    let manifest = PluginManifest(
        id: "com.status.github",
        name: "GitHub",
        version: "0.1.0",
        author: PluginAuthor(name: "Status Foundry", publisherId: "status-foundry"),
        category: "developer",
        description: "Read-only GitHub status events.",
        minCoreVersion: "0.1.0",
        platforms: [.macOS, .iOS],
        permissions: [.network, .keychain],
        domains: ["api.github.com"]
    )
    try store.installPlugin(
        PluginInstallRecord(
            manifest: manifest,
            trustLevel: .official,
            installPath: "/Application Support/Status/Plugins/com.status.github",
            verification: PluginPackageVerificationResult(
                pluginID: manifest.id,
                version: manifest.version,
                sha256: "abc123",
                signedBy: "status-foundry-dev"
            ),
            installedAt: now
        )
    )
    let credentialRef = try credentials.store(Data("github_pat_example".utf8), label: "GitHub token")
    try store.upsertAccountConfiguration(
        PluginAccountConfiguration(
            id: "acc_work",
            pluginID: manifest.id,
            accountName: "Work GitHub",
            variables: ["owner": "statusfoundry"],
            authType: "bearer-token",
            credentialRef: credentialRef
        ),
        updatedAt: now
    )

    let deletedName = try PluginSetupConfiguration.deleteAccountConfiguration(
        accountID: "acc_work",
        store: store,
        credentialStore: credentials
    )

    #expect(deletedName == "Work GitHub")
    #expect(try store.accountConfiguration(accountID: "acc_work") == nil)
    #expect(try credentials.read(reference: credentialRef) == nil)
}

private func temporaryCredentialDatabase() throws -> SQLiteDatabase {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("status-credentials-\(UUID().uuidString).sqlite")
    return try SQLiteDatabase(path: url.path)
}

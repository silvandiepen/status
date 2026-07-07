import Foundation
import Testing
@testable import StatusCore

@Test func validPluginManifestPassesValidation() throws {
    let manifest = appStoreConnectManifest()
    let request = PluginRequestDefinition(
        id: "list_apps",
        method: "GET",
        url: try #require(URL(string: "https://api.appstoreconnect.apple.com/v1/apps"))
    )

    try PluginManifestValidator.validate(
        PluginValidationInput(manifest: manifest, authKinds: [.jwtAPIKey], requests: [request])
    )
}

@Test func networkPluginMustDeclareRequestedDomains() throws {
    var manifest = appStoreConnectManifest()
    manifest.domains = []

    #expect(throws: PluginValidationError.noDomainForNetworkPermission) {
        try PluginManifestValidator.validate(PluginValidationInput(manifest: manifest))
    }
}

@Test func requestDomainMustBeDeclaredByPlugin() throws {
    let manifest = appStoreConnectManifest()
    let request = PluginRequestDefinition(
        id: "bad_request",
        method: "GET",
        url: try #require(URL(string: "https://example.com/v1/apps"))
    )

    #expect(throws: PluginValidationError.undeclaredRequestDomain("example.com")) {
        try PluginManifestValidator.validate(PluginValidationInput(manifest: manifest, requests: [request]))
    }
}

@Test func writeActionsRequireExplicitPermission() {
    let manifest = appStoreConnectManifest()
    let action = PluginActionDeclaration(
        type: "jira.createIssue",
        label: "Create Jira issue",
        requiresWritePermission: true
    )

    #expect(throws: PluginValidationError.writeActionWithoutPermission("jira.createIssue")) {
        try PluginManifestValidator.validate(PluginValidationInput(manifest: manifest, actions: [action]))
    }
}

@Test func oauthIsRejectedForV1Plugins() {
    let manifest = appStoreConnectManifest()

    #expect(throws: PluginValidationError.unsupportedOAuthInV1) {
        try PluginManifestValidator.validate(PluginValidationInput(manifest: manifest, authKinds: [.oauth2]))
    }
}

private func appStoreConnectManifest() -> PluginManifest {
    PluginManifest(
        id: "com.status.appstoreconnect",
        name: "App Store Connect",
        version: "1.0.0",
        author: "Status",
        category: "Developer",
        description: "Shows app review states, versions, builds, ratings, and direct App Store Connect links.",
        minCoreVersion: "1.0.0",
        platforms: [.macOS, .iOS],
        permissions: [.network, .keychain, .privateKey, .backgroundRefresh],
        domains: ["api.appstoreconnect.apple.com"]
    )
}

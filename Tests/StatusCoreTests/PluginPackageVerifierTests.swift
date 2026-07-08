import CryptoKit
import Foundation
import Testing
@testable import StatusCore

@Test func packageVerifierAcceptsMatchingHashAndSignatureMetadata() throws {
    let data = Data("plugin package".utf8)
    let version = registryVersion(packageData: data)

    let result = try PluginPackageVerifier.verify(
        packageData: data,
        version: version,
        revocations: emptyRevocations()
    )

    #expect(result.pluginID == "com.status.github")
    #expect(result.version == "0.1.0")
    #expect(result.sha256 == PluginPackageVerifier.sha256Hex(data))
    #expect(result.signedBy == "status-foundry-dev")
}

@Test func packageVerifierRejectsInvalidSignature() throws {
    let data = Data("plugin package".utf8)
    let version = registryVersion(packageData: data, signature: Data("invalid".utf8).base64EncodedString())

    #expect(throws: PluginPackageVerificationError.invalidSignature) {
        try PluginPackageVerifier.verify(
            packageData: data,
            version: version,
            revocations: emptyRevocations()
        )
    }
}

@Test func packageVerifierRejectsUnknownSigningKey() throws {
    let data = Data("plugin package".utf8)
    let version = registryVersion(packageData: data, signedBy: "unknown-key")

    #expect(throws: PluginPackageVerificationError.unknownSigningKey("unknown-key")) {
        try PluginPackageVerifier.verify(
            packageData: data,
            version: version,
            revocations: emptyRevocations()
        )
    }
}

@Test func packageVerifierRejectsHashMismatch() throws {
    let data = Data("plugin package".utf8)
    let version = registryVersion(packageData: data, sha256: "bad")

    #expect(throws: PluginPackageVerificationError.hashMismatch(expected: "bad", actual: PluginPackageVerifier.sha256Hex(data))) {
        try PluginPackageVerifier.verify(
            packageData: data,
            version: version,
            revocations: emptyRevocations()
        )
    }
}

@Test func packageVerifierRejectsMissingSignatureMetadata() throws {
    let data = Data("plugin package".utf8)
    let version = registryVersion(packageData: data, includeSignature: false)

    #expect(throws: PluginPackageVerificationError.missingSignature) {
        try PluginPackageVerifier.verify(
            packageData: data,
            version: version,
            revocations: emptyRevocations()
        )
    }
}

@Test func packageVerifierRejectsRevokedVersionHashAndSigningKey() throws {
    let data = Data("plugin package".utf8)
    let version = registryVersion(packageData: data)

    #expect(throws: PluginPackageVerificationError.revokedVersion(pluginID: "com.status.github", version: "0.1.0")) {
        try PluginPackageVerifier.verify(
            packageData: data,
            version: version,
            revocations: RegistryRevocationsResponse(
                schemaVersion: "1.0.0",
                generatedAt: Date(timeIntervalSince1970: 1_783_433_520),
                revokedPlugins: [],
                revokedVersions: [RegistryRevocationsResponse.RevokedVersion(pluginId: "com.status.github", version: "0.1.0")],
                revokedHashes: [],
                revokedSigningKeys: []
            )
        )
    }

    #expect(throws: PluginPackageVerificationError.revokedHash(PluginPackageVerifier.sha256Hex(data))) {
        try PluginPackageVerifier.verify(
            packageData: data,
            version: version,
            revocations: RegistryRevocationsResponse(
                schemaVersion: "1.0.0",
                generatedAt: Date(timeIntervalSince1970: 1_783_433_520),
                revokedPlugins: [],
                revokedVersions: [],
                revokedHashes: [PluginPackageVerifier.sha256Hex(data)],
                revokedSigningKeys: []
            )
        )
    }

    #expect(throws: PluginPackageVerificationError.revokedSigningKey("status-foundry-dev")) {
        try PluginPackageVerifier.verify(
            packageData: data,
            version: version,
            revocations: RegistryRevocationsResponse(
                schemaVersion: "1.0.0",
                generatedAt: Date(timeIntervalSince1970: 1_783_433_520),
                revokedPlugins: [],
                revokedVersions: [],
                revokedHashes: [],
                revokedSigningKeys: ["status-foundry-dev"]
            )
        )
    }
}

private func registryVersion(
    packageData: Data,
    sha256: String? = nil,
    signature: String? = nil,
    includeSignature: Bool = true,
    signedBy: String = "status-foundry-dev"
) -> RegistryPluginVersion {
    RegistryPluginVersion(
        pluginId: "com.status.github",
        version: "0.1.0",
        minCoreVersion: "0.1.0",
        platforms: [.macOS, .iOS],
        packageUrl: URL(string: "https://status-registry.hakobs.com/plugins/com.status.github/0.1.0/com.status.github-0.1.0.statusplugin.zip")!,
        manifestUrl: URL(string: "https://status-registry.hakobs.com/plugins/com.status.github/0.1.0/manifest.json")!,
        sha256: sha256 ?? PluginPackageVerifier.sha256Hex(packageData),
        signature: includeSignature ? (signature ?? signatureBase64(for: packageData)) : nil,
        signedBy: signedBy,
        releasedAt: Date(timeIntervalSince1970: 1_783_433_520)
    )
}

private func signatureBase64(for data: Data) -> String {
    let privateKey = try! Curve25519.Signing.PrivateKey(
        rawRepresentation: Data(base64Encoded: "cxcm0WfrqEan3cwwxBxM6BCrE5cc2y/DSJTDExN2Fpk=")!
    )
    return try! privateKey.signature(for: data).base64EncodedString()
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

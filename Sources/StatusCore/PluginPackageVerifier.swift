import CryptoKit
import Foundation

public struct PluginPackageVerificationResult: Equatable, Sendable {
    public var pluginID: String
    public var version: String
    public var sha256: String
    public var signedBy: String

    public init(pluginID: String, version: String, sha256: String, signedBy: String) {
        self.pluginID = pluginID
        self.version = version
        self.sha256 = sha256
        self.signedBy = signedBy
    }
}

public enum PluginPackageVerificationError: Error, Equatable, LocalizedError, Sendable {
    case missingPluginID
    case missingSignature
    case missingSigner
    case unknownSigningKey(String)
    case invalidSignature
    case hashMismatch(expected: String, actual: String)
    case revokedPlugin(String)
    case revokedVersion(pluginID: String, version: String)
    case revokedHash(String)
    case revokedSigningKey(String)

    public var errorDescription: String? {
        switch self {
        case .missingPluginID:
            "Registry version metadata did not include a plugin id."
        case .missingSignature:
            "Plugin package is missing signature material."
        case .missingSigner:
            "Plugin package is missing signer metadata."
        case .unknownSigningKey(let keyID):
            "Plugin signing key is not trusted: \(keyID)."
        case .invalidSignature:
            "Plugin package signature is invalid."
        case .hashMismatch(let expected, let actual):
            "Plugin package hash mismatch. Expected \(expected), got \(actual)."
        case .revokedPlugin(let pluginID):
            "Plugin is revoked: \(pluginID)."
        case .revokedVersion(let pluginID, let version):
            "Plugin version is revoked: \(pluginID) \(version)."
        case .revokedHash(let hash):
            "Plugin package hash is revoked: \(hash)."
        case .revokedSigningKey(let key):
            "Plugin signing key is revoked: \(key)."
        }
    }
}

public enum PluginPackageVerifier {
    public static func verify(
        packageData: Data,
        version: RegistryPluginVersion,
        revocations: RegistryRevocationsResponse
    ) throws -> PluginPackageVerificationResult {
        guard let pluginID = version.pluginId, pluginID.isEmpty == false else {
            throw PluginPackageVerificationError.missingPluginID
        }
        guard version.signature?.isEmpty == false else {
            throw PluginPackageVerificationError.missingSignature
        }
        guard let signedBy = version.signedBy, signedBy.isEmpty == false else {
            throw PluginPackageVerificationError.missingSigner
        }
        guard let signatureString = version.signature,
              let signature = Data(base64Encoded: signatureString),
              signature.isEmpty == false else {
            throw PluginPackageVerificationError.invalidSignature
        }

        let actualHash = sha256Hex(packageData)
        let expectedHash = version.sha256.lowercased()
        guard actualHash == expectedHash else {
            throw PluginPackageVerificationError.hashMismatch(expected: expectedHash, actual: actualHash)
        }

        if revocations.revokedPlugins.contains(pluginID) {
            throw PluginPackageVerificationError.revokedPlugin(pluginID)
        }
        if revocations.revokedVersions.contains(where: { $0.pluginId == pluginID && $0.version == version.version }) {
            throw PluginPackageVerificationError.revokedVersion(pluginID: pluginID, version: version.version)
        }
        if revocations.revokedHashes.contains(actualHash) {
            throw PluginPackageVerificationError.revokedHash(actualHash)
        }
        if revocations.revokedSigningKeys.contains(signedBy) {
            throw PluginPackageVerificationError.revokedSigningKey(signedBy)
        }
        guard let publicKeyBytes = trustedSigningKeys[signedBy],
              let publicKeyData = Data(base64Encoded: publicKeyBytes) else {
            throw PluginPackageVerificationError.unknownSigningKey(signedBy)
        }
        let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
        guard publicKey.isValidSignature(signature, for: packageData) else {
            throw PluginPackageVerificationError.invalidSignature
        }

        return PluginPackageVerificationResult(
            pluginID: pluginID,
            version: version.version,
            sha256: actualHash,
            signedBy: signedBy
        )
    }

    public static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static let trustedSigningKeys: [String: String] = [
        "status-foundry-dev": "bRCtQVjoAgF5R3LMRy6u9A1QdGiKU5pSDwjAI3acfM4="
    ]
}

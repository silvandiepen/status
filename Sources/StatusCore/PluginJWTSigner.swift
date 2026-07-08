import CryptoKit
import Foundation

public enum PluginJWTSignerError: Error, Equatable, LocalizedError, Sendable {
    case missingCredentialField(String)
    case invalidPrivateKey

    public var errorDescription: String? {
        switch self {
        case .missingCredentialField(let field):
            "JWT credential is missing required field: \(field)"
        case .invalidPrivateKey:
            "JWT credential private key is invalid."
        }
    }
}

public enum PluginJWTSigner {
    public static func appStoreConnectToken(credentials: PluginAuthCredentialBundle, now: Date) throws -> String {
        let issuerID = try required("issuerId", in: credentials)
        let keyID = try required("keyId", in: credentials)
        let privateKeyPEM = try required("privateKey", in: credentials)
        let privateKey: P256.Signing.PrivateKey
        do {
            privateKey = try P256.Signing.PrivateKey(pemRepresentation: privateKeyPEM)
        } catch {
            throw PluginJWTSignerError.invalidPrivateKey
        }

        let header = [
            "alg": "ES256",
            "kid": keyID,
            "typ": "JWT"
        ]
        let issuedAt = Int(now.timeIntervalSince1970)
        let payload: [String: PluginJWTValue] = [
            "aud": .string("appstoreconnect-v1"),
            "exp": .integer(issuedAt + 1_199),
            "iat": .integer(issuedAt),
            "iss": .string(issuerID)
        ]
        let signingInput = try "\(base64URLJSON(header)).\(base64URLJSON(payload))"
        let signature = try privateKey.signature(for: Data(signingInput.utf8))
        return "\(signingInput).\(base64URL(signature.rawRepresentation))"
    }

    private static func required(_ key: String, in credentials: PluginAuthCredentialBundle) throws -> String {
        guard let value = credentials.fields[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              value.isEmpty == false else {
            throw PluginJWTSignerError.missingCredentialField(key)
        }
        return value
    }

    private static func base64URLJSON<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return base64URL(try encoder.encode(value))
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private enum PluginJWTValue: Encodable, Equatable {
    case string(String)
    case integer(Int)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        }
    }
}

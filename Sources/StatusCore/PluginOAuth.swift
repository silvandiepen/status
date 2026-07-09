import CryptoKit
import Foundation
import Security

public struct PluginOAuthTokenSet: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var tokenType: String
    public var scope: String?
    public var expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case tokenType
        case scope
        case expiresAt
    }

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        tokenType: String = "Bearer",
        scope: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.scope = scope
        self.expiresAt = expiresAt
    }

    public var authorizationHeader: String? {
        let trimmed = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return nil
        }
        let normalizedType = tokenType.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Bearer"
        return "\(normalizedType) \(trimmed)"
    }

    public func needsRefresh(at date: Date, leeway: TimeInterval = 60) -> Bool {
        guard let expiresAt else {
            return false
        }
        return expiresAt <= date.addingTimeInterval(leeway)
    }
}

public struct PluginOAuthAuthorizationRequest: Equatable, Sendable {
    public var url: URL
    public var codeVerifier: String
    public var state: String

    public init(url: URL, codeVerifier: String, state: String) {
        self.url = url
        self.codeVerifier = codeVerifier
        self.state = state
    }
}

public struct PluginOAuthTokenResponse: Codable, Equatable, Sendable {
    public var accessToken: String?
    public var refreshToken: String?
    public var tokenType: String?
    public var scope: String?
    public var expiresIn: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
    }

    public init(
        accessToken: String? = nil,
        refreshToken: String? = nil,
        tokenType: String? = nil,
        scope: String? = nil,
        expiresIn: TimeInterval? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.scope = scope
        self.expiresIn = expiresIn
    }
}

public enum PluginOAuthError: Error, Equatable, LocalizedError, Sendable {
    case missingOAuthConfiguration(String)
    case invalidAuthorizationURL(String)
    case missingApplicationID(String)
    case missingRefreshToken(String)
    case tokenRefreshFailed(statusCode: Int)
    case invalidTokenResponse

    public var errorDescription: String? {
        switch self {
        case .missingOAuthConfiguration(let pluginID):
            "Plugin does not declare OAuth configuration: \(pluginID)"
        case .invalidAuthorizationURL(let url):
            "OAuth authorization URL is invalid: \(url)"
        case .missingApplicationID(let pluginID):
            "OAuth plugin is missing a public application ID: \(pluginID)"
        case .missingRefreshToken(let pluginID):
            "OAuth token is expired and no refresh token is available: \(pluginID)"
        case .tokenRefreshFailed(let statusCode):
            "OAuth token refresh failed with HTTP \(statusCode)."
        case .invalidTokenResponse:
            "OAuth token response did not include an access token."
        }
    }
}

public enum PluginOAuth {
    public static func authorizationRequest(
        pluginID: String,
        auth: PackagedPluginAuth,
        state: String = randomURLSafeString(byteCount: 18),
        codeVerifier: String = randomURLSafeString(byteCount: 32)
    ) throws -> PluginOAuthAuthorizationRequest {
        guard auth.type == .oauth2, let config = auth.oauth2 else {
            throw PluginOAuthError.missingOAuthConfiguration(pluginID)
        }
        guard let clientID = auth.applicationId?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty else {
            throw PluginOAuthError.missingApplicationID(pluginID)
        }
        guard var components = URLComponents(url: config.authorizationURL, resolvingAgainstBaseURL: false) else {
            throw PluginOAuthError.invalidAuthorizationURL(config.authorizationURL.absoluteString)
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "response_type", value: "code"))
        queryItems.append(URLQueryItem(name: "client_id", value: clientID))
        queryItems.append(URLQueryItem(name: "redirect_uri", value: config.redirectURI))
        queryItems.append(URLQueryItem(name: "state", value: state))
        queryItems.append(URLQueryItem(name: "code_challenge", value: codeChallenge(for: codeVerifier)))
        queryItems.append(URLQueryItem(name: "code_challenge_method", value: "S256"))
        if config.scopes.isEmpty == false {
            queryItems.append(URLQueryItem(name: "scope", value: config.scopes.joined(separator: " ")))
        }
        for (name, value) in config.additionalAuthorizationParameters.sorted(by: { $0.key < $1.key }) {
            queryItems.append(URLQueryItem(name: name, value: value))
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw PluginOAuthError.invalidAuthorizationURL(config.authorizationURL.absoluteString)
        }
        return PluginOAuthAuthorizationRequest(url: url, codeVerifier: codeVerifier, state: state)
    }

    public static func codeChallenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    public static func randomURLSafeString(byteCount: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Service for managing keyless authentication (browser auth and workload identity federation)
public class KeylessAuthService {
    private let platformURL = "https://console.anthropic.com"
    private var authToken: String?
    private var issuer: String?

    public init() {}

    // MARK: - Browser Authentication

    /// Initiates browser-based authentication flow for CLI
    /// Returns an authorization code that can be exchanged for an access token
    public func initiateBrowserAuth(clientId: String = "friendly-outlaw-cli") async throws -> BrowserAuthSession {
        let authUrl = "\(platformURL)/oauth/authorize"
        let state = UUID().uuidString
        let nonce = UUID().uuidString

        let queryParams = [
            "client_id": clientId,
            "response_type": "code",
            "redirect_uri": "http://localhost:8080/callback",
            "scope": "openid profile email offline_access",
            "state": state,
            "nonce": nonce
        ]

        let queryString = queryParams
            .map { "\($0.key)=\(($0.value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        let session = BrowserAuthSession(
            authorizationUrl: "\(authUrl)?\(queryString)",
            state: state,
            nonce: nonce,
            clientId: clientId
        )

        return session
    }

    /// Exchanges authorization code for access token
    public func exchangeCodeForToken(
        code: String,
        clientId: String,
        clientSecret: String
    ) async throws -> BrowserAuthToken {
        let tokenUrl = URL(string: "\(platformURL)/oauth/token")!
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": "http://localhost:8080/callback",
            "client_id": clientId,
            "client_secret": clientSecret
        ]

        let bodyString = body
            .map { "\($0.key)=\(($0.value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw KeylessAuthError.tokenExchangeFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let tokenResponse = try decoder.decode(BrowserAuthToken.self, from: data)

        self.authToken = tokenResponse.accessToken
        return tokenResponse
    }

    /// Refreshes an expired access token
    public func refreshToken(
        refreshToken: String,
        clientId: String,
        clientSecret: String
    ) async throws -> BrowserAuthToken {
        let tokenUrl = URL(string: "\(platformURL)/oauth/token")!
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientId,
            "client_secret": clientSecret
        ]

        let bodyString = body
            .map { "\($0.key)=\(($0.value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw KeylessAuthError.tokenRefreshFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let tokenResponse = try decoder.decode(BrowserAuthToken.self, from: data)

        self.authToken = tokenResponse.accessToken
        return tokenResponse
    }

    // MARK: - Workload Identity Federation

    /// Exchanges workload identity token (from cloud provider) for Anthropic access token
    public func exchangeWorkloadIdentity(
        subjectToken: String,
        issuer: String,
        audience: String? = nil,
        config: WorkloadIdentityConfig
    ) async throws -> WorkloadIdentityToken {
        let tokenUrl = URL(string: config.tokenEndpoint)!
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
            "subject_token": subjectToken,
            "subject_token_type": config.subjectTokenType,
            "audience": audience ?? config.audience ?? ""
        ]

        let bodyString = body
            .filter { !$0.value.isEmpty }
            .map { "\($0.key)=\(($0.value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw KeylessAuthError.workloadIdentityExchangeFailed
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let tokenResponse = try decoder.decode(WorkloadIdentityToken.self, from: data)

        self.authToken = tokenResponse.accessToken
        self.issuer = issuer
        return tokenResponse
    }

    // MARK: - Token Management

    /// Gets the current authentication token
    public func getCurrentToken() -> String? {
        return authToken
    }

    /// Gets the current issuer for workload identity
    public func getCurrentIssuer() -> String? {
        return issuer
    }

    /// Clears stored authentication token
    public func clearToken() {
        authToken = nil
        issuer = nil
    }
}

// MARK: - Models

/// Response from browser authentication initiation
public struct BrowserAuthSession: Codable {
    public let authorizationUrl: String
    public let state: String
    public let nonce: String
    public let clientId: String
}

/// Browser authentication token response
public struct BrowserAuthToken: Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: Int?
    public let tokenType: String
    public let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }
}

/// Workload identity token response
public struct WorkloadIdentityToken: Codable {
    public let accessToken: String
    public let expiresIn: Int?
    public let tokenType: String
    public let issuedTokenType: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case issuedTokenType = "issued_token_type"
    }
}

/// Errors for keyless authentication
public enum KeylessAuthError: LocalizedError {
    case tokenExchangeFailed
    case tokenRefreshFailed
    case workloadIdentityExchangeFailed
    case invalidAuthorizationCode
    case authenticationCancelled
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for access token"
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        case .workloadIdentityExchangeFailed:
            return "Failed to exchange workload identity token"
        case .invalidAuthorizationCode:
            return "Invalid or expired authorization code"
        case .authenticationCancelled:
            return "Authentication was cancelled by the user"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

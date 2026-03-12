import Foundation

// MARK: - Canvas Model

/// Represents a canvas created on gui.new
public struct GuiCanvas: Codable {
    public let id: String
    public let url: String
    public let editToken: String
    public let expiresAt: String
    public let title: String?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case editToken
        case expiresAt
        case title
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        editToken = try c.decode(String.self, forKey: .editToken)
        expiresAt = try c.decode(String.self, forKey: .expiresAt)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        // url may be absent; fall back to a URL derived from the configured base URL
        if let u = try c.decodeIfPresent(String.self, forKey: .url) {
            url = u
        } else {
            let environment = ProcessInfo.processInfo.environment
            if let configuredBase = environment["GUI_NEW_URL"], !configuredBase.isEmpty {
                let normalizedBase: String
                if configuredBase.hasSuffix("/") {
                    normalizedBase = String(configuredBase.dropLast())
                } else {
                    normalizedBase = configuredBase
                }
                url = "\(normalizedBase)/\(id)"
            } else {
                url = "https://gui.new/\(id)"
            }
        }
    }
}

// MARK: - Error Types

public enum GuiNewError: LocalizedError {
    case invalidURL
    case encodingFailed
    case decodingFailed
    case httpError(statusCode: Int, body: String)
    case notConfigured
    case documentNotFound
    case boardNotFound

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid gui.new API URL."
        case .encodingFailed:
            return "Failed to encode request body for gui.new."
        case .decodingFailed:
            return "Failed to decode response from gui.new."
        case .httpError(let code, let body):
            return "gui.new API returned HTTP \(code): \(body)"
        case .notConfigured:
            return "GuiNewService is not configured. Make sure the gui.new client is enabled (for example by calling enableGui()). You can optionally provide an API key or set GUI_NEW_API_KEY for Pro features."
        case .documentNotFound:
            return "The requested document was not found."
        case .boardNotFound:
            return "The requested Kanban board was not found."
        }
    }
}

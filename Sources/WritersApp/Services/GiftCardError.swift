import Foundation

public enum GiftCardError: Error, LocalizedError, Equatable {
    case invalidCode
    case bundleExpired
    case alreadyRedeemed
    case bundleNotFound
    case invalidInput(String)
    case databaseError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "Gift card code is invalid or not found"
        case .bundleExpired:
            return "Gift card bundle has expired"
        case .alreadyRedeemed:
            return "Gift card has already been redeemed"
        case .bundleNotFound:
            return "Bundle associated with this gift card was not found"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidCode:
            return "Please check the gift card code and try again"
        case .bundleExpired:
            return "This gift card bundle has expired and can no longer be redeemed"
        case .alreadyRedeemed:
            return "This gift card has already been redeemed"
        case .bundleNotFound:
            return "The bundle associated with this gift card no longer exists"
        case .invalidInput:
            return "Please provide valid input"
        case .databaseError:
            return "Please try again later"
        }
    }
}

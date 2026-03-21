import Foundation

// MARK: - FakechatChannel

/// A localhost demo channel that simulates message push without any external service.
/// Useful for testing the channel pipeline before connecting a real platform like
/// Telegram or Discord.
///
/// Usage:
/// ```swift
/// let fakechat = FakechatChannel()
/// channelManager.register(channel: fakechat)
/// try await channelManager.start(channelId: fakechat.id)
///
/// // Simulate an inbound message (as if a user typed in the browser UI):
/// fakechat.simulateIncomingMessage("what's in my working directory?")
/// ```
public class FakechatChannel: Channel {

    // MARK: - Channel Protocol

    public let id = "fakechat"
    public let name = "Fakechat (demo)"
    public let platform: ChannelPlatform = .fakechat
    public private(set) var isActive: Bool = false
    public var allowlist: SenderAllowlist = SenderAllowlist(policy: .allowAll)
    public weak var delegate: ChannelDelegate?

    // MARK: - Internal State

    /// All replies sent through this channel (for inspection in tests / the demo UI)
    public private(set) var sentReplies: [ChannelReply] = []

    /// All events delivered to the session
    public private(set) var receivedEvents: [ChannelEvent] = []

    private var pendingPairingRequests: [String: ChannelPairingRequest] = [:]
    private let lock = NSLock()

    // MARK: - Lifecycle

    public init() {}

    public func start() async throws {
        lock.lock()
        defer { lock.unlock() }
        isActive = true
    }

    public func stop() async {
        lock.lock()
        defer { lock.unlock() }
        isActive = false
    }

    // MARK: - Messaging

    /// Simulate an inbound message from a browser user (the demo "user").
    /// This creates a `ChannelEvent` and delivers it to the delegate, exactly as a
    /// real channel plugin would.
    @discardableResult
    public func simulateIncomingMessage(
        _ text: String,
        senderId: String = "fakechat-user",
        senderName: String = "Demo User"
    ) -> ChannelEvent {
        let sender = ChannelSender(id: senderId, displayName: senderName, platform: .fakechat)
        let event = ChannelEvent(
            channelId: id,
            sender: sender,
            message: ChannelMessage(text: text)
        )

        lock.lock()
        receivedEvents.append(event)
        lock.unlock()

        delegate?.channel(self, didReceive: event)
        return event
    }

    public func send(reply: ChannelReply) async throws {
        lock.lock()
        let active = isActive
        lock.unlock()
        guard active else {
            throw ChannelError.channelNotEnabled(id)
        }
        lock.lock()
        sentReplies.append(reply)
        lock.unlock()
    }

    // MARK: - Pairing

    public func generatePairingCode(for sender: ChannelSender) -> ChannelPairingRequest {
        let request = ChannelPairingRequest(sender: sender, channelId: id)
        lock.lock()
        pendingPairingRequests[request.code] = request
        lock.unlock()
        return request
    }

    public func approvePairing(code: String) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let request = pendingPairingRequests[code] else {
            throw ChannelError.pairingCodeNotFound
        }
        guard !request.isExpired else {
            pendingPairingRequests.removeValue(forKey: code)
            throw ChannelError.pairingCodeExpired
        }

        allowlist.add(senderId: request.sender.id)
        pendingPairingRequests.removeValue(forKey: code)
    }

    // MARK: - Convenience

    /// Last reply sent through this channel, for easy assertion in tests
    public var lastReply: ChannelReply? {
        lock.lock()
        defer { lock.unlock() }
        return sentReplies.last
    }

    /// Clear recorded replies and events (useful between test cases)
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        sentReplies.removeAll()
        receivedEvents.removeAll()
        pendingPairingRequests.removeAll()
    }
}

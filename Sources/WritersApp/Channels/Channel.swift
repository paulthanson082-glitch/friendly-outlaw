import Foundation

// MARK: - Channel Protocol

/// A channel is an MCP-like server that pushes events into the running session.
/// Channels extend the Plugin system with bidirectional messaging.
public protocol Channel: AnyObject {
    /// Unique identifier for this channel (e.g. "telegram", "fakechat")
    var id: String { get }

    /// Human-readable name
    var name: String { get }

    /// The platform this channel bridges to
    var platform: ChannelPlatform { get }

    /// Whether the channel is currently active
    var isActive: Bool { get }

    /// Sender allowlist controlling who can push events
    var allowlist: SenderAllowlist { get set }

    /// Delegate that receives incoming events
    var delegate: ChannelDelegate? { get set }

    /// Start the channel (begin listening for events)
    func start() async throws

    /// Stop the channel (stop listening for events)
    func stop() async

    /// Send a reply back through the channel
    func send(reply: ChannelReply) async throws

    /// Generate a pairing code for the given sender
    func generatePairingCode(for sender: ChannelSender) -> ChannelPairingRequest

    /// Approve a pairing request by code, adding the sender to the allowlist.
    /// Throws `ChannelError.pairingCodeNotFound` or `ChannelError.pairingCodeExpired` on failure.
    func approvePairing(code: String) throws
}

// MARK: - Channel Delegate

/// Receives incoming channel events so they can be handled by the session
public protocol ChannelDelegate: AnyObject {
    /// Called when a new event arrives from the channel.
    /// Implementations should check the allowlist and route accordingly.
    func channel(_ channel: Channel, didReceive event: ChannelEvent)

    /// Called when a channel encounters an error
    func channel(_ channel: Channel, didEncounterError error: Error)
}

// MARK: - Channel Manager

/// Manages active channels for the current session.
/// Channels must be explicitly registered and started to receive events.
public class ChannelManager {

    // MARK: - Properties

    private var channels: [String: Channel] = [:]
    private let queue = DispatchQueue(label: "com.writersapp.channels", attributes: .concurrent)

    /// Delegate to route all incoming events to
    public weak var delegate: ChannelManagerDelegate?

    /// Event handlers registered for specific channels (channelId → handler)
    private var eventHandlers: [String: (ChannelEvent) async -> String?] = [:]

    public init() {}

    // MARK: - Channel Registration

    /// Register a channel. Does not start it.
    public func register(channel: Channel) {
        // Assign delegate synchronously before writing to the dictionary so
        // that any subsequent start() call on the same thread sees the delegate set.
        channel.delegate = self
        queue.sync(flags: .barrier) {
            self.channels[channel.id] = channel
        }
    }

    /// Unregister and stop a channel
    public func unregister(channelId: String) async {
        var ch: Channel?
        queue.sync { ch = channels[channelId] }
        if let channel = ch {
            await channel.stop()
            queue.async(flags: .barrier) { self.channels.removeValue(forKey: channelId) }
        }
    }

    /// Get a registered channel by id
    public func channel(id: String) -> Channel? {
        queue.sync { channels[id] }
    }

    /// All registered channels
    public func allChannels() -> [Channel] {
        queue.sync { Array(channels.values) }
    }

    /// All active (started) channels
    public func activeChannels() -> [Channel] {
        queue.sync { channels.values.filter { $0.isActive } }
    }

    // MARK: - Lifecycle

    /// Start a channel by id
    public func start(channelId: String) async throws {
        guard let channel = channel(id: channelId) else {
            throw ChannelError.channelNotFound(channelId)
        }
        try await channel.start()
        delegate?.channelManager(self, didStart: channel)
    }

    /// Stop a channel by id
    public func stop(channelId: String) async throws {
        guard let channel = channel(id: channelId) else {
            throw ChannelError.channelNotFound(channelId)
        }
        await channel.stop()
        delegate?.channelManager(self, didStop: channel)
    }

    /// Stop all channels
    public func stopAll() async {
        let all = allChannels()
        for channel in all {
            await channel.stop()
        }
    }

    // MARK: - Allowlist Management

    /// Set allowlist policy for a channel
    public func setPolicy(_ policy: AllowlistPolicy, channelId: String) throws {
        guard let channel = channel(id: channelId) else {
            throw ChannelError.channelNotFound(channelId)
        }
        channel.allowlist.policy = policy
    }

    /// Add a sender to a channel's allowlist
    public func addToAllowlist(senderId: String, channelId: String) throws {
        guard let channel = channel(id: channelId) else {
            throw ChannelError.channelNotFound(channelId)
        }
        channel.allowlist.add(senderId: senderId)
    }

    /// Remove a sender from a channel's allowlist
    public func removeFromAllowlist(senderId: String, channelId: String) throws {
        guard let channel = channel(id: channelId) else {
            throw ChannelError.channelNotFound(channelId)
        }
        channel.allowlist.remove(senderId: senderId)
    }

    /// Generate a pairing code for a sender on a given channel.
    /// The code should be shown to the sender who then uses it to pair.
    public func generatePairingCode(for sender: ChannelSender, channelId: String) throws -> ChannelPairingRequest {
        guard let channel = channel(id: channelId) else {
            throw ChannelError.channelNotFound(channelId)
        }
        return channel.generatePairingCode(for: sender)
    }

    /// Approve a pairing request: validates the code and adds the sender to the allowlist
    public func approvePairing(code: String, channelId: String) throws {
        guard let channel = channel(id: channelId) else {
            throw ChannelError.channelNotFound(channelId)
        }
        try channel.approvePairing(code: code)
    }

    // MARK: - Event Handling

    /// Register an async handler for events arriving on a specific channel.
    /// The handler receives the event and returns an optional reply string.
    public func onEvent(channelId: String, handler: @escaping (ChannelEvent) async -> String?) {
        queue.async(flags: .barrier) {
            self.eventHandlers[channelId] = handler
        }
    }

    /// Send a reply through a channel
    public func send(reply: ChannelReply) async throws {
        guard let channel = channel(id: reply.channelId) else {
            throw ChannelError.channelNotFound(reply.channelId)
        }
        guard channel.isActive else {
            throw ChannelError.channelNotEnabled(reply.channelId)
        }
        try await channel.send(reply: reply)
    }
}

// MARK: - ChannelDelegate conformance

extension ChannelManager: ChannelDelegate {
    public func channel(_ channel: Channel, didReceive event: ChannelEvent) {
        guard channel.allowlist.allows(sender: event.sender) else { return }

        delegate?.channelManager(self, didReceive: event)

        // Call any registered handler
        let handler = queue.sync { eventHandlers[channel.id] }
        guard let handler = handler else { return }

        Task {
            if let replyText = await handler(event) {
                let reply = ChannelReply(
                    eventId: event.id,
                    channelId: channel.id,
                    text: replyText
                )
                try? await channel.send(reply: reply)
            }
        }
    }

    public func channel(_ channel: Channel, didEncounterError error: Error) {
        delegate?.channelManager(self, didEncounterError: error, in: channel)
    }
}

// MARK: - Channel Manager Delegate

/// Receives events and lifecycle callbacks from ChannelManager
public protocol ChannelManagerDelegate: AnyObject {
    func channelManager(_ manager: ChannelManager, didReceive event: ChannelEvent)
    func channelManager(_ manager: ChannelManager, didStart channel: Channel)
    func channelManager(_ manager: ChannelManager, didStop channel: Channel)
    func channelManager(_ manager: ChannelManager, didEncounterError error: Error, in channel: Channel)
}

public extension ChannelManagerDelegate {
    func channelManager(_ manager: ChannelManager, didStart channel: Channel) {}
    func channelManager(_ manager: ChannelManager, didStop channel: Channel) {}
    func channelManager(_ manager: ChannelManager, didEncounterError error: Error, in channel: Channel) {}
}

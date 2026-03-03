import Foundation

// MARK: - Tmux Agent Service

/// Service for managing inter-agent communication via tmux panes
public class TmuxAgentService {
    private let configuration: TmuxConfiguration
    private var sessions: [String: AgentSession] = [:]
    private var pendingResponses: [UUID: CheckedContinuation<String, Error>] = [:]
    private let lock = NSLock()
    private var isInitialized = false

    public init(configuration: TmuxConfiguration = TmuxConfiguration()) {
        self.configuration = configuration
    }

    // MARK: - Initialization

    /// Initialize the tmux agent service
    public func initialize() async throws {
        lock.lock()
        defer { lock.unlock() }

        // Check if tmux is available
        do {
            _ = try executeShellCommand("which tmux > /dev/null 2>&1 && tmux -V")
            isInitialized = true
        } catch {
            throw TmuxAgentError.tmuxNotAvailable
        }
    }

    // MARK: - Session Management

    /// Register a new agent with a tmux pane target
    public func registerAgent(
        agentId: String,
        paneTarget: String
    ) async throws -> AgentSession {
        lock.lock()
        defer { lock.unlock() }

        guard isInitialized else {
            throw TmuxAgentError.notInitialized
        }

        // Validate pane format
        _ = try validatePaneFormat(paneTarget)

        // Check if agent already registered
        if sessions[agentId] != nil {
            throw TmuxAgentError.sendKeysFailed("Agent '\(agentId)' already registered")
        }

        let session = AgentSession(
            agentId: agentId,
            paneTarget: paneTarget
        )

        sessions[agentId] = session
        return session
    }

    /// Unregister an agent
    public func unregisterAgent(agentId: String) async throws {
        lock.lock()
        defer { lock.unlock() }

        sessions.removeValue(forKey: agentId)
    }

    /// Get a session by agent ID
    public func getSession(agentId: String) -> AgentSession? {
        lock.lock()
        defer { lock.unlock() }

        return sessions[agentId]
    }

    /// Get all active sessions
    public func getAllSessions() -> [AgentSession] {
        lock.lock()
        defer { lock.unlock() }

        return Array(sessions.values)
    }

    // MARK: - Message Operations

    /// Send a message to another agent via tmux
    public func sendMessage(
        message: AgentMessage,
        awaitResponse: Bool = false,
        timeoutSeconds: Int = 30
    ) async throws -> AgentResponse {
        lock.lock()
        guard let targetSession = sessions[message.toAgentId] else {
            lock.unlock()
            throw TmuxAgentError.paneNotFound(message.toAgentId)
        }
        let paneTarget = targetSession.paneTarget
        lock.unlock()

        // Send the keystroke sequence
        try await sendKeystrokeSequence(
            toPane: paneTarget,
            message: message.content,
            retries: configuration.writeRetries
        )

        // Update session activity
        lock.lock()
        if var session = sessions[message.toAgentId] {
            session.lastActivity = Date()
            session.messageCount += 1
            sessions[message.toAgentId] = session
        }
        lock.unlock()

        if awaitResponse {
            do {
                let content = try await withTimeout(
                    seconds: timeoutSeconds,
                    operation: {
                        try await captureOutputWithRetry(fromPane: paneTarget)
                    }
                )
                return AgentResponse(
                    messageId: message.id,
                    status: .processed,
                    content: content
                )
            } catch {
                if error is TmuxAgentError {
                    throw error
                }
                return AgentResponse(
                    messageId: message.id,
                    status: .timeout,
                    error: "Response timeout after \(timeoutSeconds)s"
                )
            }
        }

        return AgentResponse(
            messageId: message.id,
            status: .received
        )
    }

    /// Receive a message from another agent
    public func receiveMessage(
        fromAgentId: String,
        timeoutSeconds: Int = 30
    ) async throws -> AgentMessage? {
        lock.lock()
        guard let session = sessions[fromAgentId] else {
            lock.unlock()
            throw TmuxAgentError.paneNotFound(fromAgentId)
        }
        let paneTarget = session.paneTarget
        lock.unlock()

        do {
            let output = try await withTimeout(
                seconds: timeoutSeconds,
                operation: {
                    try await captureOutputWithRetry(fromPane: paneTarget)
                }
            )

            // Parse message from captured output
            // For now, treat captured output as message content
            let message = AgentMessage(
                fromAgentId: fromAgentId,
                toAgentId: "self",  // Receiving agent
                content: output
            )

            return message
        } catch {
            if error is TmuxAgentError {
                throw error
            }
            return nil
        }
    }

    // MARK: - Private Methods

    /// Validate tmux pane format
    private func validatePaneFormat(_ pane: String) throws -> (window: String, pane: String) {
        if pane.contains(":") {
            let parts = pane.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else {
                throw TmuxAgentError.invalidPaneFormat(pane)
            }
            return (String(parts[0]), String(parts[1]))
        } else if Int(pane) != nil {
            return (configuration.windowIndex.description, pane)
        } else {
            throw TmuxAgentError.invalidPaneFormat(pane)
        }
    }

    /// Send a reliable keystroke sequence to tmux pane
    private func sendKeystrokeSequence(
        toPane: String,
        message: String,
        retries: Int = 3
    ) async throws {
        var lastError: Error?

        for attempt in 0..<retries {
            do {
                // Enter insert mode
                try tmuxSendKeys(toPane: toPane, keys: "i")
                try await sleepMs(configuration.keystrokeDelay)

                // Send message
                try tmuxSendKeys(toPane: toPane, keys: message)
                try await sleepMs(configuration.keystrokeDelay)

                // Exit insert mode
                try tmuxSendKeys(toPane: toPane, keys: "Escape")
                try await sleepMs(configuration.keystrokeDelay)

                // Submit
                try tmuxSendKeys(toPane: toPane, keys: "Enter")

                return  // Success
            } catch {
                lastError = error
                if attempt < retries - 1 {
                    try await sleepMs(500 * (attempt + 1))  // Exponential backoff
                }
            }
        }

        if let error = lastError {
            throw error
        }
        throw TmuxAgentError.sendKeysFailed("Unknown error after \(retries) retries")
    }

    /// Send keys to a tmux pane
    private func tmuxSendKeys(toPane: String, keys: String) throws {
        let command = "tmux send-keys -t \(toPane) '\(escapeSingleQuotes(keys))'"
        _ = try executeShellCommand(command)
    }

    /// Capture output from a tmux pane
    private func tmuxCapturePane(fromPane: String) throws -> String {
        let command = "tmux capture-pane -t \(fromPane) -p"
        return try executeShellCommand(command)
    }

    /// Capture output with retry logic
    private func captureOutputWithRetry(fromPane: String) async throws -> String {
        for attempt in 0..<3 {
            do {
                let output = try tmuxCapturePane(fromPane: fromPane)
                if !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return output
                }
            } catch {
                if attempt == 2 {
                    throw TmuxAgentError.captureOutputFailed("Unable to capture output after 3 attempts")
                }
            }
            try await sleepMs(100)
        }
        return ""
    }

    /// Execute a shell command
    private func executeShellCommand(_ command: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            if process.terminationStatus != 0 {
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                throw TmuxAgentError.sendKeysFailed(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
            }

            return String(data: outputData, encoding: .utf8) ?? ""
        } catch let error as TmuxAgentError {
            throw error
        } catch {
            throw TmuxAgentError.sendKeysFailed(error.localizedDescription)
        }
    }

    /// Escape single quotes in a string for shell safety
    private func escapeSingleQuotes(_ string: String) -> String {
        return string.replacingOccurrences(of: "'", with: "'\"'\"'")
    }

    /// Sleep for milliseconds
    private func sleepMs(_ milliseconds: Int) async throws {
        try await Task.sleep(nanoseconds: UInt64(milliseconds) * 1_000_000)
    }

    /// Wait for an operation with timeout
    private func withTimeout<T>(
        seconds: Int,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await sleepMs(seconds * 1000)
                throw TmuxAgentError.responseTimeout("Timeout after \(seconds) seconds")
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

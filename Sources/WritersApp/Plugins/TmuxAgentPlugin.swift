import Foundation

// MARK: - Tmux Agent Plugin

/// Plugin for managing inter-agent communication via tmux panes
public class TmuxAgentPlugin: Plugin {
    public let id: String = "tmux-agent"
    public let name: String = "Tmux Agent Communication"
    public let version: String = "1.0.0"
    public let description: String = "Enable inter-agent communication via tmux panes"
    public var isEnabled: Bool = true
    public let capabilities: [PluginCapability] = [.customActions, .tools]

    private var service: TmuxAgentService?
    private var isInitialized = false

    public init() {}

    // MARK: - Plugin Lifecycle

    public func initialize() async throws {
        service = TmuxAgentService()
        try await service?.initialize()
        isInitialized = true
    }

    public func shutdown() async throws {
        if let service = service {
            for session in service.getAllSessions() {
                try? await service.unregisterAgent(agentId: session.agentId)
            }
        }
        service = nil
        isInitialized = false
    }

    // MARK: - Plugin Action Execution

    public func execute(action: PluginAction) async throws -> PluginResult {
        guard isInitialized, let service = service else {
            throw PluginError.notInitialized
        }

        switch action.type {
        case .custom:
            return try await handleCustomAction(action: action, service: service)
        default:
            throw PluginError.actionNotSupported(action.type.rawValue)
        }
    }

    // MARK: - Custom Action Handlers

    private func handleCustomAction(
        action: PluginAction,
        service: TmuxAgentService
    ) async throws -> PluginResult {
        guard let actionName = action.parameters["action"] as? String else {
            throw PluginError.invalidParameters("Missing 'action' parameter")
        }

        switch actionName {
        case "register_agent":
            return try await registerAgentAction(action: action, service: service)
        case "unregister_agent":
            return try await unregisterAgentAction(action: action, service: service)
        case "send_message":
            return try await sendMessageAction(action: action, service: service)
        case "receive_message":
            return try await receiveMessageAction(action: action, service: service)
        case "get_sessions":
            return getSessionsAction(service: service)
        case "get_session":
            return getSessionAction(action: action, service: service)
        default:
            throw PluginError.actionNotSupported(actionName)
        }
    }

    private func registerAgentAction(
        action: PluginAction,
        service: TmuxAgentService
    ) async throws -> PluginResult {
        guard let agentId = action.parameters["agent_id"] as? String,
              let paneTarget = action.parameters["pane_target"] as? String else {
            throw PluginError.invalidParameters("Missing agent_id or pane_target")
        }

        let session = try await service.registerAgent(
            agentId: agentId,
            paneTarget: paneTarget
        )

        return .success(data: session)
    }

    private func unregisterAgentAction(
        action: PluginAction,
        service: TmuxAgentService
    ) async throws -> PluginResult {
        guard let agentId = action.parameters["agent_id"] as? String else {
            throw PluginError.invalidParameters("Missing agent_id")
        }

        try await service.unregisterAgent(agentId: agentId)
        return .success()
    }

    private func sendMessageAction(
        action: PluginAction,
        service: TmuxAgentService
    ) async throws -> PluginResult {
        guard let fromAgentId = action.parameters["from_agent_id"] as? String,
              let toAgentId = action.parameters["to_agent_id"] as? String,
              let content = action.parameters["content"] as? String else {
            throw PluginError.invalidParameters("Missing from_agent_id, to_agent_id, or content")
        }

        let awaitResponse = (action.parameters["await_response"] as? Bool) ?? false
        let timeoutSeconds = (action.parameters["timeout_seconds"] as? Int) ?? 30

        let message = AgentMessage(
            fromAgentId: fromAgentId,
            toAgentId: toAgentId,
            content: content
        )

        let response = try await service.sendMessage(
            message: message,
            awaitResponse: awaitResponse,
            timeoutSeconds: timeoutSeconds
        )

        return .success(data: response)
    }

    private func receiveMessageAction(
        action: PluginAction,
        service: TmuxAgentService
    ) async throws -> PluginResult {
        guard let fromAgentId = action.parameters["from_agent_id"] as? String else {
            throw PluginError.invalidParameters("Missing from_agent_id")
        }

        let timeoutSeconds = (action.parameters["timeout_seconds"] as? Int) ?? 30

        let message = try await service.receiveMessage(
            fromAgentId: fromAgentId,
            timeoutSeconds: timeoutSeconds
        )

        return .success(data: message)
    }

    private func getSessionsAction(service: TmuxAgentService) -> PluginResult {
        let sessions = service.getAllSessions()
        return .success(data: sessions)
    }

    private func getSessionAction(
        action: PluginAction,
        service: TmuxAgentService
    ) -> PluginResult {
        guard let agentId = action.parameters["agent_id"] as? String else {
            return .failure(error: PluginError.invalidParameters("Missing agent_id"))
        }

        if let session = service.getSession(agentId: agentId) {
            return .success(data: session)
        } else {
            return .success(data: nil)
        }
    }
}

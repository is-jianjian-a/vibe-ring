import Foundation

/// Per-session metadata discovered from the Hermes WebUI REST API.
public struct HermesSessionMetadata: Equatable, Codable, Sendable {
    /// The Hermes SSE stream identifier for this session.
    public var streamId: String?
    /// The model name (e.g. "claude-sonnet-4-6").
    public var model: String?
    /// Working directory of the session.
    public var workspace: String?
    /// Whether the session is actively streaming on the Hermes backend.
    public var isStreaming: Bool
    /// Last user message text.
    public var lastUserMessage: String?
    /// Last assistant message text.
    public var lastAssistantMessage: String?
    /// Whether there is a pending approval request for this session.
    public var hasPendingApproval: Bool

    public var isEmpty: Bool {
        streamId == nil
            && model == nil
            && workspace == nil
            && !isStreaming
            && lastUserMessage == nil
            && lastAssistantMessage == nil
            && !hasPendingApproval
    }

    public init(
        streamId: String? = nil,
        model: String? = nil,
        workspace: String? = nil,
        isStreaming: Bool = false,
        lastUserMessage: String? = nil,
        lastAssistantMessage: String? = nil,
        hasPendingApproval: Bool = false
    ) {
        self.streamId = streamId
        self.model = model
        self.workspace = workspace
        self.isStreaming = isStreaming
        self.lastUserMessage = lastUserMessage
        self.lastAssistantMessage = lastAssistantMessage
        self.hasPendingApproval = hasPendingApproval
    }
}

import Foundation

/// Hook event types emitted by the Vibe Ring Hermes plugin.
///
/// The Python plugin running inside Hermes fires these events at key
/// lifecycle points and forwards them to the Vibe Ring bridge over
/// the Unix socket.  The event names match the Python plugin's
/// `hook_event_name` field exactly so that serialisation is trivial
/// on both sides.
public enum HermesPluginEventName: String, Codable, Sendable {
    case sessionStart = "session_start"
    case sessionEnd = "session_end"
    case toolCall = "tool_call"
    case approvalRequest = "approval_request"
    case approvalResponse = "approval_response"
}

/// Payload sent by the Hermes Python plugin over the bridge socket.
///
/// Fields are optional and populated depending on the hook event:
///
/// | Event              | Populated fields                                |
/// |--------------------|-------------------------------------------------|
/// | `sessionStart`     | `sessionID`, `model`, `cwd`, `sessionTitle`     |
/// | `sessionEnd`       | `sessionID`, `completed`, `interrupted`         |
/// | `toolCall`         | `sessionID`, `toolName`, `toolArgs`             |
/// | `approvalRequest`  | `sessionID`, `command`, `description`           |
/// | `approvalResponse` | `sessionID`, `command`, `choice`                |
public struct HermesPluginPayload: Equatable, Codable, Sendable {
    public var hookEventName: HermesPluginEventName
    public var sessionID: String

    // Session metadata (sessionStart)
    public var model: String?
    public var cwd: String?
    public var sessionTitle: String?

    // Tool-call metadata (toolCall)
    public var toolName: String?
    public var toolArgs: String?

    // Approval metadata (approvalRequest / approvalResponse)
    public var command: String?
    public var description: String?
    public var choice: String?

    // Session-end metadata (sessionEnd)
    public var completed: Bool?
    public var interrupted: Bool?

    private enum CodingKeys: String, CodingKey {
        case hookEventName = "hook_event_name"
        case sessionID = "session_id"
        case model
        case cwd
        case sessionTitle = "session_title"
        case toolName = "tool_name"
        case toolArgs = "tool_args"
        case command
        case description
        case choice
        case completed
        case interrupted
    }

    public init(
        hookEventName: HermesPluginEventName,
        sessionID: String,
        model: String? = nil,
        cwd: String? = nil,
        sessionTitle: String? = nil,
        toolName: String? = nil,
        toolArgs: String? = nil,
        command: String? = nil,
        description: String? = nil,
        choice: String? = nil,
        completed: Bool? = nil,
        interrupted: Bool? = nil
    ) {
        self.hookEventName = hookEventName
        self.sessionID = sessionID
        self.model = model
        self.cwd = cwd
        self.sessionTitle = sessionTitle
        self.toolName = toolName
        self.toolArgs = toolArgs
        self.command = command
        self.description = description
        self.choice = choice
        self.completed = completed
        self.interrupted = interrupted
    }
}

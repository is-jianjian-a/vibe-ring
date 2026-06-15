import AppKit
import Foundation
import VibeRingCore

/// Manages the lifecycle of the Hermes WebUI monitoring connection.
///
/// Polls the Hermes REST API (default `http://127.0.0.1:8787`) to discover
/// active sessions, detect state changes, and surface pending approvals.
/// Converts API responses into `AgentEvent`s that flow through the standard
/// `SessionState` reducer.
///
/// The coordinator is started/stopped by `ProcessMonitoringCoordinator` when
/// a Hermes process is detected/lost, following the same pattern as
/// `CodexAppServerCoordinator`.
@Observable
@MainActor
final class HermesCoordinator {
    @ObservationIgnored
    private var client: HermesAPIClient?

    @ObservationIgnored
    private var pollingTask: Task<Void, Never>?

    /// Callback to emit AgentEvents into AppModel.
    @ObservationIgnored
    var onEvent: ((AgentEvent) -> Void)?

    /// Callback to log status messages.
    @ObservationIgnored
    var onStatusMessage: ((String) -> Void)?

    /// Returns `true` if a session with the given id is already tracked.
    @ObservationIgnored
    var isSessionTracked: ((String) -> Bool)?

    private(set) var isConnected = false

    /// Tracked session IDs from previous poll cycles.
    @ObservationIgnored
    private var knownSessionIDs: Set<String> = []

    // MARK: - Public API

    /// Ensure a polling connection exists.  Called from the monitoring loop
    /// when a Hermes process is detected.  Idempotent — does nothing if
    /// already connected or a connection attempt is in progress.
    func ensureConnected() {
        guard !isConnected, pollingTask == nil else { return }

        let client = HermesAPIClient()
        self.client = client
        isConnected = true
        knownSessionIDs = []

        onStatusMessage?("Connected to Hermes API.")

        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.pollHermes()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    /// Disconnect and stop polling.  Called when the Hermes process is no
    /// longer detected.
    func disconnect() {
        pollingTask?.cancel()
        pollingTask = nil
        client = nil
        isConnected = false
        knownSessionIDs = []

        onStatusMessage?("Disconnected from Hermes API.")
    }

    // MARK: - Polling

    private func pollHermes() async {
        guard let client else { return }

        // First, verify Hermes is reachable.
        guard let _ = try? await client.healthCheck() else {
            return
        }

        // Fetch the current session list.
        guard let sessionsResponse = try? await client.listSessions() else {
            return
        }

        let currentIDs = Set(sessionsResponse.sessions.map { $0.session_id })
        let newIDs = currentIDs.subtracting(knownSessionIDs)
        let removedIDs = knownSessionIDs.subtracting(currentIDs)

        // Handle new sessions.
        for summary in sessionsResponse.sessions where newIDs.contains(summary.session_id) {
            await handleNewSession(summary)
        }

        // Handle removed sessions.
        for id in removedIDs {
            onEvent?(.sessionCompleted(SessionCompleted(
                sessionID: id,
                summary: "Hermes session ended.",
                timestamp: .now,
                isSessionEnd: true
            )))
        }

        knownSessionIDs = currentIDs

        // Check for approval state changes on streaming sessions.
        for summary in sessionsResponse.sessions
        where summary.is_streaming == true && !newIDs.contains(summary.session_id) {
            await checkApprovalState(sessionID: summary.session_id)
        }
    }

    private func handleNewSession(_ summary: HermesSessionSummary) async {
        guard isSessionTracked?(summary.session_id) != true else { return }

        // Fetch session detail for richer metadata.
        var detail: HermesSessionDetail?
        var lastUserMsg: String?
        var lastAssistantMsg: String?

        if let d = try? await client?.getSession(sessionID: summary.session_id) {
            detail = d
            if let messages = d.messages {
                lastUserMsg = messages.last { $0.role == "user" }?.content
                lastAssistantMsg = messages.last { $0.role == "assistant" }?.content
            }
        }

        let isStreaming = detail?.is_streaming ?? summary.is_streaming ?? false
        let phase: SessionPhase = isStreaming ? .running : .completed
        let model = detail?.model ?? summary.model

        let metadata = HermesSessionMetadata(
            streamId: detail?.stream_id ?? summary.stream_id,
            model: model,
            workspace: detail?.workspace ?? summary.workspace,
            isStreaming: isStreaming,
            lastUserMessage: lastUserMsg,
            lastAssistantMessage: lastAssistantMsg,
            hasPendingApproval: detail?.pending_approval ?? false
        )

        let title = summary.title ?? detail?.title ?? "Hermes · \(model ?? "Agent")"

        onEvent?(.sessionStarted(SessionStarted(
            sessionID: summary.session_id,
            title: title,
            tool: .hermes,
            origin: .live,
            initialPhase: phase,
            summary: isStreaming ? "Working…" : "Completed.",
            timestamp: .now,
            jumpTarget: JumpTarget(
                terminalApp: "Hermes",
                workspaceName: title,
                paneTitle: title,
                workingDirectory: summary.workspace,
                terminalSessionID: summary.session_id
            ),
            hermesMetadata: metadata
        )))

        // Emit additional events based on state.
        if metadata.hasPendingApproval {
            onEvent?(.permissionRequested(PermissionRequested(
                sessionID: summary.session_id,
                request: PermissionRequest(
                    title: "Hermes Approval Required",
                    summary: "Hermes is waiting for approval.",
                    affectedPath: ""
                ),
                timestamp: .now
            )))
        }

        onStatusMessage?("Discovered Hermes session: \(title)")
    }

    private func checkApprovalState(sessionID: String) async {
        guard let client else { return }
        guard let response = try? await client.pendingApproval(sessionID: sessionID) else { return }

        if response.has_pending == true {
            let summary = response.requests?.first?.summary ?? "Hermes is waiting for approval."
            onEvent?(.permissionRequested(PermissionRequested(
                sessionID: sessionID,
                request: PermissionRequest(
                    title: "Hermes Approval Required",
                    summary: summary,
                    affectedPath: response.requests?.first?.affected_path ?? ""
                ),
                timestamp: .now
            )))
        }
    }
}

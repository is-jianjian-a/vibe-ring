import AppKit
import Foundation
import VibeRingCore

/// Manages the lifecycle of Hermes agent monitoring.
///
/// Reads active Hermes sessions directly from `~/.hermes/state.db` (SQLite)
/// every 5 seconds.  No WebUI server required — works with Hermes CLI,
/// gateway (Telegram/Discord/etc.), and any other Hermes session source.
///
/// The coordinator is started/stopped by `ProcessMonitoringCoordinator` when
/// a Hermes process is detected/lost, following the same pattern as
/// `CodexAppServerCoordinator`.
@Observable
@MainActor
final class HermesCoordinator {
    @ObservationIgnored
    private var db: HermesStateDB?

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

    func ensureConnected() {
        guard !isConnected, pollingTask == nil else { return }

        let db = HermesStateDB()
        self.db = db
        isConnected = true
        knownSessionIDs = []

        onStatusMessage?("Connected to Hermes state DB.")

        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.pollHermes()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    func disconnect() {
        pollingTask?.cancel()
        pollingTask = nil
        db = nil
        isConnected = false
        knownSessionIDs = []

        onStatusMessage?("Disconnected from Hermes state DB.")
    }

    // MARK: - Polling

    private func pollHermes() async {
        guard let db else { return }

        let records: [HermesSessionRecord]
        do {
            records = try db.listActiveSessions()
        } catch {
            return
        }

        let currentIDs = Set(records.map(\.id))
        let newIDs = currentIDs.subtracting(knownSessionIDs)
        let removedIDs = knownSessionIDs.subtracting(currentIDs)

        for record in records where newIDs.contains(record.id) {
            handleNewSession(record)
        }

        for id in removedIDs {
            onEvent?(.sessionCompleted(SessionCompleted(
                sessionID: id,
                summary: "Hermes session ended.",
                timestamp: .now,
                isSessionEnd: true
            )))
        }

        knownSessionIDs = currentIDs
    }

    private func handleNewSession(_ record: HermesSessionRecord) {
        guard isSessionTracked?(record.id) != true else { return }

        let metadata = HermesSessionMetadata(
            model: record.model,
            workspace: record.cwd,
            isStreaming: true,  // active Hermes session ≈ streaming
            hasPendingApproval: false
        )

        onEvent?(.sessionStarted(SessionStarted(
            sessionID: record.id,
            title: record.sessionTitle,
            tool: .hermes,
            origin: .live,
            initialPhase: .running,
            summary: "Hermes · \(record.source)",
            timestamp: record.startedAt,
            jumpTarget: JumpTarget(
                terminalApp: "Hermes",
                workspaceName: record.sessionTitle,
                paneTitle: record.sessionTitle,
                workingDirectory: record.cwd,
                terminalSessionID: record.id
            ),
            hermesMetadata: metadata
        )))

        onStatusMessage?("Discovered Hermes session: \(record.sessionTitle)")
    }
}

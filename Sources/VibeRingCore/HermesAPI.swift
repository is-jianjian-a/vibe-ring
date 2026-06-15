import Foundation

// MARK: - Session Record

/// A session record read directly from Hermes' `~/.hermes/state.db`.
public struct HermesSessionRecord: Sendable {
    public let id: String
    public let source: String           // "cli", "webui", "feishu", "gateway", etc.
    public let model: String?
    public let title: String?
    public let startedAt: Date
    public let endedAt: Date?
    public let messageCount: Int
    public let inputTokens: Int
    public let outputTokens: Int
    public let cwd: String?

    public var isActive: Bool { endedAt == nil }

    public var sessionTitle: String {
        if let title, !title.isEmpty { return title }
        return "Hermes · \(model ?? "Agent")"
    }
}

// MARK: - State DB Reader

/// Reads Hermes session data directly from `~/.hermes/state.db`.
///
/// No HTTP server required — the SQLite database is always present when
/// Hermes CLI is running.
public final class HermesStateDB: Sendable {
    private let dbPath: String

    public init(dbPath: String? = nil) {
        let home = ProcessInfo.processInfo.environment["HOME"]
            ?? NSHomeDirectory()
        self.dbPath = dbPath ?? "\(home)/.hermes/state.db"
    }

    // MARK: - Public API

    /// Returns all sessions whose `ended_at` is NULL (i.e. still active).
    public func listActiveSessions() throws -> [HermesSessionRecord] {
        return try query(
            """
            SELECT id, source, model, title, started_at, ended_at,
                   message_count, input_tokens, output_tokens, cwd
            FROM sessions
            WHERE ended_at IS NULL
            ORDER BY started_at DESC
            """
        )
    }

    /// Returns a single session by ID, or nil if not found.
    public func getSession(id: String) throws -> HermesSessionRecord? {
        return try query(
            """
            SELECT id, source, model, title, started_at, ended_at,
                   message_count, input_tokens, output_tokens, cwd
            FROM sessions
            WHERE id = ?
            """,
            arguments: [id]
        ).first
    }

    // MARK: - Internal

    private func query(
        _ sql: String,
        arguments: [String] = []
    ) throws -> [HermesSessionRecord] {
        // Use /usr/bin/sqlite3 to avoid needing a Swift SQLite dependency.
        var args = ["-readonly", "-json", "-noheader", dbPath, sql]
        args.insert(contentsOf: arguments, at: args.count - 3)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = args
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else { return [] }

        let outputData = process.standardOutput.flatMap {
            ($0 as? Pipe)?.fileHandleForReading.readDataToEndOfFile()
        } ?? Data()

        guard !outputData.isEmpty else { return [] }

        // sqlite3 -json outputs one JSON array per row. Parse them.
        guard let rawRows = try? JSONSerialization.jsonObject(with: outputData) as? [[String: Any]] else {
            return []
        }

        return rawRows.compactMap { row in
            guard let id = row["id"] as? String,
                  let startedAtUnix = row["started_at"] as? TimeInterval else {
                return nil
            }
            return HermesSessionRecord(
                id: id,
                source: row["source"] as? String ?? "",
                model: row["model"] as? String,
                title: row["title"] as? String,
                startedAt: Date(timeIntervalSince1970: startedAtUnix),
                endedAt: (row["ended_at"] as? TimeInterval).map(Date.init(timeIntervalSince1970:)),
                messageCount: row["message_count"] as? Int ?? 0,
                inputTokens: row["input_tokens"] as? Int ?? 0,
                outputTokens: row["output_tokens"] as? Int ?? 0,
                cwd: row["cwd"] as? String
            )
        }
    }
}

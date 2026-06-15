import Foundation

// MARK: - API Response Models

/// GET /api/health response.
public struct HermesHealthResponse: Codable, Sendable {
    public let active_streams: Int
    public let active_runs: Int
    public let runs: [HermesRunSummary]?
    public let uptime_seconds: Double?
    public let last_run_finished_at: String?
}

public struct HermesRunSummary: Codable, Sendable {
    public let stream_id: String?
    public let session_id: String?
    public let phase: String?
    public let started_at: String?
    public let age_seconds: Double?
}

/// GET /api/sessions response.
public struct HermesSessionsResponse: Codable, Sendable {
    public let sessions: [HermesSessionSummary]
    public let cli_count: Int?
    public let active_profile: String?
}

public struct HermesSessionSummary: Codable, Sendable {
    public let session_id: String
    public let title: String?
    public let model: String?
    public let workspace: String?
    public let is_streaming: Bool?
    public let stream_id: String?
    public let created_at: String?
    public let updated_at: String?
}

/// GET /api/session?session_id=X response (partial — only fields we use).
public struct HermesSessionDetail: Codable, Sendable {
    public let session_id: String
    public let title: String?
    public let model: String?
    public let workspace: String?
    public let is_streaming: Bool?
    public let stream_id: String?
    public let created_at: String?
    public let updated_at: String?
    public let messages: [HermesMessage]?
    public let pending_approval: Bool?
}

public struct HermesMessage: Codable, Sendable {
    public let role: String
    public let content: String?
}

/// GET /api/approval/pending?session_id=X response.
public struct HermesApprovalPendingResponse: Codable, Sendable {
    public let has_pending: Bool?
    public let requests: [HermesApprovalRequest]?
}

public struct HermesApprovalRequest: Codable, Sendable {
    public let tool_name: String?
    public let affected_path: String?
    public let summary: String?
}

// MARK: - Errors

public enum HermesAPIError: Error, LocalizedError {
    case notRunning
    case requestFailed(statusCode: Int)
    case decodeFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .notRunning:
            "Hermes is not running"
        case let .requestFailed(statusCode):
            "Hermes API returned status \(statusCode)"
        case let .decodeFailed(error):
            "Failed to decode Hermes response: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Client

public final class HermesAPIClient: Sendable {
    public let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL = URL(string: "http://127.0.0.1:8787")!) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 10
        self.session = URLSession(configuration: config)
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - API Methods

    public func healthCheck() async throws -> HermesHealthResponse {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("health")
        return try await fetch(url)
    }

    public func listSessions() async throws -> HermesSessionsResponse {
        let url = baseURL.appendingPathComponent("api").appendingPathComponent("sessions")
        return try await fetch(url)
    }

    public func getSession(sessionID: String) async throws -> HermesSessionDetail {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api").appendingPathComponent("session"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "session_id", value: sessionID),
            URLQueryItem(name: "messages", value: "1"),
            URLQueryItem(name: "msg_limit", value: "2"),
        ]
        return try await fetch(components.url!)
    }

    public func pendingApproval(sessionID: String) async throws -> HermesApprovalPendingResponse {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api").appendingPathComponent("approval").appendingPathComponent("pending"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "session_id", value: sessionID)]
        return try await fetch(components.url!)
    }

    // MARK: - Internal

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HermesAPIError.notRunning
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw HermesAPIError.requestFailed(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw HermesAPIError.decodeFailed(error)
        }
    }
}

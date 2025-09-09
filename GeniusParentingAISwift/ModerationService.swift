//
//  ModerationService.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/9/9.
//

// ModerationService.swift
// GeniusParentingAI
//
// A dedicated service for the new Moderation Report endpoints.
// Endpoints (Strapi v4 custom routes):
//  POST /api/moderation/report/post
//  POST /api/moderation/report/comment
//  POST /api/moderation/report/user
//  POST /api/moderation/report/resolve   (admin-only in app logic)
//
// Notes
// - The Strapi controllers accept either `{ data: {...} }` or a bare JSON body.
//   We send a bare JSON body for simplicity.
// - Authorization: The controllers require a valid Bearer token. We rely on
//   NetworkManager to attach the JWT (to be consistent with StrapiService usage).
// - Reason validation mirrors server-side REASONS; we also expose an enum to
//   keep the call sites type-safe on iOS.
// - Logging matches the style used by StrapiService via AppLogger.

import Foundation

// MARK: - Models

/// Allowed reasons for reporting (mirrors server REASONS set)
public enum ModerationReason: String, Codable, CaseIterable, Hashable {
    case spam
    case harassment
    case hate
    case sexual
    case violence
    case illegal
    case other
}

/// Allowed actions when resolving a report (admin-only)
public enum ModerationActionTaken: String, Codable, CaseIterable {
    case removed_content
    case warned_user
    case banned_user
    case no_violation
}

// Payloads
public struct ReportPostPayload: Codable {
    let postId: Int
    let reason: ModerationReason
    let details: String?
}

public struct ReportCommentPayload: Codable {
    let commentId: Int
    let reason: ModerationReason
    let details: String?
}

public struct ReportUserPayload: Codable {
    let username: String?
    let userId: Int?
    let reason: ModerationReason
    let details: String?
}

public struct ResolveReportPayload: Codable {
    let reportId: Int
    let action_taken: ModerationActionTaken
}

// Responses
public struct ModerationReportResponse: Codable {
    public let id: Int
    public let status: String
}

public struct ModerationResolveResponse: Codable {
    public let id: Int
    public let status: String
    public let action_taken: ModerationActionTaken
}

public struct BlockUserPayload: Codable {
    let username: String?
    let userId: Int?
}

public struct UnblockUserPayload: Codable {
    let username: String?
    let userId: Int?
}

public struct BlockUserResponse: Codable {
    let ok: Bool
    let id: Int?
}

public struct UnblockUserResponse: Codable {
    let ok: Bool
}

public struct BlockedUser: Codable, Identifiable, Hashable {
    public let id: Int
    public let username: String
}


// MARK: - Service

final class ModerationService {

    static let shared = ModerationService()
    private let logger = AppLogger(category: "ModerationService")

    private init() {}

    // MARK: - Helpers

    private func makeURL(_ path: String) -> URL {
        // All moderation endpoints live under /api
        return URL(string: "\(Config.strapiBaseUrl)/api\(path)")!
    }

    // MARK: - Public API

    /// POST /api/moderation/report/post
    @discardableResult
    func reportPost(postId: Int, reason: ModerationReason, details: String? = nil) async throws -> ModerationReportResponse {
        let functionName = #function
        logger.info("[ModerationService::\(functionName)] - Reporting post id=\(postId), reason=\(reason.rawValue)")
        let url = makeURL("/moderation/report/post")
        let body = ReportPostPayload(postId: postId, reason: reason, details: details)
        do {
            let resp: ModerationReportResponse = try await NetworkManager.shared.post(to: url, body: body)
            logger.info("[ModerationService::\(functionName)] - Report created id=\(resp.id), status=\(resp.status)")
            return resp
        } catch {
            logger.error("[ModerationService::\(functionName)] - Failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// POST /api/moderation/report/comment
    @discardableResult
    func reportComment(commentId: Int, reason: ModerationReason, details: String? = nil) async throws -> ModerationReportResponse {
        let functionName = #function
        logger.info("[ModerationService::\(functionName)] - Reporting comment id=\(commentId), reason=\(reason.rawValue)")
        let url = makeURL("/moderation/report/comment")
        let body = ReportCommentPayload(commentId: commentId, reason: reason, details: details)
        do {
            let resp: ModerationReportResponse = try await NetworkManager.shared.post(to: url, body: body)
            logger.info("[ModerationService::\(functionName)] - Report created id=\(resp.id), status=\(resp.status)")
            return resp
        } catch {
            logger.error("[ModerationService::\(functionName)] - Failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// POST /api/moderation/report/user
    /// You must provide either `username` or `userId` (server enforces this too).
    @discardableResult
    func reportUser(username: String? = nil, userId: Int? = nil, reason: ModerationReason, details: String? = nil) async throws -> ModerationReportResponse {
        let functionName = #function
        logger.info("[ModerationService::\(functionName)] - Reporting user username=\(username ?? "nil"), userId=\(userId?.description ?? "nil"), reason=\(reason.rawValue)")
        let url = makeURL("/moderation/report/user")
        let body = ReportUserPayload(username: username, userId: userId, reason: reason, details: details)
        do {
            let resp: ModerationReportResponse = try await NetworkManager.shared.post(to: url, body: body)
            logger.info("[ModerationService::\(functionName)] - Report created id=\(resp.id), status=\(resp.status)")
            return resp
        } catch {
            logger.error("[ModerationService::\(functionName)] - Failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// POST /api/moderation/report/resolve (admin-only per app logic)
    @discardableResult
    func resolveReport(reportId: Int, actionTaken: ModerationActionTaken) async throws -> ModerationResolveResponse {
        let functionName = #function
        logger.info("[ModerationService::\(functionName)] - Resolving report id=\(reportId) with action=\(actionTaken.rawValue)")
        let url = makeURL("/moderation/report/resolve")
        let body = ResolveReportPayload(reportId: reportId, action_taken: actionTaken)
        do {
            let resp: ModerationResolveResponse = try await NetworkManager.shared.post(to: url, body: body)
            logger.info("[ModerationService::\(functionName)] - Resolved id=\(resp.id), status=\(resp.status), action=\(resp.action_taken.rawValue)")
            return resp
        } catch {
            logger.error("[ModerationService::\(functionName)] - Failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// POST /api/moderation/block
    @discardableResult
    func blockUser(username: String? = nil, userId: Int? = nil) async throws -> BlockUserResponse {
        let functionName = #function
        logger.info("[ModerationService::\(functionName)] - Blocking user username=\(username ?? "nil"), userId=\(userId?.description ?? "nil")")
        let url = makeURL("/moderation/block")
        let body = BlockUserPayload(username: username, userId: userId)
        do {
            let resp: BlockUserResponse = try await NetworkManager.shared.post(to: url, body: body)
            logger.info("[ModerationService::\(functionName)] - Block result ok=\(resp.ok), id=\(resp.id?.description ?? "nil")")
            return resp
        } catch {
            logger.error("[ModerationService::\(functionName)] - Failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// POST /api/moderation/unblock
    @discardableResult
    func unblockUser(username: String? = nil, userId: Int? = nil) async throws -> UnblockUserResponse {
        let functionName = #function
        logger.info("[ModerationService::\(functionName)] - Unblocking user username=\(username ?? "nil"), userId=\(userId?.description ?? "nil")")
        let url = makeURL("/moderation/unblock")
        let body = UnblockUserPayload(username: username, userId: userId)
        do {
            let resp: UnblockUserResponse = try await NetworkManager.shared.post(to: url, body: body)
            logger.info("[ModerationService::\(functionName)] - Unblock result ok=\(resp.ok)")
            return resp
        } catch {
            logger.error("[ModerationService::\(functionName)] - Failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// GET /api/moderation/blocks
    func fetchMyBlocks() async throws -> [BlockedUser] {
        let functionName = #function
        logger.info("[ModerationService::\(functionName)] - Fetching my blocked users.")
        let url = makeURL("/moderation/blocks")
        do {
            let resp: [BlockedUser] = try await NetworkManager.shared.fetchDirect(from: url)
            logger.info("[ModerationService::\(functionName)] - Received \(resp.count) blocked users.")
            return resp
        } catch {
            logger.error("[ModerationService::\(functionName)] - Failed: \(error.localizedDescription)")
            throw error
        }
    }

}

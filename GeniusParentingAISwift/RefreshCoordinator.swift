//
//  RefreshCoordinator.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/9/9.
//


// RefreshCoordinator.swift
import Foundation

final class RefreshCoordinator: ObservableObject {
    static let shared = RefreshCoordinator()
    private init() {}

    private let logger = AppLogger(category: "RefreshCoordinator")

    // NEW: recommendations flag (plus your existing community flag)
    @Published private(set) var needsRecommendationsRefresh = false
    @Published private(set) var needsCommunityRefresh = false

    // MARK: Recommendations
    func markRecommendationsNeedsRefresh(file: String = #fileID, line: Int = #line) {
        logger.info("[markRecommendationsNeedsRefresh] called @ \(file):\(line)")
        DispatchQueue.main.async {
            self.needsRecommendationsRefresh = true
            self.logger.debug("[markRecommendationsNeedsRefresh] needsRecommendationsRefresh -> TRUE")
        }
    }

    @discardableResult
    func consumeRecommendationsNeedsRefresh(file: String = #fileID, line: Int = #line) -> Bool {
        let should = needsRecommendationsRefresh
        logger.info("[consumeRecommendationsNeedsRefresh] return=\(should) @ \(file):\(line)")
        if should {
            needsRecommendationsRefresh = false
            logger.debug("[consumeRecommendationsNeedsRefresh] needsRecommendationsRefresh -> FALSE")
        }
        return should
    }

    // MARK: Community (unchanged behavior, now logged)
    func markCommunityNeedsRefresh() {
        logger.info("[markCommunityNeedsRefresh] called")
        DispatchQueue.main.async { self.needsCommunityRefresh = true }
    }

    @discardableResult
    func consumeCommunityNeedsRefresh() -> Bool {
        let should = needsCommunityRefresh
        logger.info("[consumeCommunityNeedsRefresh] return=\(should)")
        needsCommunityRefresh = false
        return should
    }
}

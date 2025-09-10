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

    @Published private(set) var needsCommunityRefresh = false

    func markCommunityNeedsRefresh() {
        DispatchQueue.main.async { self.needsCommunityRefresh = true }
    }

    @discardableResult
    func consumeCommunityNeedsRefresh() -> Bool {
        let should = needsCommunityRefresh
        needsCommunityRefresh = false
        return should
    }
}


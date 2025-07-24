//
//  Permission.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/07/23.
//

import Foundation

/// Represents a specific feature or action within the app that can be controlled by a permission check.
enum Permission {
    case viewAITab
    case useAIChat
    case viewCommunityTab
    case canPostComment
    case accessPremiumCourses
    case accessMembershipCourses // <-- ADDED
    // Add other specific permissions as your app grows.
}

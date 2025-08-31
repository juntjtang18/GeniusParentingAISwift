//
//  Permission.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/07/23.
//
// Permission.swift
import Foundation

enum Permission {
    case viewAITab
    case useAIChat
    case viewCommunityTab
    case canPostComment
    case accessPremiumCourses
    case accessMembershipCourses

    /// The Strapi slug that corresponds to this permission.
    var slug: String {
        switch self {
        case .viewAITab: return "ai-chatbot"
        case .useAIChat: return "ai-chatbot" // Can be the same slug for multiple checks
        case .viewCommunityTab: return "community-access" // Example slug
        case .canPostComment: return "community-access"   // Example slug
        case .accessPremiumCourses: return "premium-courses" // Example slug
        case .accessMembershipCourses: return "membership-courses" // Example slug
        }
    }
}

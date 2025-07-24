//
//  Role.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/7/23.
//


//
//  Role.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/07/23.
//

import Foundation

/// Defines the user roles within the app.
/// The rawValue must match the string value provided by the backend (e.g., in the Plan's 'role' field).
enum Role: String, Codable, Comparable {
    case free
    case basic
    case premium

    /// Defines the hierarchy of roles for comparison.
    private var order: Int {
        switch self {
        case .free: return 0
        case .basic: return 1
        case .premium: return 2
        }
    }

    /// Allows for comparisons like `userRole >= .basic`.
    static func < (lhs: Role, rhs: Role) -> Bool {
        return lhs.order < rhs.order
    }
}

//
//  PermissionGateModifier.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/7/23.
//


//
//  PermissionViewModifier.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/07/23.
//

import SwiftUI

/// A view modifier that "gates" access to a view's functionality based on a permission check.
/// If the check fails, it presents a specified destination view (like a paywall) as a sheet.
struct PermissionGateModifier<Destination: View>: ViewModifier {
    /// A condition to determine if the gate should be active.
    let condition: Bool
    /// The specific permission required to pass the gate.
    let permission: Permission
    /// A closure that provides the destination view to show if permission is denied.
    let destination: () -> Destination

    @State private var showDestinationSheet = false

    func body(content: Content) -> some View {
        // The main content is wrapped in a button to intercept taps.
        Button(action: {
            // If the gate condition is met, check the permission.
            if condition {
                if !PermissionManager.shared.canAccess(permission) {
                    // If permission is denied, trigger the sheet.
                    showDestinationSheet = true
                }
            }
            // If the condition is not met, the gate is ignored.
            // Note: The original view's tap action (like a NavigationLink) will need to be handled separately.
        }) {
            content
        }
        .buttonStyle(.plain) // Use plain style to not alter the content's appearance.
        .sheet(isPresented: $showDestinationSheet, content: destination)
    }
}

extension View {
    /// A declarative modifier to protect a view with a permission check.
    ///
    /// If the `condition` is `true`, this modifier checks if the user has the required `permission`.
    /// If the user lacks permission, it presents the `destination` view as a sheet when the view is tapped.
    ///
    /// - Parameters:
    ///   - condition: A boolean indicating whether to apply the permission check.
    ///   - permission: The `Permission` required to access the view's functionality.
    ///   - destination: A view to present if the permission check fails.
    func gate(if condition: Bool, requires permission: Permission, to destination: @escaping () -> some View) -> some View {
        self.modifier(PermissionGateModifier(condition: condition, permission: permission, destination: destination))
    }
}

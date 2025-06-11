import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedTab: Int
    @Binding var isShowingLanguageSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Menu Header
            VStack(alignment: .leading) {
                Text("Settings")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue)

            // 2. Menu Items
            VStack(alignment: .leading, spacing: 1) {
                Button(action: {
                    // Navigate to Profile
                    handleMenuSelection {
                        selectedTab = 4
                    }
                }) {
                    Label("Profile", systemImage: "person.fill")
                }
                .buttonStyle(SideMenuItemButtonStyle()) // Apply the custom ButtonStyle

                Divider()

                Button(action: {
                    // Show the language picker
                    handleMenuSelection {
                        isShowingLanguageSheet = true
                    }
                }) {
                    Label("Language", systemImage: "globe")
                }
                .buttonStyle(SideMenuItemButtonStyle()) // Apply the custom ButtonStyle
            }

            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    /// Helper function to close the menu with an animation before executing an action.
    private func handleMenuSelection(action: @escaping () -> Void) {
        withAnimation(.easeInOut) {
            isShowing = false
        }
        // Dispatch the action after the animation to avoid jarring UI changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            action()
        }
    }
}

// --- FIX: Replaced ViewModifier with the more appropriate ButtonStyle ---
struct SideMenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.primary)
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}


struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView(
            isShowing: .constant(true),
            selectedTab: .constant(0),
            isShowingLanguageSheet: .constant(false)
        )
    }
}

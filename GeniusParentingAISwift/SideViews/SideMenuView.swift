// GeniusParentingAISwift/SideMenuView.swift
import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    // --- ADDED: To receive the viewModel from MainView ---
    let profileViewModel: ProfileViewModel
    @Binding var isShowingProfileSheet: Bool
    @Binding var isShowingLanguageSheet: Bool
    @Binding var isShowingSettingSheet: Bool
    // Removed: @Binding var isShowingThemeSheet: Bool // No longer needed
    let logoutAction: () -> Void
    @Binding var isShowingPrivacySheet: Bool
    @Binding var isShowingTermsSheet: Bool
    @Binding var isShowingSubscriptionSheet: Bool
    @Binding var isShowingBlockedUsers: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading) {
                Text("Settings")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue)

            VStack(alignment: .leading, spacing: 1) {
                Button(action: { handleMenuSelection { isShowingProfileSheet = true } }) {
                    Label("Profile", systemImage: "person.fill")
                }
                .buttonStyle(SideMenuItemButtonStyle())

                Divider()
                
                Button(action: { handleMenuSelection { isShowingSubscriptionSheet = true } }) {
                    Label("Subscription Plans", systemImage: "creditcard.fill")
                }
                .buttonStyle(SideMenuItemButtonStyle())
                
                Divider()
                Button(action: { handleMenuSelection { isShowingBlockedUsers = true } }) {
                    Label("Blocked Users", systemImage: "person.2.slash")
                }
                .buttonStyle(SideMenuItemButtonStyle())
                
                /*
                Divider()
                
                Button(action: { handleMenuSelection { isShowingLanguageSheet = true } }) {
                    Label("Language", systemImage: "globe")
                }
                .buttonStyle(SideMenuItemButtonStyle())
                
                Divider()
                */
                // Commented out the Theme selection button
                /*
                Button(action: { handleMenuSelection { isShowingThemeSheet = true } }) {
                    Label("Change Theme", systemImage: "paintbrush.fill")
                }
                .buttonStyle(SideMenuItemButtonStyle())
                
                Divider()

                Button(action: { handleMenuSelection { isShowingSettingSheet = true } }) {
                    Label("Setting", systemImage: "gear")
                }
                .buttonStyle(SideMenuItemButtonStyle())
                
                Divider()
                 */

                Button(action: {
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                }
                .buttonStyle(SideMenuItemButtonStyle())

                Divider()

                Button(action: {
                    if let url = URL(string: "https://www.geniusparentingai.ca/privacy-policy") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Privacy Policy", systemImage: "shield.lefthalf.filled")
                }
                .buttonStyle(SideMenuItemButtonStyle())

                Divider()

                Button(action: {
                    if let url = URL(string: "https://www.geniusparentingai.ca/community-guidelines") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Community Guidelines", systemImage: "list.bullet.rectangle")
                }
                .buttonStyle(SideMenuItemButtonStyle())

            }

            Spacer()
            
            Button(action: logoutAction) {
                Label("Logout", systemImage: "arrow.right.to.line")
                    .foregroundColor(.red)
            }
            .buttonStyle(SideMenuItemButtonStyle())
            .padding(.bottom)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func handleMenuSelection(action: @escaping () -> Void) {
        withAnimation(.easeInOut) {
            isShowing = false
        }
        action()
    }
}

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
            profileViewModel: ProfileViewModel(),
            isShowingProfileSheet: .constant(false),
            isShowingLanguageSheet: .constant(false),
            isShowingSettingSheet: .constant(false),
            // Removed: isShowingThemeSheet: .constant(false), // No longer needed
            logoutAction: {},
            isShowingPrivacySheet: .constant(false),
            isShowingTermsSheet: .constant(false),
            isShowingSubscriptionSheet: .constant(false),
            isShowingBlockedUsers: .constant(false)
        )
    }
}

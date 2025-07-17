// GeniusParentingAISwift/SideMenuView.swift
import SwiftUI
import KeychainAccess

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var isShowingProfileSheet: Bool
    @Binding var isShowingLanguageSheet: Bool
    @Binding var isShowingSettingSheet: Bool
    @Binding var isShowingThemeSheet: Bool
    @Binding var isLoggedIn: Bool
    @Binding var isShowingPrivacySheet: Bool
    @Binding var isShowingTermsSheet: Bool
    @Binding var isShowingSubscriptionSheet: Bool

    private let keychain = Keychain(service: Config.keychainService)

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
                
                Button(action: { handleMenuSelection { isShowingLanguageSheet = true } }) {
                    Label("Language", systemImage: "globe")
                }
                .buttonStyle(SideMenuItemButtonStyle())
                
                Divider()

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
                
                Button(action: { handleMenuSelection { isShowingTermsSheet = true } }) {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                }
                .buttonStyle(SideMenuItemButtonStyle())

                Divider()

                Button(action: { handleMenuSelection { isShowingPrivacySheet = true } }) {
                    Label("Privacy Policy", systemImage: "shield.lefthalf.filled")
                }
                .buttonStyle(SideMenuItemButtonStyle())
            }

            Spacer()
            
            // 3. Logout Button
            Button(action: {
                keychain["jwt"] = nil
                SessionManager.shared.currentUser = nil
                withAnimation {
                    isLoggedIn = false
                }
            }) {
                Label("Logout", systemImage: "arrow.right.to.line")
                    .foregroundColor(.red)
            }
            .buttonStyle(SideMenuItemButtonStyle())
            .padding(.bottom)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func handleMenuSelection(action: @escaping () -> Void) {
        // MODIFIED: Removed the delay for more reliable state updates
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
            isShowingProfileSheet: .constant(false),
            isShowingLanguageSheet: .constant(false),
            isShowingSettingSheet: .constant(false),
            isShowingThemeSheet: .constant(false),
            isLoggedIn: .constant(true),
            isShowingPrivacySheet: .constant(false),
            isShowingTermsSheet: .constant(false),
            isShowingSubscriptionSheet: .constant(false)
        )
    }
}

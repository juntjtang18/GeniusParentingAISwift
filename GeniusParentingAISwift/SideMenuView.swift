import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var isShowingProfileSheet: Bool
    @Binding var isShowingLanguageSheet: Bool
    // New binding to control the settings sheet
    @Binding var isShowingSettingSheet: Bool

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
                    handleMenuSelection {
                        isShowingProfileSheet = true
                    }
                }) {
                    Label("Profile", systemImage: "person.fill")
                }
                .buttonStyle(SideMenuItemButtonStyle())

                Divider()

                Button(action: {
                    handleMenuSelection {
                        isShowingLanguageSheet = true
                    }
                }) {
                    Label("Language", systemImage: "globe")
                }
                .buttonStyle(SideMenuItemButtonStyle())
                
                Divider()

                // New "Setting" menu item
                Button(action: {
                    handleMenuSelection {
                        isShowingSettingSheet = true
                    }
                }) {
                    Label("Setting", systemImage: "gear")
                }
                .buttonStyle(SideMenuItemButtonStyle())
            }

            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func handleMenuSelection(action: @escaping () -> Void) {
        withAnimation(.easeInOut) {
            isShowing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            action()
        }
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
            isShowingSettingSheet: .constant(false)
        )
    }
}

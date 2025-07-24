import SwiftUI

struct SettingView: View {
    // The key and variable name are updated for clarity.
    @AppStorage("isRefreshModeEnabled") private var isRefreshModeEnabled = false
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Data Options"), footer: Text("This will control data refreshing behavior in a future update.")) {
                    // The label for the Toggle is now "REFRESH mode".
                    Toggle("REFRESH mode", isOn: $isRefreshModeEnabled)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingView(isPresented: .constant(true))
        }
    }
}

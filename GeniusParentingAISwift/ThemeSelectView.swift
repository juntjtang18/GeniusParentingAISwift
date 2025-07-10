import SwiftUI

struct ThemeSelectView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // ✅ LOG 4: This is the most important log.
        let _ = print("LOG: ThemeSelectView body is being evaluated. It found \(themeManager.themes.count) themes in the ThemeManager.")
        
        return NavigationView {
            VStack {
                List {
                    ForEach(themeManager.themes, id: \.id) { theme in
                        Button(action: {
                            themeManager.setTheme(id: theme.id)
                        }) {
                            ThemeRowView(theme: theme, isSelected: theme.id == themeManager.currentTheme.id)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .background(themeManager.currentTheme.background.ignoresSafeArea())
            .navigationTitle("Select a Theme")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.currentTheme.accent)
                }
            }
        }
    }
}

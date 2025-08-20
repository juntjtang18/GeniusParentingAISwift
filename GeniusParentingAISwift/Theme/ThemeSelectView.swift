import SwiftUI

struct ThemeSelectView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            // The VStack provides a clear layout container for the List
            VStack {
                List {
                    // The ForEach loop is now much simpler
                    ForEach(themeManager.themes, id: \.id) { theme in
                        Button(action: {
                            // Correctly pass the whole theme object
                            themeManager.setTheme(theme)
                        }) {
                            // Use the new helper view and safely check the current theme
                            ThemeRowView(
                                theme: theme,
                                isSelected: theme.id == themeManager.currentTheme.id
                            )
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            // Use the theme from the environment for the background
            .background(themeManager.currentTheme.background.ignoresSafeArea())
            .navigationTitle("Select a Theme")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(themeManager.currentTheme.accent)
                }
            }
        }
    }
}

struct ThemeRowView: View {
    let theme: Theme
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text(theme.id)
                    .font(.headline)
                    .foregroundColor(theme.foreground)
                
                // Color swatches to preview the theme
                HStack(spacing: 12) {
                    Circle().fill(theme.primary).frame(width: 22, height: 22)
                    Circle().fill(theme.primaryText).frame(width: 22, height: 22)
                    Circle().fill(theme.accent).frame(width: 22, height: 22)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(theme.accent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(theme.background.opacity(0.4))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.accent, lineWidth: isSelected ? 2 : 0)
        )
    }
}

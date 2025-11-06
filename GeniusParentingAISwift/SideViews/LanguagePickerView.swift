//
//  LanguagePickerView.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/11/4.
//

import Foundation
import SwiftUI

struct LanguagePickerView: View {
    @Binding var isPresented: Bool

    // Single source of truth (persisted)
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    // Local view state to ensure we show the *current* stored value on first render
    @State private var currentLanguage: String = "en"

    private struct Option: Identifiable {
        let id: String
        let title: String
    }

    private let options: [Option] = [
        .init(id: "en",     title: "English"),
        .init(id: "zh_CN",  title: "中文（简体）")
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(options) { option in
                    Button {
                        // Update storage and local state
                        appLanguage = option.id
                        currentLanguage = option.id
                        isPresented = false
                    } label: {
                        HStack {
                            Text(option.title)
                            Spacer()
                            if currentLanguage == option.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle(String(localized: "Select Language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        // ✅ Read the saved value before showing the list
        .onAppear {
            currentLanguage = appLanguage
            // (Optional) debug print to verify
            print("LanguagePickerView initial read from AppStorage: \(currentLanguage)")
        }
    }
}

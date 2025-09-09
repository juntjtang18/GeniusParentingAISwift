//
//  ReportFormView.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/9/9.
//


// ReportFormView.swift
import SwiftUI

struct ReportFormView: View {
    @Environment(\.theme) private var currentTheme: Theme
    let title: String                    // e.g. "Report Comment"
    let subject: String                  // e.g. "by @username"
    let onCancel: () -> Void
    let onSubmit: (_ reason: ModerationReason, _ details: String?) -> Void

    @State private var reason: ModerationReason = .spam
    @State private var details: String = ""
    @State private var isSubmitting = false
    @FocusState private var focusDetails: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reason")) {
                    Picker("Reason", selection: $reason) {
                        ForEach(ModerationReason.allCases, id: \.self) { r in
                            Text(label(for: r)).tag(r)
                        }
                    }
                }

                Section(header: Text("Details (optional)")) {
                    TextEditor(text: $details)
                        .frame(minHeight: 96)
                        .foregroundColor(currentTheme.inputBoxForeground)
                        .background(currentTheme.inputBoxBackground)
                        .focused($focusDetails)
                        .submitLabel(.done)
                }

                Section {
                    Button {
                        isSubmitting = true
                        onSubmit(reason, details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : details)
                        // isSubmitting is reset by caller closing the sheet
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Label("Submit Report", systemImage: "paperplane.fill")
                        }
                    }
                    .foregroundColor(currentTheme.accent)
                    .background(currentTheme.accentBackground)
                    .disabled(isSubmitting)
                    //.buttonStyle(.borderedProminent)

                    Button(role: .cancel) {
                        onCancel()
                    } label: {
                        Label("Cancel", systemImage: "xmark.circle")
                    }
                    .foregroundColor(currentTheme.accent)
                    .background(currentTheme.accentBackground)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { focusDetails = true }
        }
    }

    private func label(for r: ModerationReason) -> String {
        switch r {
        case .spam:        return "Spam"
        case .harassment:  return "Harassment"
        case .hate:        return "Hate"
        case .sexual:      return "Sexual Content"
        case .violence:    return "Violence"
        case .illegal:     return "Illegal Activity"
        case .other:       return "Other"
        }
    }
}

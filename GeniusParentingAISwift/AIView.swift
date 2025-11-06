import SwiftUI
import UIKit

struct AIView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var newMessage: String = ""
    @Environment(\.theme) var currentTheme: Theme
    
    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Input sizing
    private let inputHPad: CGFloat = 14
    private let inputVPad: CGFloat = 10

    private var lineHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .body).lineHeight
    }
    private var minInputHeight: CGFloat { lineHeight + inputVPad * 2 }          // 1 line
    private var maxInputHeight: CGFloat { lineHeight * 4 + inputVPad * 2 }      // 4 lines

    // ✅ Function (not var) — counts hard newlines
    private func hardLineCount(_ text: String) -> Int {
        max(1, text.components(separatedBy: "\n").count)
    }

    // Height is exactly 1–4 lines (grows only on Return)
    private var currentInputHeight: CGFloat {
        let lines = hardLineCount(newMessage)
        return min(maxInputHeight, CGFloat(lines) * lineHeight + inputVPad * 2)
    }
    
    var body: some View {
        ZStack { // 1. Added ZStack as the root for the gradient
            
            LinearGradient(
                colors: [currentTheme.background, currentTheme.background2],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea() // Ensure the gradient fills the entire screen
             
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageView(message: message)
                                    .id(message.id)
                            }
                            Color.clear.frame(height: 1).id("bottomAnchor")
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively) // drag-to-dismiss
                    .onTapGesture { isTextFieldFocused = false } // tap outside to dismiss
                    .onReceive(viewModel.$messages) { _ in
                        DispatchQueue.main.async {
                            withAnimation(.spring()) {
                                proxy.scrollTo("bottomAnchor", anchor: .bottom)
                            }
                        }
                    }
                }

                Spacer()

                // Footer input area (grows upward to 4 lines)
                HStack(alignment: .bottom, spacing: 8) {
                    // --- TEXT FIELD CONTAINER (anchors bottom) ---
                    ZStack(alignment: .leading) {
                        // Placeholder
                        if newMessage.isEmpty {
                            Text("Ask a parenting question...")
                                .foregroundColor(currentTheme.foreground.opacity(0.6))
                                .padding(.horizontal, inputHPad + 2.5)
                                .padding(.vertical, inputVPad - 2)
                                .allowsHitTesting(false)
                        }

                        // Multiline TextField
                        TextField("", text: $newMessage, axis: .vertical)
                            .font(.body)
                            .lineLimit(1...4)                       // auto-grow up to 4 lines
                            .submitLabel(.return)                   // show Return key
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                // Insert newline instead of sending (only grows on hard newlines)
                                let lines = newMessage.components(separatedBy: "\n").count
                                if lines < 4 { newMessage.append("\n"); isTextFieldFocused = true }
                            }
                            .textInputAutocapitalization(.sentences)
                            .disableAutocorrection(false)
                            .foregroundColor(currentTheme.inputBoxForeground)
                            .padding(.vertical, inputVPad)
                            .padding(.horizontal, inputHPad)
                            .fixedSize(horizontal: false, vertical: true) // intrinsic height
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .background(currentTheme.inputBoxBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(currentTheme.border.opacity(0.6), lineWidth: 1)
                    )
                    .frame(height: currentInputHeight, alignment: .bottom)  // ✅ exact 1–4 line height

                    // --- SEND BUTTON ---
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: minInputHeight, height: minInputHeight) // single-line size
                            .foregroundColor(
                                newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .gray : currentTheme.foreground
                            )
                    }
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isAwaitingResponse)
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .padding(.bottom, 6)
                //.background(currentTheme.background)
            }
        } // End of ZStack
        .toolbar { // keyboard accessory: hide keyboard
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    isTextFieldFocused = false
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .imageScale(.large)
                        .accessibilityLabel(String(localized: "Hide Keyboard"))
                }
                // Commented out the tint customization for the keyboard accessory toolbar button
                // .tint(currentTheme.accent)
            }
        }
        .onAppear {
            if viewModel.messages.isEmpty {
                let greeting = ChatMessage(
                    content: String(localized: "Hello! How can I help you with your parenting questions today?"),
                    isUser: false
                )
                viewModel.messages.append(greeting)
            }
        }
    }

    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        viewModel.sendMessage(text: trimmedMessage)
        newMessage = ""
        isTextFieldFocused = false
    }
}

// The MessageView and RoundedCorner extensions remain unchanged.
struct MessageView: View {
    @Environment(\.theme) var currentTheme: Theme // Access theme within MessageView
    let message: ChatMessage
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !message.isUser {
                Image("chatbot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(UIColor.systemGray4), lineWidth: 1))
                Text(message.content)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(Color(UIColor.label))
                    .cornerRadius(18, corners: [.topLeft, .topRight, .bottomRight])
                Spacer(minLength: 10)
            } else {
                Spacer(minLength: 10)
                Text(message.content)
                    .font(.subheadline)
                    .padding(12)
                    .background(currentTheme.accentBackground) // Changed background for user messages
                    .foregroundColor(currentTheme.accent)      // Changed foreground for user messages
                    .cornerRadius(18, corners: [.topLeft, .topRight, .bottomLeft])
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 35))
                    .foregroundColor(Color(UIColor.systemGray3))
            }
        }
        .padding(.horizontal, 4)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

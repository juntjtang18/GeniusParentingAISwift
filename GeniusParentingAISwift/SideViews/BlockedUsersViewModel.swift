//
//  BlockedUsersViewModel.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/9/9.
//


// BlockedUsersView.swift
import SwiftUI

@MainActor
final class BlockedUsersViewModel: ObservableObject {
    @Published var blocks: [BlockedUser] = []
    @Published var loading = false
    @Published var error: String?

    func load() async {
        loading = true; error = nil
        defer { loading = false }
        do {
            blocks = try await ModerationService.shared.fetchMyBlocks()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func unblock(_ user: BlockedUser) async {
        error = nil
        do {
            _ = try await ModerationService.shared.unblockUser(userId: user.id)
            // Optimistically remove from list
            blocks.removeAll { $0.id == user.id }
            RefreshCoordinator.shared.markCommunityNeedsRefresh()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct BlockedUsersView: View {
    @StateObject private var vm = BlockedUsersViewModel()
    @State private var confirmUnblock: BlockedUser?
    @State private var showingToast = false

    var body: some View {
        List {
            if let error = vm.error {
                Section {
                    Text(error).foregroundColor(.red)
                }
            }

            if vm.blocks.isEmpty && !vm.loading {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("No blocked users")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
                }
            } else {
                ForEach(vm.blocks) { user in
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                        Text("@\(user.username)")
                            .font(.body)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            confirmUnblock = user
                        } label: {
                            Label("Unblock", systemImage: "person.crop.circle.badge.checkmark")
                        }
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .confirmationDialog(
            "Unblock @\(confirmUnblock?.username ?? "")?",
            isPresented: Binding(get: { confirmUnblock != nil }, set: { if !$0 { confirmUnblock = nil } }),
            titleVisibility: .visible
        ) {
            Button("Unblock", role: .destructive) {
                guard let user = confirmUnblock else { return }
                Task {
                    await vm.unblock(user)
                    confirmUnblock = nil
                    //RefreshCoordinator.shared.markCommunityNeedsRefresh()
                    showToast()
                }
            }
            Button("Cancel", role: .cancel) { confirmUnblock = nil }
        }
        .overlay(alignment: .bottom) {
            if showingToast {
                Text("User unblocked")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.green.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func showToast() {
        withAnimation { showingToast = true }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation { showingToast = false }
        }
    }
}

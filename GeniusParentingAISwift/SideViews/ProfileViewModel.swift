// GeniusParentingAISwift/SideViews/ProfileViewModel.swift
import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {}

    var user: StrapiUser? {
        get {
            guard let userId = SessionManager.shared.currentUser?.id else { return nil }
            return SessionStore.shared.getUserData("user", userId: userId)
        }
        set {
            if let userToSave = newValue {
                SessionManager.shared.setCurrentUser(userToSave)
            }
        }
    }

    func fetchUserProfile() async {
        isLoading = true
        errorMessage = nil

        guard var baseUser = SessionManager.shared.currentUser else {
            errorMessage = "No active user session."
            isLoading = false
            return
        }

        do {
            let apiResponse = try await StrapiService.shared.fetchUserProfile()
            
            print("API Response: \(apiResponse)")
            let decodedData = apiResponse.data
            
            let userProfile = UserProfile(
                id: decodedData.id,
                locale: decodedData.attributes.locale,
                consentForEmailNotice: decodedData.attributes.consentForEmailNotice,
                children: decodedData.attributes.children,
                users_permissions_user: nil
            )
            
            baseUser.user_profile = userProfile
            self.user = baseUser
            
        } catch {
            print("Could not fetch user profile details: \(error.localizedDescription)")
            errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    func updateUserAndProfile(userId: Int, username: String, profileId: Int, consent: Bool, children: [EditableChild]) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            guard let currentUser = SessionManager.shared.currentUser else {
                errorMessage = "No active user session."
                isLoading = false
                return false
            }

            if username != currentUser.username && userId != 0 {
                let userPayload = UserUpdatePayload(username: username)
                _ = try await StrapiService.shared.updateUserAccount(userId: userId, payload: userPayload)
            }
            
            let childrenPayload = children.map { ChildPayload(id: $0.serverId, name: $0.name, age: $0.age, gender: $0.gender) }
            let profileData = ProfileUpdateData(consentForEmailNotice: consent, children: childrenPayload)
            let profilePayload = ProfileUpdatePayload(data: profileData)
            _ = try await StrapiService.shared.updateUserProfile(payload: profilePayload)
            
            await fetchUserProfile()
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Failed to save profile changes: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}

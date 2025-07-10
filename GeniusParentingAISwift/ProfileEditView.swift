// GeniusParentingAISwift/ProfileEditView.swift

import SwiftUI

/// A local struct to manage the state of children in the edit view.
struct EditableChild: Identifiable {
    let id: UUID = UUID()
    var serverId: Int?
    var name: String
    var age: Int
    var gender: String
}

struct ProfileEditView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ProfileViewModel

    // Local state for editable fields
    @State private var editableUsername: String
    @State private var editableConsent: Bool
    @State private var editableChildren: [EditableChild] = []
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let userId: Int
    private let userProfileId: Int

    init(isPresented: Binding<Bool>, viewModel: ProfileViewModel) {
        self._isPresented = isPresented
        self.viewModel = viewModel
        
        self.userId = viewModel.user?.id ?? 0
        self._editableUsername = State(initialValue: viewModel.user?.username ?? "")
        
        if let profile = viewModel.user?.user_profile {
            self.userProfileId = profile.id
            self._editableConsent = State(initialValue: profile.consentForEmailNotice)
            _editableChildren = State(initialValue: (profile.children ?? []).map { child in
                EditableChild(serverId: child.id, name: child.name, age: child.age, gender: child.gender)
            })
        } else {
            self.userProfileId = 0
            self._editableConsent = State(initialValue: false)
            self.errorMessage = "Could not load profile to edit."
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User Name")) {
                    TextField("Username", text: $editableUsername)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Preferences")) {
                    Toggle("Email Notifications", isOn: $editableConsent)
                }

                Section(header: Text("Family Information")) {
                    ForEach($editableChildren) { $child in
                        ChildEditRow(child: $child)
                    }
                    .onDelete(perform: deleteChild)

                    Button(action: addChild) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Child")
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: saveButton
            )
        }
    }

    private var saveButton: some View {
        Button(action: {
            Task { await saveChanges() }
        }) {
            if isSaving {
                ProgressView()
            } else {
                Text("Save")
            }
        }
        .disabled(isSaving)
    }

    private func addChild() {
        editableChildren.append(EditableChild(serverId: nil, name: "", age: 0, gender: "male"))
    }

    private func deleteChild(at offsets: IndexSet) {
        editableChildren.remove(atOffsets: offsets)
    }

    private func saveChanges() async {
        guard userProfileId != 0 else {
            self.errorMessage = "Cannot save: Profile ID is missing."
            return
        }
        
        isSaving = true
        self.errorMessage = nil

        let success = await viewModel.updateUserAndProfile(
            userId: self.userId,
            username: self.editableUsername,
            profileId: self.userProfileId,
            consent: self.editableConsent,
            children: self.editableChildren
        )

        isSaving = false
        if success {
            isPresented = false
        } else {
            self.errorMessage = viewModel.errorMessage ?? "An unknown error occurred."
        }
    }
}

struct ChildEditRow: View {
    @Binding var child: EditableChild

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Child's Name", text: $child.name)
            
            HStack {
                Text("Age:")
                TextField("", value: $child.age, formatter: NumberFormatter())
                   .keyboardType(.numberPad)
            }
            
            Picker("Gender", selection: $child.gender) {
                Text("Male").tag("male")
                Text("Female").tag("female")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.vertical, 5)
    }
}

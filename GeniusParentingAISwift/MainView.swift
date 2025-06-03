//
//  MainView.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/6/1.
//

import Foundation
import SwiftUI
import KeychainAccess

struct MainView: View {
    var body: some View {
        VStack {
            Text("Welcome to GeniusParentingSwift!")
                .font(.title)
                .padding()
            Button("Logout") {
                // Clear JWT and navigate back to login
                let keychain = Keychain(service: "com.yourcompany.GeniusParentingAISwift")
                keychain["jwt"] = nil
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .navigationTitle("Home")
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

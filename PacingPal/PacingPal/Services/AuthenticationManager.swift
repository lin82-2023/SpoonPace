// PacingPal
// AuthenticationManager.swift
// Sign in with Apple 管理

import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
@Observable
final class AuthenticationManager {
    nonisolated static let shared: AuthenticationManager = MainActor.assumeIsolated {
        AuthenticationManager()
    }

    private(set) var isAuthenticated = false
    private(set) var userID: String?

    init() {
        // Check if we have a saved user ID
        if let saved = UserDefaults.standard.string(forKey: "AppleUserID") {
            userID = saved
            isAuthenticated = true
        }
    }

    func handleCredential(_ credential: ASAuthorizationAppleIDCredential) {
        userID = credential.user
        isAuthenticated = true
        UserDefaults.standard.set(credential.user, forKey: "AppleUserID")

        if let email = credential.email {
            UserDefaults.standard.set(email, forKey: "AppleUserEmail")
        }
    }

    func signOut() {
        userID = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "AppleUserID")
        UserDefaults.standard.removeObject(forKey: "AppleUserEmail")
    }
}

extension EnvironmentValues {
    @Entry var authenticationManager: AuthenticationManager = .shared
}

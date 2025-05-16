//
//  MagicPicturingApp.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

@main
struct MagicPicturingApp: App {
    // Initialize shared view models
    @StateObject private var userPreferences = UserPreferences()
    @StateObject private var photoLibraryViewModel = PhotoLibraryViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(userPreferences)
                .environmentObject(photoLibraryViewModel)
                .preferredColorScheme(.dark)
        }
    }
}

//
//  UserPreferences.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import Foundation
import SwiftUI
import Combine

class UserPreferences: ObservableObject {
    // Published properties for user settings
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: Keys.isDarkMode.rawValue)
        }
    }
    
    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: Keys.language.rawValue)
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled.rawValue)
        }
    }
    
    @Published var cacheSize: Int {
        didSet {
            UserDefaults.standard.set(cacheSize, forKey: Keys.cacheSize.rawValue)
        }
    }
    
    // Keys for UserDefaults
    enum Keys: String {
        case isDarkMode
        case language
        case notificationsEnabled
        case cacheSize
    }
    
    // Initialize with values from UserDefaults or defaults
    init() {
        // Fix for optional boolean comparison issue as mentioned in memory
        self.isDarkMode = UserDefaults.standard.object(forKey: Keys.isDarkMode.rawValue) == nil ? 
            true : UserDefaults.standard.bool(forKey: Keys.isDarkMode.rawValue)
        
        self.language = UserDefaults.standard.string(forKey: Keys.language.rawValue) ?? "简体中文"
        
        self.notificationsEnabled = UserDefaults.standard.object(forKey: Keys.notificationsEnabled.rawValue) == nil ?
            true : UserDefaults.standard.bool(forKey: Keys.notificationsEnabled.rawValue)
        
        self.cacheSize = UserDefaults.standard.integer(forKey: Keys.cacheSize.rawValue)
        if self.cacheSize == 0 {
            self.cacheSize = 256 // Default cache size in MB
        }
    }
    
    // Reset all preferences to default values
    func resetToDefaults() {
        isDarkMode = true
        language = "简体中文"
        notificationsEnabled = true
        cacheSize = 256
    }
    
    // Clear cache
    func clearCache() {
        // Implementation would depend on how cache is managed
        print("Cache cleared")
    }
}

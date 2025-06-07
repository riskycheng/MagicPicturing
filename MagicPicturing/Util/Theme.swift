import SwiftUI

struct Theme {
    struct Colors {
        static let primary = Color.blue
        static let primaryButtonText = Color.white
        
        static let background = Color(red: 0.98, green: 0.98, blue: 0.99)
        static let placeholderBackground = Color.gray.opacity(0.1)
        static let placeholderStroke = Color.gray.opacity(0.4)
        
        static let textPrimary = Color.black
        static let textSecondary = Color.gray
        
        static let success = Color.green
        static let error = Color.red
    }
    
    struct Fonts {
        static let navigationTitle = Font.system(size: 18, weight: .semibold)
        static let button = Font.system(size: 16, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 14, weight: .regular)
        static let smallCaption = Font.system(size: 12, weight: .medium)
    }
    
    struct Metrics {
        static let cornerRadius: CGFloat = 12
        static let buttonHeight: CGFloat = 50
        static let horizontalPadding: CGFloat = 20
        static let verticalSpacing: CGFloat = 20
    }
} 
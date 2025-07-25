import SwiftUI

enum IndicatorComponent {
    case logo
    case text
}

// Using an enum for templates ensures type safety and makes it easy to manage all available styles.
enum WatermarkTemplate: String, CaseIterable, Identifiable {
    case classic = "经典之框"
    case modern = "现代之框"
    case film = "电影之框"
    case minimalist = "极简风格"
    case tech = "科技风格"
    
    var id: String { self.rawValue }

    var indicatorLayout: [IndicatorComponent] {
        switch self {
        case .classic, .tech:
            return [.text, .logo, .text]
        case .modern:
            return [.logo, .text]
        case .film:
            return [.text, .logo]
        case .minimalist:
            return [.logo]

        }
    }

    var name: String {
        switch self {
        case .classic: return "Classic"
        case .modern: return "Modern"
        case .film: return "Film"
        case .minimalist: return "Minimalist"
        case .tech: return "Tech"
        }
    }
    
    // This ViewBuilder returns the appropriate SwiftUI view for each template.
    // This is the core of the template-switching logic.
    @ViewBuilder
    func makeView(watermarkInfo: WatermarkInfo, width: CGFloat) -> some View {
        switch self {
        case .classic:
            return AnyView(ClassicWatermarkView(watermarkInfo: watermarkInfo, width: width))
        case .modern:
            return AnyView(ModernWatermarkView(watermarkInfo: watermarkInfo, width: width))
        case .film:
            return AnyView(FilmWatermarkView(watermarkInfo: watermarkInfo, width: width))
        case .minimalist:
            return AnyView(MinimalistWatermarkView(watermarkInfo: watermarkInfo, width: width))
        case .tech:
            return AnyView(TechWatermarkView(watermarkInfo: watermarkInfo, width: width))
        }
    }
} 
import SwiftUI

// Using an enum for templates ensures type safety and makes it easy to manage all available styles.
enum WatermarkTemplate: String, CaseIterable, Identifiable {
    case classic = "经典之框"
    case modern = "现代之框"
    case film = "电影之框"
    
    var id: String { self.rawValue }
    
    // This ViewBuilder returns the appropriate SwiftUI view for each template.
    // This is the core of the template-switching logic.
    @ViewBuilder
    func makeView(image: UIImage, watermarkInfo: WatermarkInfo) -> some View {
        switch self {
        case .classic:
            ClassicWatermarkView(image: image, watermarkInfo: watermarkInfo)
        case .modern:
            ModernWatermarkView(image: image, watermarkInfo: watermarkInfo)
        case .film:
            FilmWatermarkView(image: image, watermarkInfo: watermarkInfo)
        }
    }
} 
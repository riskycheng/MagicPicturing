import SwiftUI

// Using an enum for templates ensures type safety and makes it easy to manage all available styles.
enum WatermarkTemplate: String, CaseIterable, Identifiable {
    case classic = "经典之框"
    case modern = "现代之框"
    case film = "电影之框"
    case minimalist = "极简风格"
    case vintage = "复古风格"
    case magazine = "杂志风格"
    case artistic = "艺术风格"
    case tech = "科技风格"
    case natural = "自然风格"
    
    var id: String { self.rawValue }
    
    // This ViewBuilder returns the appropriate SwiftUI view for each template.
    // This is the core of the template-switching logic.
    @ViewBuilder
    func makeView(image: UIImage, watermarkInfo: WatermarkInfo, isPreview: Bool = false) -> some View {
        switch self {
        case .classic:
            ClassicWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview)
        case .modern:
            ModernWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview)
        case .film:
            FilmWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview)
        case .minimalist:
            MinimalistWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview)
        case .vintage:
            VintageWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview)
        case .magazine:
            MagazineWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview)
        case .artistic:
            ArtisticWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview)
        case .tech:
            TechWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview)
        case .natural:
            NaturalWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview)
        }
    }
} 
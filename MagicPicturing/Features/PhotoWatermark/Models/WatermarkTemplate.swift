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
    func makeView(image: UIImage, watermarkInfo: WatermarkInfo, isPreview: Bool, width: CGFloat) -> some View {
        switch self {
        case .classic:
            return AnyView(ClassicWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview, width: width))
        case .modern:
            return AnyView(ModernWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview, width: width))
        case .film:
            return AnyView(FilmWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview, width: width))
        case .minimalist:
            return AnyView(MinimalistWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview, width: width))
        case .vintage:
            // Assuming VintageWatermarkView and others will be updated to accept width
            return AnyView(VintageWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview, width: width))
        case .magazine:
            return AnyView(MagazineWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview, width: width))
        case .artistic:
            return AnyView(ArtisticWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview, width: width))
        case .tech:
            return AnyView(TechWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview, width: width))
        case .natural:
            return AnyView(NaturalWatermarkView(image: image, watermarkInfo: watermarkInfo, isPreview: isPreview, width: width))
        }
    }
} 
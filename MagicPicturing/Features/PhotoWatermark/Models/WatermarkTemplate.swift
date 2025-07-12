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
        case .vintage:
            return AnyView(VintageWatermarkView(watermarkInfo: watermarkInfo, width: width))
        case .magazine:
            return AnyView(MagazineWatermarkView(watermarkInfo: watermarkInfo, width: width))
        case .tech:
            return AnyView(TechWatermarkView(watermarkInfo: watermarkInfo, width: width))
        case .artistic:
            return AnyView(ArtisticWatermarkView(watermarkInfo: watermarkInfo, width: width))
        case .natural:
            return AnyView(NaturalWatermarkView(watermarkInfo: watermarkInfo, width: width))
        }
    }
} 
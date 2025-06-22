import SwiftUI
import Combine

/// Represents the editable state of a single image within the collage.
class CollageImageState: Identifiable, ObservableObject {
    let id = UUID()
    let assetId: String

    // The actual image data, published so views can update when a higher-res version loads.
    @Published var image: UIImage
    
    // Transform properties
    @Published var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var rotation: Angle = .zero
    @Published var isFlippedHorizontally: Bool = false
    @Published var isFlippedVertically: Bool = false

    init(image: UIImage, assetId: String) {
        self.image = image
        self.assetId = assetId
    }
} 
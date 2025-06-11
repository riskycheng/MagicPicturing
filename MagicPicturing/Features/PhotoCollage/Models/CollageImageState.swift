import SwiftUI

/// Represents the editable state of a single image within the collage.
struct CollageImageState: Identifiable {
    let id = UUID()
    
    /// The zoom level of the image.
    var scale: CGFloat = 1.0
    
    /// The offset of the image within its frame.
    var offset: CGSize = .zero
    
    /// The rotation angle of the image.
    var rotation: Angle = .zero
    
    /// Indicates if the image is flipped horizontally.
    var isFlippedHorizontally: Bool = false
    
    /// Indicates if the image is flipped vertically.
    var isFlippedVertically: Bool = false
} 
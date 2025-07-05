import Foundation

/// A struct to hold the EXIF data extracted from a photo.
struct WatermarkInfo: Identifiable, Equatable {
    let id = UUID()
    
    // Camera and Lens
    var cameraMake: String?
    var cameraModel: String?
    var lensModel: String?
    
    // Shot details
    var focalLength: String?
    var aperture: String?
    var shutterSpeed: String?
    var iso: String?
    
    // Location and Time
    var location: String?
    var creationDate: String?
    var weather: String? // For future implementation
    
    // Custom text
    var customText: String?
    
    static func == (lhs: WatermarkInfo, rhs: WatermarkInfo) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Provides a placeholder for previews and testing.
    static var placeholder: WatermarkInfo {
        WatermarkInfo(
            cameraMake: "Apple",
            cameraModel: "iPhone 16 Pro",
            lensModel: "iPhone 16 Pro back camera 4.2mm f/1.7",
            focalLength: "24mm",
            aperture: "f/1.8",
            shutterSpeed: "1/120s",
            iso: "ISO 100",
            location: "Cupertino, CA",
            creationDate: "2024-10-27"
        )
    }
} 
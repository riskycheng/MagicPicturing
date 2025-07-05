import Foundation
import ImageIO
import CoreLocation
import UIKit

class EXIFService {
    
    /// Extracts EXIF and other metadata from an image.
    /// - Parameter image: The UIImage to process.
    /// - Returns: A `WatermarkInfo` struct populated with the extracted data.
    func extractWatermarkInfo(from image: UIImage) -> WatermarkInfo {
        var info = WatermarkInfo()
        
        guard let imageData = image.cgImage?.dataProvider?.data,
              let source = CGImageSourceCreateWithData(imageData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return info
        }
        
        // Extract TIFF properties (camera model, make)
        if let tiffDict = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            info.cameraMake = tiffDict[kCGImagePropertyTIFFMake as String] as? String
            info.cameraModel = tiffDict[kCGImagePropertyTIFFModel as String] as? String
        }
        
        // Extract Exif properties (shot details)
        if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let aperture = exifDict[kCGImagePropertyExifFNumber as String] as? Double {
                info.aperture = String(format: "f/%.1f", aperture)
            }
            if let shutter = exifDict[kCGImagePropertyExifExposureTime as String] as? Double {
                info.shutterSpeed = formatShutterSpeed(shutter)
            }
            if let isoArray = exifDict[kCGImagePropertyExifISOSpeedRatings as String] as? [Int], let iso = isoArray.first {
                info.iso = "ISO \(iso)"
            }
            if let focalLength = exifDict[kCGImagePropertyExifFocalLength as String] as? Double {
                info.focalLength = "\(Int(round(focalLength)))mm"
            }
            info.lensModel = exifDict[kCGImagePropertyExifLensModel as String] as? String
            
            if let creationDate = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                info.creationDate = formatDate(creationDate)
            }
        }

        return info
    }
    
    // MARK: - Helper Formatting Functions
    
    private func formatShutterSpeed(_ speed: Double) -> String {
        if speed < 1.0 {
            return "1/\(Int(round(1.0/speed)))s"
        } else {
            return "\(speed)s"
        }
    }
    
    private func formatDate(_ dateString: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .long
        outputFormatter.timeStyle = .none
        return outputFormatter.string(from: date)
    }
} 
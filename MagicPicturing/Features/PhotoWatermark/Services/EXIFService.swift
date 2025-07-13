import Foundation
import ImageIO
import CoreLocation
import UIKit

class EXIFService {
    
    /// Extracts EXIF and other metadata from an image.
    /// - Parameter image: The UIImage to process.
    /// - Returns: A `WatermarkInfo` struct populated with the extracted data.
    /// Extracts EXIF and other metadata from raw image data.
    /// - Parameter data: The raw `Data` of the image.
    /// - Returns: A `WatermarkInfo` struct populated with the extracted data.
    func extractWatermarkInfo(from data: Data) -> WatermarkInfo {
        print("EXIFService: Starting metadata extraction from Data.")
        var info = WatermarkInfo()

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            print("EXIFService: Failed to create image source from data.")
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

        // Clean up lens model if it contains the camera model
        if let cameraModel = info.cameraModel, let lensModel = info.lensModel, lensModel.contains(cameraModel) {
            info.lensModel = lensModel.replacingOccurrences(of: cameraModel, with: "").trimmingCharacters(in: .whitespaces)
        }

        print("EXIFService: Extracted info from Data: \(info)")
        return info
    }

    /// Extracts EXIF and other metadata from an image.
    /// - Parameter image: The UIImage to process.
    /// - Returns: A `WatermarkInfo` struct populated with the extracted data.
    func extractWatermarkInfo(from image: UIImage) -> WatermarkInfo {
        print("EXIFService: Starting metadata extraction.")
        var info = WatermarkInfo()
        
        guard let imageData = image.cgImage?.dataProvider?.data,
              let source = CGImageSourceCreateWithData(imageData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            print("EXIFService: Failed to get image properties from data. The data might be corrupted or not a valid image format.")
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

        // Clean up lens model if it contains the camera model
        if let cameraModel = info.cameraModel, let lensModel = info.lensModel, lensModel.contains(cameraModel) {
            info.lensModel = lensModel.replacingOccurrences(of: cameraModel, with: "").trimmingCharacters(in: .whitespaces)
        }

        print("EXIFService: Extracted info from UIImage: \(info)")
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
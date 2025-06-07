//
//  PersonSegmentationService.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/18.
//

import Foundation
import UIKit
import Vision
import CoreImage

/// Protocol defining the contract for person segmentation services
protocol PersonSegmentationServiceProtocol {
    /// Segments a person from the provided image
    /// - Parameter image: The source image containing a person
    /// - Returns: A new image with the person segmented (transparent background)
    func segmentPerson(from image: PlatformImage) async throws -> PlatformImage
}

/// Service responsible for person segmentation using Vision framework
class PersonSegmentationService: PersonSegmentationServiceProtocol {
    
    enum PersonSegmentationError: Error, LocalizedError {
        case invalidImage
        case noSegmentationMask
        case graphicsContextCreationFailed
        case maskDataAccessFailed
        case contextDataAccessFailed
        case resultImageCreationFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not get CGImage from UIImage"
            case .noSegmentationMask:
                return "No segmentation mask generated"
            case .graphicsContextCreationFailed:
                return "Failed to create graphics context"
            case .maskDataAccessFailed:
                return "Failed to get mask data"
            case .contextDataAccessFailed:
                return "Failed to get context data"
            case .resultImageCreationFailed:
                return "Failed to create result image"
            }
        }
    }
    
    /// Segments a person from the provided image
    /// - Parameter image: The source image containing a person
    /// - Returns: A new image with the person segmented (transparent background)
    func segmentPerson(from image: PlatformImage) async throws -> PlatformImage {
        print("[PersonSegmentation] Starting person segmentation process")
        return try await withCheckedThrowingContinuation { continuation in
            do {
                print("[PersonSegmentation] Processing image with dimensions: \(image.size.width) x \(image.size.height)")
                let result = try self.processPersonSegmentation(image)
                print("[PersonSegmentation] Successfully completed segmentation")
                continuation.resume(returning: result)
            } catch {
                print("[PersonSegmentation] ERROR: Failed to process segmentation: \(error.localizedDescription)")
                print("[PersonSegmentation] Error details: \(String(describing: error))")
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Processes the person segmentation request
    /// - Parameter image: The source image containing a person
    /// - Returns: A new image with the person segmented (transparent background)
    private func processPersonSegmentation(_ image: PlatformImage) throws -> PlatformImage {
        #if canImport(UIKit)
        print("[PersonSegmentation] Starting processPersonSegmentation")
        
        // 保存原始图像的方向信息，以便后续使用
        let originalOrientation = image.imageOrientation
        print("[PersonSegmentation] Original image orientation: \(originalOrientation.rawValue)")
        
        // 将图像转换为标准方向（up）以便 Vision 框架处理
        // 这一步很重要，因为 Vision 框架在处理时可能会忽略方向信息
        let normalizedImage: UIImage
        if originalOrientation != .up {
            print("[PersonSegmentation] Normalizing image orientation to .up")
            if let cgImage = image.cgImage {
                normalizedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
                print("[PersonSegmentation] Successfully normalized image")
            } else {
                print("[PersonSegmentation] WARNING: Could not get CGImage, using original image")
                normalizedImage = image
            }
        } else {
            print("[PersonSegmentation] Image already in .up orientation")
            normalizedImage = image
        }
        
        guard let cgImage = normalizedImage.cgImage else {
            print("[PersonSegmentation] ERROR: Failed to get CGImage from normalized image")
            throw PersonSegmentationError.invalidImage
        }
        print("[PersonSegmentation] CGImage obtained: \(cgImage.width) x \(cgImage.height)")
        
        // Create a request to segment persons in the image with higher quality
        print("[PersonSegmentation] Creating VNGeneratePersonSegmentationRequest")
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate // Use accurate for better results
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        // Create a request handler
        print("[PersonSegmentation] Creating VNImageRequestHandler")
        do {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            print("[PersonSegmentation] Performing segmentation request")
            try handler.perform([request])
            print("[PersonSegmentation] Request performed successfully")
        } catch {
            print("[PersonSegmentation] ERROR: Vision request failed: \(error.localizedDescription)")
            print("[PersonSegmentation] Error details: \(String(describing: error))")
            throw error
        }
        
        // Get the segmentation mask
        print("[PersonSegmentation] Checking for segmentation results")
        if request.results == nil {
            print("[PersonSegmentation] ERROR: No results returned from segmentation request")
        } else if request.results?.isEmpty ?? true {
            print("[PersonSegmentation] ERROR: Empty results array returned")
        } else {
            print("[PersonSegmentation] Got \(request.results?.count ?? 0) results")
        }
        
        guard let mask = request.results?.first?.pixelBuffer else {
            print("[PersonSegmentation] ERROR: No pixelBuffer in segmentation results")
            throw PersonSegmentationError.noSegmentationMask
        }
        print("[PersonSegmentation] Successfully obtained segmentation mask")
        print("[PersonSegmentation] Mask dimensions: \(CVPixelBufferGetWidth(mask)) x \(CVPixelBufferGetHeight(mask))")
        
        // Check for the FileProvider error
        if let results = request.results, !results.isEmpty {
            print("[PersonSegmentation] Examining result properties")
            let result = results[0]
            let properties = Mirror(reflecting: result).children
            for (label, value) in properties {
                print("[PersonSegmentation] Property: \(label ?? "unknown") = \(value)")
            }
        }
        
        // 创建透明背景图像
        let segmentedImage = try createTransparentBackground(for: cgImage, using: mask)
        
        // 将分割后的图像还原为原始图像的方向
        if let finalCGImage = segmentedImage.cgImage {
            return UIImage(cgImage: finalCGImage, scale: image.scale, orientation: originalOrientation)
        } else {
            return segmentedImage
        }
        #else
        // macOS implementation would go here
        // For now, just return the original image
        return image
        #endif
    }
    
    /// Creates a transparent background by applying the segmentation mask
    /// - Parameters:
    ///   - image: The original image
    ///   - mask: The segmentation mask
    /// - Returns: An image with transparent background where the mask indicates
    private func createTransparentBackground(for image: CGImage, using mask: CVPixelBuffer) throws -> PlatformImage {
        #if canImport(UIKit)
        
        // 1. --- Bounding Box Calculation ---
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        
        guard let maskData = CVPixelBufferGetBaseAddress(mask) else {
            throw PersonSegmentationError.maskDataAccessFailed
        }
        
        let maskWidth = CVPixelBufferGetWidth(mask)
        let maskHeight = CVPixelBufferGetHeight(mask)
        let maskBytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        
        var minX = maskWidth, minY = maskHeight, maxX = -1, maxY = -1
        // Raise the threshold to be stricter about what is considered part of the person, filtering out low-confidence noise from the model.
        let personThresholdForBBox: UInt8 = 192
        
        for y in 0..<maskHeight {
            for x in 0..<maskWidth {
                let maskOffset = y * maskBytesPerRow + x
                if (maskData + maskOffset).load(as: UInt8.self) >= personThresholdForBBox {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }
        
        if maxX < minX || maxY < minY {
            print("[PersonSegmentation] No person found in mask to create a bounding box.")
            throw PersonSegmentationError.noSegmentationMask
        }
        print("----------------------------------------------------")
        print("[DEBUG] Mask Dimensions: \(maskWidth)x\(maskHeight)")
        print("[DEBUG] Calculated Bounding Box: (\(minX), \(minY)) -> (\(maxX), \(maxY))")
        print("----------------------------------------------------")
        
        // 2. --- Create a new canvas with the exact cropped size ---
        let scaleX = Double(image.width) / Double(maskWidth)
        let scaleY = Double(image.height) / Double(maskHeight)
        
        let cropRect = CGRect(
            x: CGFloat(minX) * scaleX,
            y: CGFloat(minY) * scaleY,
            width: CGFloat(maxX - minX + 1) * scaleX,
            height: CGFloat(maxY - minY + 1) * scaleY
        ).integral
        
        let croppedWidth = Int(cropRect.width)
        let croppedHeight = Int(cropRect.height)
        
        print("----------------------------------------------------")
        print("[DEBUG] Original Image Size: \(image.width)x\(image.height)")
        print("[DEBUG] Scaling Factors: x=\(scaleX), y=\(scaleY)")
        print("[DEBUG] Calculated Crop Rect in Image Coords: \(cropRect)")
        print("[DEBUG] Final Cropped Canvas Size: \(croppedWidth)x\(croppedHeight)")
        print("----------------------------------------------------")
        
        if croppedWidth <= 0 || croppedHeight <= 0 {
             throw PersonSegmentationError.noSegmentationMask
        }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * croppedWidth
        let bitsPerComponent = 8
        let bufferSize = bytesPerRow * croppedHeight
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        buffer.initialize(repeating: 0, count: bufferSize)
        defer { buffer.deallocate() }
        
        guard let context = CGContext(data: buffer,
                                      width: croppedWidth,
                                      height: croppedHeight,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw PersonSegmentationError.graphicsContextCreationFailed
        }
        
        // 3. --- Directly render the cropped image ---
        guard let originalImageProvider = image.dataProvider,
              let originalImageData = originalImageProvider.data,
              let originalPixels = CFDataGetBytePtr(originalImageData) else {
            throw PersonSegmentationError.invalidImage
        }
        
        let originalBytesPerRow = image.bytesPerRow
        let originalBytesPerPixel = image.bitsPerPixel / 8
        let highConfidenceThreshold: UInt8 = 220
        let edgeBlendFactor: Double = 1.5

        DispatchQueue.concurrentPerform(iterations: croppedHeight) { y in
            for x in 0..<croppedWidth {
                let sourceX = Int(cropRect.minX) + x
                let sourceY = Int(cropRect.minY) + y

                let maskX = Int(Double(sourceX) / scaleX)
                let maskY = Int(Double(sourceY) / scaleY)
                
                guard maskX >= 0 && maskX < maskWidth && maskY >= 0 && maskY < maskHeight else { continue }
                
                let maskOffset = maskY * maskBytesPerRow + maskX
                let maskValue = (maskData + maskOffset).load(as: UInt8.self)

                if maskValue >= personThresholdForBBox {
                    let sourceOffset = sourceY * originalBytesPerRow + sourceX * originalBytesPerPixel
                    let targetOffset = y * bytesPerRow + x * bytesPerPixel
                    
                    // Copy RGB
                    memcpy(buffer + targetOffset, originalPixels + sourceOffset, 3)
                    
                    // Set Alpha with smoothing at the edges
                    if maskValue >= highConfidenceThreshold {
                        buffer[targetOffset + 3] = 255
                    } else {
                        buffer[targetOffset + 3] = min(255, UInt8(Double(maskValue - personThresholdForBBox) * edgeBlendFactor))
                    }
                }
            }
        }
        
        // 4. --- Create final image ---
        guard let resultCGImage = context.makeImage() else {
            throw PersonSegmentationError.resultImageCreationFailed
        }
        
        let finalImage = UIImage(cgImage: resultCGImage, scale: 1.0, orientation: .up)
        print("----------------------------------------------------")
        print("[DEBUG] Successfully created final UIImage with size: \(finalImage.size.width) x \(finalImage.size.height)")
        print("----------------------------------------------------")
        print("[PersonSegmentation] Final cropped image created with dimensions: \(finalImage.size.width) x \(finalImage.size.height)")
        
        // Trim transparent edges from the final image to correct any mask inaccuracies
        guard let trimmedImage = trim(image: finalImage) else {
            print("[PersonSegmentation] Failed to trim transparent edges, returning original.")
            return finalImage
        }
        
        print("[PersonSegmentation] Final trimmed image has dimensions: \(trimmedImage.size.width) x \(trimmedImage.size.height)")
        return trimmedImage
        #else
        // macOS implementation would go here
        // For now, just return a placeholder
        return NSImage()
        #endif
    }
    
    #if canImport(UIKit)
    private func trim(image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue

        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return nil }
        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        var minX = width, minY = height, maxX = -1, maxY = -1
        
        // Define a threshold to ignore nearly-transparent pixels
        let alphaThreshold: UInt8 = 10

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                // Check alpha channel against the threshold
                if pixelBuffer[offset + 3] > alphaThreshold {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }

        if maxX < minX || maxY < minY {
            // The image is completely transparent.
            return image
        }

        let cropRect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    #endif
}

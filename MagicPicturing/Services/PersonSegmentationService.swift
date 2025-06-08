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
import CoreImage.CIFilterBuiltins

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
        let originalOrientation = image.imageOrientation
        
        let normalizedImage: UIImage
        if originalOrientation != .up {
            if let cgImage = image.cgImage {
                normalizedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
            } else {
                print("[PersonSegmentation] WARNING: Could not get CGImage, using original image")
                normalizedImage = image
            }
        } else {
            normalizedImage = image
        }
        
        guard let cgImage = normalizedImage.cgImage else {
            print("[PersonSegmentation] ERROR: Failed to get CGImage from normalized image")
            throw PersonSegmentationError.invalidImage
        }
        
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        do {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
        } catch {
            print("[PersonSegmentation] ERROR: Vision request failed: \(error.localizedDescription)")
            print("[PersonSegmentation] Error details: \(String(describing: error))")
            throw error
        }
        
        if request.results == nil || request.results?.isEmpty == true {
            print("[PersonSegmentation] ERROR: No results returned from segmentation request")
            throw PersonSegmentationError.noSegmentationMask
        }
        
        guard let mask = request.results?.first?.pixelBuffer else {
            print("[PersonSegmentation] ERROR: No pixelBuffer in segmentation results")
            throw PersonSegmentationError.noSegmentationMask
        }
        
        let segmentedImage = try createTransparentBackground(for: cgImage, using: mask)
        
        if let finalCGImage = segmentedImage.cgImage {
            return UIImage(cgImage: finalCGImage, scale: image.scale, orientation: originalOrientation)
        } else {
            return segmentedImage
        }
        #else
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
        
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        
        guard let maskData = CVPixelBufferGetBaseAddress(mask) else {
            throw PersonSegmentationError.maskDataAccessFailed
        }
        
        let maskWidth = CVPixelBufferGetWidth(mask)
        let maskHeight = CVPixelBufferGetHeight(mask)
        let maskBytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        
        var minX = maskWidth, minY = maskHeight, maxX = -1, maxY = -1
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
            throw PersonSegmentationError.noSegmentationMask
        }
        
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
                    
                    memcpy(buffer + targetOffset, originalPixels + sourceOffset, 3)
                    
                    if maskValue >= highConfidenceThreshold {
                        buffer[targetOffset + 3] = 255
                    } else {
                        buffer[targetOffset + 3] = min(255, UInt8(Double(maskValue - personThresholdForBBox) * edgeBlendFactor))
                    }
                }
            }
        }
        
        guard let resultCGImage = context.makeImage() else {
            throw PersonSegmentationError.resultImageCreationFailed
        }
        
        let finalImage = UIImage(cgImage: resultCGImage, scale: 1.0, orientation: .up)
        
        // Trim transparent edges from the final image to correct any mask inaccuracies
        guard let trimmedImage = trim(image: finalImage) else {
            print("[PersonSegmentation] Failed to trim transparent edges, returning original.")
            return finalImage
        }
        
        print("[PersonSegmentation] Attempting to apply stroke to trimmed image...")
        guard let strokedImage = applyStroke(to: trimmedImage) else {
            print("[PersonSegmentation] WARNING: Failed to apply stroke, returning trimmed image without stroke.")
            return trimmedImage
        }
        
        print("[PersonSegmentation] Successfully applied stroke.")
        return strokedImage
        #else
        return NSImage()
        #endif
    }
    
    #if canImport(UIKit)
    private func applyStroke(to image: UIImage, strokeWidth: CGFloat = 3.0, strokeColor: UIColor = .white) -> UIImage? {
        print("[Stroke] ---- Starting NEW Stroke Process ----")
        guard let originalCIImage = CIImage(image: image) else {
            print("[Stroke] ERROR: Failed to create CIImage from input image.")
            return nil
        }
        print("[Stroke] Step 1: CIImage created successfully.")

        // Step 2: Create a dilated (expanded) version of the image's alpha channel.
        let morphologyFilter = CIFilter.morphologyMaximum()
        morphologyFilter.inputImage = originalCIImage
        morphologyFilter.radius = Float(strokeWidth)
        guard let dilatedAlpha = morphologyFilter.outputImage else {
            print("[Stroke] ERROR: Morphology filter failed to produce output.")
            return nil
        }
        print("[Stroke] Step 2: Dilated alpha mask created.")

        // Step 3: Create a solid color image matching the size of the dilated mask.
        let strokeColorCI = CIColor(color: strokeColor)
        let strokeColorImage = CIImage(color: strokeColorCI).cropped(to: dilatedAlpha.extent)
        print("[Stroke] Step 3: Stroke color image created and cropped.")
        
        // Step 4: Use CISourceInCompositing to "fill" the dilated alpha shape with the stroke color.
        let sourceInFilter = CIFilter.sourceInCompositing()
        sourceInFilter.inputImage = strokeColorImage
        sourceInFilter.backgroundImage = dilatedAlpha
        guard let strokeLayer = sourceInFilter.outputImage else {
            print("[Stroke] ERROR: CISourceInCompositing filter failed.")
            return nil
        }
        print("[Stroke] Step 4: Stroke layer created using CISourceIn.")

        // Step 5: Composite the original image over the stroke layer.
        let compositeFilter = CIFilter.sourceOverCompositing()
        compositeFilter.inputImage = originalCIImage
        compositeFilter.backgroundImage = strokeLayer
        guard let finalCIImage = compositeFilter.outputImage else {
            print("[Stroke] ERROR: Composite filter failed.")
            return nil
        }
        print("[Stroke] Step 5: Final image composited.")

        // Step 6: Render the final image.
        let context = CIContext()
        guard let finalCGImage = context.createCGImage(finalCIImage, from: finalCIImage.extent) else {
            print("[Stroke] ERROR: Failed to render final CGImage.")
            return nil
        }
        print("[Stroke] Step 6: Final CGImage created successfully.")
        print("[Stroke] ---- NEW Stroke Process Finished ----")
        
        return UIImage(cgImage: finalCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

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
        
        let alphaThreshold: UInt8 = 10

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                if pixelBuffer[offset + 3] > alphaThreshold {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }

        if maxX < minX || maxY < minY {
            return image
        }

        let cropRect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    #endif
}

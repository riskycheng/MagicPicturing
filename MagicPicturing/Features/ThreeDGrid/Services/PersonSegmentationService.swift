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
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let result = try self.processPersonSegmentation(image)
                continuation.resume(returning: result)
            } catch {
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
                normalizedImage = image
            }
        } else {
            normalizedImage = image
        }
        
        guard let cgImage = normalizedImage.cgImage else {
            throw PersonSegmentationError.invalidImage
        }
        
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        do {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
        } catch {
            throw error
        }
        
        if request.results == nil || request.results?.isEmpty == true {
            throw PersonSegmentationError.noSegmentationMask
        }
        
        guard let mask = request.results?.first?.pixelBuffer else {
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
                    
                    // Use a hard edge for alpha to produce a crisp silhouette, which is better for stroking.
                    buffer[targetOffset + 3] = 255
                }
            }
        }
        
        guard let resultCGImage = context.makeImage() else {
            throw PersonSegmentationError.resultImageCreationFailed
        }
        
        let finalImage = UIImage(cgImage: resultCGImage, scale: 1.0, orientation: .up)
        
        guard let trimmedImage = trim(image: finalImage) else {
            return finalImage
        }
        
        guard let strokedImage = applyStroke(to: trimmedImage) else {
            return trimmedImage
        }
        
        return strokedImage
        #else
        return NSImage()
        #endif
    }
    
    #if canImport(UIKit)
    private func applyStroke(to image: UIImage) -> UIImage? {
        // Dynamically calculate effect parameters based on image size for visual consistency.
        let referenceDimension = max(image.size.width, image.size.height)
        
        // --- Define parameters relative to the image size for a consistent look ---
        let strokeWidth = max(3.0, referenceDimension * 0.008) // 0.8% of the longest side, with a minimum of 3px
        let shadowBlurRadius = strokeWidth * 0.4 // Further reduced blur for a tighter shadow
        let shadowOffset = CGPoint(x: strokeWidth * 0.3, y: -strokeWidth * 0.3) // Further reduced offset
        let shadowAlpha: CGFloat = 0.5
        
        guard let originalCIImage = CIImage(image: image) else { return nil }

        // 1. Create the dilated shape for the stroke and shadow
        let morphologyFilter = CIFilter.morphologyMaximum()
        morphologyFilter.inputImage = originalCIImage
        morphologyFilter.radius = Float(strokeWidth)
        guard let dilatedShape = morphologyFilter.outputImage else { return nil }

        // 2. Create the white stroke layer
        let whiteColor = CIImage(color: .white)
        let strokeFilter = CIFilter.sourceInCompositing()
        strokeFilter.inputImage = whiteColor
        strokeFilter.backgroundImage = dilatedShape
        guard let whiteStroke = strokeFilter.outputImage else { return nil }

        // 3. Create the shadow layer
        let shadowColor = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: shadowAlpha))
        let shadowShapeFilter = CIFilter.sourceInCompositing()
        shadowShapeFilter.inputImage = shadowColor
        shadowShapeFilter.backgroundImage = dilatedShape
        guard let shadowShape = shadowShapeFilter.outputImage else { return nil }
        
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = shadowShape
        blurFilter.radius = Float(shadowBlurRadius)
        guard let blurredShadow = blurFilter.outputImage else { return nil }

        let transform = CGAffineTransform(translationX: shadowOffset.x, y: shadowOffset.y)
        let offsetShadow = blurredShadow.transformed(by: transform)
        
        // 4. Composite the layers: shadow -> stroke -> original image
        let strokeOverShadowFilter = CIFilter.sourceOverCompositing()
        strokeOverShadowFilter.inputImage = whiteStroke
        strokeOverShadowFilter.backgroundImage = offsetShadow
        guard let strokeWithShadow = strokeOverShadowFilter.outputImage else { return nil }

        let finalCompositeFilter = CIFilter.sourceOverCompositing()
        finalCompositeFilter.inputImage = originalCIImage
        finalCompositeFilter.backgroundImage = strokeWithShadow
        guard let finalCIImage = finalCompositeFilter.outputImage else { return nil }
        
        // 5. Render the final image
        let context = CIContext()
        guard let finalCGImage = context.createCGImage(finalCIImage, from: finalCIImage.extent) else { return nil }
        
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

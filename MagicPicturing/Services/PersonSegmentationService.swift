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
        print("[PersonSegmentation] Starting createTransparentBackground")
        print("[PersonSegmentation] Image dimensions: \(image.width) x \(image.height)")
        print("[PersonSegmentation] Mask dimensions: \(CVPixelBufferGetWidth(mask)) x \(CVPixelBufferGetHeight(mask))")
        
        // 创建位图上下文，支持RGBA透明度
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        print("[PersonSegmentation] Creating bitmap context with dimensions: \(width) x \(height)")
        print("[PersonSegmentation] Bytes per row: \(bytesPerRow), Buffer size: \(bytesPerRow * height)")
        
        // 创建上下文时直接分配内存，减少内存分配次数
        let bufferSize = bytesPerRow * height
        print("[PersonSegmentation] Allocating buffer of size: \(bufferSize) bytes")
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { 
            print("[PersonSegmentation] Deallocating buffer")
            buffer.deallocate() 
        } // 确保内存在函数结束时被释放
        
        // 初始化内存为0（完全透明）
        print("[PersonSegmentation] Initializing buffer to zero (transparent)")
        buffer.initialize(repeating: 0, count: bufferSize)
        
        print("[PersonSegmentation] Creating CGContext")
        guard let context = CGContext(data: buffer,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            print("[PersonSegmentation] ERROR: Failed to create graphics context")
            throw PersonSegmentationError.graphicsContextCreationFailed
        }
        print("[PersonSegmentation] CGContext created successfully")
        
        // 获取原始图像的像素数据
        print("[PersonSegmentation] Accessing original image data")
        guard let originalImageProvider = image.dataProvider else {
            print("[PersonSegmentation] ERROR: Failed to get image data provider")
            throw PersonSegmentationError.invalidImage
        }
        
        guard let originalImageData = originalImageProvider.data else {
            print("[PersonSegmentation] ERROR: Failed to get image data from provider")
            throw PersonSegmentationError.invalidImage
        }
        
        guard let originalPixels = CFDataGetBytePtr(originalImageData) else {
            print("[PersonSegmentation] ERROR: Failed to get byte pointer from image data")
            throw PersonSegmentationError.invalidImage
        }
        
        print("[PersonSegmentation] Successfully accessed original image data")
        
        // 锁定遮罩以便读取
        print("[PersonSegmentation] Locking mask pixel buffer")
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { 
            print("[PersonSegmentation] Unlocking mask pixel buffer")
            CVPixelBufferUnlockBaseAddress(mask, .readOnly) 
        }
        
        // 获取遮罩数据
        print("[PersonSegmentation] Getting mask base address")
        guard let maskData = CVPixelBufferGetBaseAddress(mask) else {
            print("[PersonSegmentation] ERROR: Failed to get mask base address")
            throw PersonSegmentationError.maskDataAccessFailed
        }
        
        // 获取遮罩属性
        let maskWidth = CVPixelBufferGetWidth(mask)
        let maskHeight = CVPixelBufferGetHeight(mask)
        let maskBytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        print("[PersonSegmentation] Mask properties - Width: \(maskWidth), Height: \(maskHeight), BytesPerRow: \(maskBytesPerRow)")
        
        // --- Bounding Box Calculation ---
        var minX = maskWidth, minY = maskHeight, maxX = -1, maxY = -1
        let personThresholdForBBox: UInt8 = 128
        
        for y in 0..<maskHeight {
            for x in 0..<maskWidth {
                let maskOffset = y * maskBytesPerRow + x
                let maskValue = (maskData + maskOffset).load(as: UInt8.self)
                if maskValue >= personThresholdForBBox {
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
        // --- End of Bounding Box Calculation ---
        
        // 计算缩放因子（如果遮罩和图像尺寸不同）
        let scaleX = Double(width) / Double(maskWidth)
        let scaleY = Double(height) / Double(maskHeight)
        print("[PersonSegmentation] Scale factors - X: \(scaleX), Y: \(scaleY)")
        
        // 定义阈值常量
        let personThreshold: UInt8 = 128 // 人物阈值
        let highConfidenceThreshold: UInt8 = 220 // 高置信度阈值
        let edgeBlendFactor: Double = 1.5 // 边缘混合因子
        
        // 获取原始图像的每像素字节数和每行字节数
        let originalBytesPerPixel = image.bitsPerPixel / 8
        let originalBytesPerRow = image.bytesPerRow
        print("[PersonSegmentation] Original image - BytesPerPixel: \(originalBytesPerPixel), BytesPerRow: \(originalBytesPerRow)")
        
        // Try to read a sample pixel to check if data access works
        print("[PersonSegmentation] Testing mask data access...")
        do {
            if maskWidth > 0 && maskHeight > 0 {
                let testOffset = 0 // First pixel
                let testValue = (maskData + testOffset).load(as: UInt8.self)
                print("[PersonSegmentation] Test pixel value: \(testValue)")
            }
        } catch {
            print("[PersonSegmentation] ERROR: Failed to access test pixel: \(error)")
        }
        
        // 使用并行处理提高效率
        print("[PersonSegmentation] Starting pixel processing with concurrent execution")
        DispatchQueue.concurrentPerform(iterations: height) { y in
            for x in 0..<width {
                // 计算遮罩中的对应位置
                let maskX = Int(Double(x) / scaleX)
                let maskY = Int(Double(y) / scaleY)
                
                // 确保在遮罩边界内
                guard maskX >= 0 && maskX < maskWidth && maskY >= 0 && maskY < maskHeight else { continue }
                
                // 获取遮罩值（0-255，255表示人物，0表示背景）
                let maskOffset = maskY * maskBytesPerRow + maskX
                let maskValue = (maskData + maskOffset).load(as: UInt8.self)
                
                // 只处理人物区域（阈值以上的像素）
                if maskValue >= personThreshold {
                    // 计算原始图像中的像素位置
                    let originalOffset = y * originalBytesPerRow + x * originalBytesPerPixel
                    
                    // 计算目标上下文中的像素位置
                    let contextOffset = y * bytesPerRow + x * bytesPerPixel
                    
                    // 复制RGB通道（一次性复制以提高效率）
                    if originalBytesPerPixel >= 3 && bytesPerPixel >= 3 {
                        memcpy(buffer + contextOffset, originalPixels + originalOffset, 3)
                    }
                    
                    // 设置Alpha通道
                    if maskValue >= highConfidenceThreshold {
                        // 完全是人物区域 - 完全不透明
                        buffer[contextOffset + 3] = 255
                    } else {
                        // 边缘区域 - 应用平滑过渡
                        buffer[contextOffset + 3] = min(255, UInt8(Double(maskValue - personThreshold) * edgeBlendFactor))
                    }
                }
                // 如果maskValue < personThreshold，保持完全透明（背景区域）
            }
        }
        print("[PersonSegmentation] Pixel processing completed")
        
        // Create an image from the context
        print("[PersonSegmentation] Creating result image from context")
        guard let resultCGImage = context.makeImage() else {
            print("[PersonSegmentation] ERROR: Failed to create result image from context")
            throw PersonSegmentationError.resultImageCreationFailed
        }
        print("[PersonSegmentation] Result CGImage created successfully")
        
        let cropScaleX = Double(image.width) / Double(maskWidth)
        let cropScaleY = Double(image.height) / Double(maskHeight)
        
        let cropRect = CGRect(
            x: CGFloat(minX) * cropScaleX,
            y: CGFloat(minY) * cropScaleY,
            width: CGFloat(maxX - minX) * cropScaleX,
            height: CGFloat(maxY - minY) * cropScaleY
        ).integral
        
        print("[PersonSegmentation] Cropping to rect: \(cropRect)")
        guard let croppedCGImage = resultCGImage.cropping(to: cropRect) else {
            print("[PersonSegmentation] ERROR: Failed to crop result image.")
            throw PersonSegmentationError.resultImageCreationFailed
        }
        
        // 创建最终结果图像，使用标准方向（up）
        // 在processPersonSegmentation方法中会将其还原为原始图像的方向
        print("[PersonSegmentation] Creating final UIImage with orientation .up")
        let finalImage = UIImage(cgImage: croppedCGImage, scale: 1.0, orientation: .up)
        print("[PersonSegmentation] Final image created successfully with dimensions: \(finalImage.size.width) x \(finalImage.size.height)")
        return finalImage
        #else
        // macOS implementation would go here
        // For now, just return a placeholder
        return NSImage()
        #endif
    }
}

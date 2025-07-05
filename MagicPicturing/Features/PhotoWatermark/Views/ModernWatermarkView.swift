import SwiftUI

/// A modern, stylish watermark template.
struct ModernWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo
    let isPreview: Bool

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()

            // White bottom bar with detailed layout
            HStack(alignment: .center) {
                // Left side: Camera and Lens info
                VStack(alignment: .leading, spacing: isPreview ? 1 : 2) {
                    Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                        .font(.system(size: isPreview ? 8 : 14, weight: .semibold))
                    if let lensModel = watermarkInfo.lensModel, !lensModel.isEmpty {
                        Text(lensModel)
                            .font(.system(size: isPreview ? 5 : 10, weight: .light))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Right side: Logo, shot details, and date
                HStack(alignment: .center, spacing: isPreview ? 4 : 8) {
                    brandLogo
                        .font(.system(size: isPreview ? 14 : 24))
                        .opacity(0.9)
                    
                    VStack(alignment: .leading, spacing: isPreview ? 1 : 2) {
                        Text([watermarkInfo.focalLength, watermarkInfo.aperture, watermarkInfo.shutterSpeed, watermarkInfo.iso]
                                .compactMap { $0 }
                                .joined(separator: " "))
                            .font(.system(size: isPreview ? 8 : 14, weight: .semibold))
                        if let date = watermarkInfo.creationDate {
                            Text(date)
                                .font(.system(size: isPreview ? 5 : 10, weight: .light))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, isPreview ? 8 : 20)
            .padding(.vertical, isPreview ? 5 : 15)
            .background(Color.white)
        }
    }

    /// A view builder for the brand logo.
    @ViewBuilder
    private var brandLogo: some View {
        if let make = watermarkInfo.cameraMake?.lowercased() {
            if make.contains("apple") {
                Image(systemName: "apple.logo")
            } else if make.contains("fujifilm") {
                Text("FUJIFILM")
            } else if make.contains("sony") {
                Text("SONY")
            } else if make.contains("canon") {
                Text("Canon")
            } else {
                Image(systemName: "camera.fill")
            }
        } else {
            Image(systemName: "camera.fill")
        }
    }
} 
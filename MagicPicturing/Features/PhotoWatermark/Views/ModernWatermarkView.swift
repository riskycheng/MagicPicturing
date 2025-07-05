import SwiftUI

/// A modern, stylish watermark template.
struct ModernWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()

            // White bottom bar with detailed layout
            HStack(alignment: .center) {
                // Left side: Camera and Lens info
                VStack(alignment: .leading, spacing: 2) {
                    Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                        .font(.system(size: 14, weight: .semibold))
                    if let lensModel = watermarkInfo.lensModel, !lensModel.isEmpty {
                        Text(lensModel)
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Right side: Logo, shot details, and date
                HStack(alignment: .center, spacing: 8) {
                    brandLogo
                        .font(.system(size: 24))
                        .opacity(0.9)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text([watermarkInfo.focalLength, watermarkInfo.aperture, watermarkInfo.shutterSpeed, watermarkInfo.iso]
                                .compactMap { $0 }
                                .joined(separator: " "))
                            .font(.system(size: 14, weight: .semibold))
                        if let date = watermarkInfo.creationDate {
                            Text(date)
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
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
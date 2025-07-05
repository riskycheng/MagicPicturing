import SwiftUI

/// A classic watermark template that displays EXIF data at the bottom of an image.
struct ClassicWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()

            // Taller, richer white bottom bar for the watermark
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    // Left side: Camera Model and Lens
                    VStack(alignment: .leading, spacing: 2) {
                        Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                            .font(.system(size: 14, weight: .semibold))
                        if let lensModel = watermarkInfo.lensModel, !lensModel.isEmpty {
                            Text(lensModel)
                                .font(.system(size: 10, weight: .light))
                        }
                    }

                    Spacer()

                    // Center: Brand Logo
                    brandLogo
                        .font(.system(size: 22))
                        .opacity(0.8)

                    Spacer()

                    // Right side: Shot details
                    VStack(alignment: .trailing, spacing: 2) {
                        Text([watermarkInfo.focalLength, watermarkInfo.aperture]
                                .compactMap { $0 }
                                .joined(separator: " "))
                            .font(.system(size: 14, weight: .semibold))
                        Text([watermarkInfo.shutterSpeed, watermarkInfo.iso]
                                .compactMap { $0 }
                                .joined(separator: " "))
                            .font(.system(size: 10, weight: .light))
                    }
                }
            }
            .foregroundColor(.black.opacity(0.9))
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
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            } else if make.contains("sony") {
                Text("SONY")
                    .font(.system(size: 14, weight: .bold, design: .default))
            } else if make.contains("canon") {
                Text("Canon")
                    .font(.system(size: 16, weight: .bold, design: .serif))
            } else {
                Image(systemName: "camera.fill")
            }
        } else {
            Image(systemName: "camera.fill")
        }
    }
}

struct ClassicWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        ClassicWatermarkView(
            image: UIImage(named: "beach")!, // Make sure you have a sample image in assets
            watermarkInfo: .placeholder
        )
        .previewLayout(.sizeThatFits)
    }
} 
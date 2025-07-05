import SwiftUI

/// A classic watermark template that displays EXIF data at the bottom of an image.
struct ClassicWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo
    let isPreview: Bool

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()

            // Taller, richer white bottom bar for the watermark
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    // Left side: Camera Model and Lens
                    VStack(alignment: .leading, spacing: isPreview ? 1 : 2) {
                        Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                            .font(.system(size: isPreview ? 8 : 14, weight: .semibold))
                        if let lensModel = watermarkInfo.lensModel, !lensModel.isEmpty {
                            Text(lensModel)
                                .font(.system(size: isPreview ? 5 : 10, weight: .light))
                        }
                    }

                    Spacer()

                    // Center: Brand Logo
                    brandLogo
                        .font(.system(size: isPreview ? 12 : 22))
                        .opacity(0.8)

                    Spacer()

                    // Right side: Shot details
                    VStack(alignment: .trailing, spacing: isPreview ? 1 : 2) {
                        Text([watermarkInfo.focalLength, watermarkInfo.aperture]
                                .compactMap { $0 }
                                .joined(separator: " "))
                            .font(.system(size: isPreview ? 8 : 14, weight: .semibold))
                        Text([watermarkInfo.shutterSpeed, watermarkInfo.iso]
                                .compactMap { $0 }
                                .joined(separator: " "))
                            .font(.system(size: isPreview ? 5 : 10, weight: .light))
                    }
                }
            }
            .foregroundColor(.black.opacity(0.9))
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
                    .font(.system(size: isPreview ? 7 : 12, weight: .bold, design: .monospaced))
            } else if make.contains("sony") {
                Text("SONY")
                    .font(.system(size: isPreview ? 8 : 14, weight: .bold, design: .default))
            } else if make.contains("canon") {
                Text("Canon")
                    .font(.system(size: isPreview ? 9 : 16, weight: .bold, design: .serif))
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
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false
        )
        .previewLayout(.sizeThatFits)
        
        ClassicWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true
        )
        .previewLayout(.fixed(width: 200, height: 150))
    }
} 
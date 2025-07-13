import SwiftUI

/// A modern, stylish watermark template.
struct ModernWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        watermarkBar(width: self.width)
    }

    @ViewBuilder
    private func watermarkBar(width: CGFloat) -> some View {
        let baseFontSize = width * 0.035
        
        HStack(alignment: .center) {
            // Left side: Camera and Lens info
            VStack(alignment: .leading, spacing: baseFontSize * 0.15) {
                Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                    .font(.system(size: baseFontSize, weight: .semibold))
                if let lensModel = watermarkInfo.lensModel, !lensModel.isEmpty {
                    Text(lensModel)
                        .font(.system(size: baseFontSize * 0.7, weight: .light))
                        .foregroundColor(.black.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            Spacer()

            // Right side: Logo, shot details, and date
            HStack(alignment: .center, spacing: baseFontSize * 0.5) {
                brandLogo(size: baseFontSize * 1.5)
                
                VStack(alignment: .leading, spacing: baseFontSize * 0.15) {
                    Text([watermarkInfo.focalLength, watermarkInfo.aperture, watermarkInfo.shutterSpeed, watermarkInfo.iso]
                            .compactMap { $0 }
                            .joined(separator: " "))
                        .font(.system(size: baseFontSize, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    if let date = watermarkInfo.creationDate {
                        Text(date)
                            .font(.system(size: baseFontSize * 0.7, weight: .light))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, baseFontSize * 1.5)
        .padding(.vertical, baseFontSize)
        .background(Color.white)
        .foregroundColor(.black)
    }

    /// A view builder for the brand logo.
    @ViewBuilder
    private func brandLogo(size: CGFloat) -> some View {
        if let make = watermarkInfo.cameraMake?.lowercased() {
            if make.contains("apple") {
                Image(systemName: "apple.logo").font(.system(size: size))
            } else if make.contains("fujifilm") {
                Text("FUJIFILM").font(.custom("Tungsten-Semibold", size: size))
            } else if make.contains("sony") {
                Text("SONY").font(.system(size: size * 0.8, weight: .bold))
            } else if make.contains("canon") {
                Text("Canon").font(.custom("Trajan Pro", size: size * 0.9))
            } else {
                Image(systemName: "camera.fill").font(.system(size: size * 0.9))
            }
        } else {
            Image(systemName: "camera.fill").font(.system(size: size * 0.9))
        }
    }
}

struct ModernWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Image("beach")
                .resizable()
                .scaledToFit()
            ModernWatermarkView(
                watermarkInfo: .placeholder,
                width: 400
            )
        }
        .previewLayout(.sizeThatFits)
        
        Image("beach")
            .resizable()
            .scaledToFit()
            .overlay(
                VStack {
                    Spacer()
                    ModernWatermarkView(
                        watermarkInfo: .placeholder,
                        width: 400
                    )
                }
            )
            .previewLayout(.fixed(width: 400, height: 300))
    }
}
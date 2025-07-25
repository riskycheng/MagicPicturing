import SwiftUI

/// A modern, stylish watermark template.
struct ModernWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let barHeight = geometry.size.width * 0.13
            let baseFontSize = geometry.size.width * 0.035

            HStack(alignment: .center) {
                // Left side: Logo
                brandLogo(size: baseFontSize * 1.8)

                Spacer()

                // Right side: Camera info, shot details, and date
                VStack(alignment: .trailing, spacing: baseFontSize * 0.2) {
                    Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                        .font(.system(size: baseFontSize * 1.1, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text([watermarkInfo.focalLength, watermarkInfo.aperture, watermarkInfo.shutterSpeed, watermarkInfo.iso]
                            .compactMap { $0 }
                            .joined(separator: "   "))
                        .font(.system(size: baseFontSize * 0.9, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.horizontal, baseFontSize * 1.5)
            .frame(height: barHeight)
            .background(Color.white)
            .foregroundColor(.black)
        }
        .frame(width: width, height: width * 0.13)
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
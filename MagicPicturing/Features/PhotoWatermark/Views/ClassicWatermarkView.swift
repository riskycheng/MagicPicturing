import SwiftUI

/// A classic watermark template that displays EXIF data at the bottom of an image.
struct ClassicWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        watermarkBar(width: self.width)
    }

    @ViewBuilder
    private func watermarkBar(width: CGFloat) -> some View {
        let barHeight = width * 0.12
        let baseFontSize = width * 0.045

        HStack(alignment: .center) {
            // Left side: Camera Brand and Model
            HStack(alignment: .firstTextBaseline, spacing: baseFontSize * 0.5) {
                brandLogo(size: baseFontSize * 1.2)

                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 1.5, height: baseFontSize)

                Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                    .font(.system(size: baseFontSize, weight: .semibold))
            }

            Spacer()

            // Right side: Shot details and Date
            VStack(alignment: .trailing, spacing: baseFontSize * 0.15) {
                Text([watermarkInfo.focalLength, watermarkInfo.aperture, watermarkInfo.shutterSpeed, watermarkInfo.iso]
                        .compactMap { $0 }
                        .joined(separator: "   "))
                    .font(.system(size: baseFontSize * 0.75, weight: .medium))

                if let date = watermarkInfo.creationDate {
                    Text(date)
                        .font(.system(size: baseFontSize * 0.65, weight: .light))
                        .foregroundColor(.black.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, width * 0.05)
        .frame(width: width, height: barHeight)
        .background(Color.white)
        .foregroundColor(.black)

    }
    
    /// A view builder for the brand logo.
    @ViewBuilder
    private func brandLogo(size: CGFloat) -> some View {
        if let make = watermarkInfo.cameraMake?.lowercased() {
            if make.contains("apple") {
                Image(systemName: "apple.logo").font(.system(size: size, weight: .semibold))
            } else if make.contains("fujifilm") {
                Text("FUJIFILM").font(.custom("Tungsten-Semibold", size: size))
            } else if make.contains("sony") {
                Text("SONY").font(.system(size: size * 0.8, weight: .bold))
            } else if make.contains("canon") {
                Text("Canon").font(.custom("Trajan Pro", size: size * 0.9))
            } else {
                Image(systemName: "camera.fill").font(.system(size: size * 0.9, weight: .semibold))
            }
        } else {
            Image(systemName: "camera.fill").font(.system(size: size * 0.9, weight: .semibold))
        }
    }
}


struct ClassicWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Image("beach")
                .resizable()
                .scaledToFill()
                .frame(width: 400)
                .clipped()
            ClassicWatermarkView(
                watermarkInfo: .placeholder,
                width: 400
            )
        }
        .previewLayout(.sizeThatFits)
        
        Image("beach")
            .resizable()
            .scaledToFill()
            .frame(width: 400)
            .clipped()
            .overlay(
                VStack {
                    Spacer()
                    ClassicWatermarkView(
                        watermarkInfo: .placeholder,
                        width: 400
                    )
                }
            )
            .previewLayout(.fixed(width: 400, height: 350))
    }
} 
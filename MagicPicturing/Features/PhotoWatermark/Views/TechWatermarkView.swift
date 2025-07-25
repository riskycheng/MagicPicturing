import SwiftUI

/// A futuristic tech-style watermark template.
struct TechWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        let baseFontSize = width * 0.028
        let padding = width * 0.04

        HStack(alignment: .center) {
            // Left: Camera Model
            Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                .font(.system(size: baseFontSize, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            // Center: Logo
            brandLogo(size: baseFontSize * 1.8)

            Spacer()

            // Right: Shot Details
            Text(cameraDetails())
                .font(.system(size: baseFontSize, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundColor(.black)
        .padding(.horizontal, padding)
        .frame(width: width, height: width * 0.13)
        .background(Color.white)
    }

    private func cameraDetails() -> String {
        let allDetails = [
            watermarkInfo.focalLength,
            watermarkInfo.aperture,
            watermarkInfo.shutterSpeed,
            watermarkInfo.iso
        ].compactMap { $0 }

        if allDetails.count <= 2 {
            return allDetails.joined(separator: " | ")
        }

        let primaryDetails = Array(allDetails.prefix(2))
        return primaryDetails.joined(separator: " | ")
    }

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

struct TechCornerView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        let baseFontSize = width * 0.025

        VStack(spacing: baseFontSize * 0.2) {
            Text("⚡")
                .font(.system(size: baseFontSize * 1.5))
            
            Text(watermarkInfo.cameraMake ?? "TECH")
                .font(.system(size: baseFontSize, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, baseFontSize * 1.5)
        .padding(.vertical, baseFontSize)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.cyan, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.3), lineWidth: 0.5))
        .padding([.top, .trailing], width * 0.04)
    }
}

struct TechWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Image("beach")
                .resizable()
                .scaledToFit()
                .overlay(
                    HStack {
                        Spacer()
                        VStack {
                            TechCornerView(watermarkInfo: .placeholder, width: 400)
                            Spacer()
                        }
                    }
                )
            TechWatermarkView(
                watermarkInfo: .placeholder,
                width: 400
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
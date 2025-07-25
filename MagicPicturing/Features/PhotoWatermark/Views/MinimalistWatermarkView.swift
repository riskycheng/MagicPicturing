import SwiftUI

/// A minimalist watermark template with clean lines and modern design.
struct MinimalistWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let barHeight = geometry.size.width * 0.13
            let baseFontSize = geometry.size.width * 0.04

            HStack {
                Spacer()
                brandLogo(size: baseFontSize * 1.5)
                Spacer()
            }
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

struct MinimalistCornerView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        let baseFontSize = width * 0.025

        HStack(spacing: baseFontSize * 0.4) {
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: baseFontSize * 0.6, height: baseFontSize * 0.6)
            
            Text(watermarkInfo.cameraMake ?? "CAMERA")
                .font(.system(size: baseFontSize, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, baseFontSize)
        .padding(.vertical, baseFontSize * 0.5)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
        .padding([.top, .trailing], width * 0.04)
    }
}

struct MinimalistWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Image("beach")
                .resizable()
                .scaledToFit()
                .overlay(
                    HStack {
                        Spacer()
                        VStack {
                            MinimalistCornerView(watermarkInfo: .placeholder, width: 400)
                            Spacer()
                        }
                    }
                )
            MinimalistWatermarkView(
                watermarkInfo: .placeholder,
                width: 400
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
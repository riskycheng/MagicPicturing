import SwiftUI

/// A template that mimics the look of a cinematic film strip.
struct FilmWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let barHeight = geometry.size.width * 0.13
            let baseFontSize = geometry.size.width * 0.03

            HStack(alignment: .center) {
                // Left side: Camera info and shot details
                VStack(alignment: .leading, spacing: baseFontSize * 0.2) {
                    Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                        .font(.system(size: baseFontSize * 1.1, weight: .bold, design: .monospaced))

                    Text([watermarkInfo.focalLength, watermarkInfo.aperture, watermarkInfo.shutterSpeed, watermarkInfo.iso]
                            .compactMap { $0 }
                            .joined(separator: "   "))
                        .font(.system(size: baseFontSize * 0.9, weight: .medium, design: .monospaced))
                }

                Spacer()

                // Right side: Logo
                brandLogo(size: baseFontSize * 1.8)
            }
            .foregroundColor(.black)
            .padding(.horizontal, baseFontSize * 1.5)
            .frame(height: barHeight)
            .background(Color.white)
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

struct FilmWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Image("beach")
                .resizable()
                .scaledToFit()
                .colorMatrix(.cinematic) // Apply filter for preview
            FilmWatermarkView(
                watermarkInfo: .placeholder,
                width: 400
            )
        }
        .previewLayout(.sizeThatFits)
        
        Image("beach")
            .resizable()
            .scaledToFit()
            .colorMatrix(.cinematic) // Apply filter for preview
            .overlay(
                VStack {
                    Spacer()
                    FilmWatermarkView(
                        watermarkInfo: .placeholder,
                        width: 400
                    )
                }
            )
            .previewLayout(.fixed(width: 400, height: 300))
    }
}

// A simple ColorMatrix extension for example filter effects
fileprivate extension View {
    func colorMatrix(_ matrix: ColorMatrix) -> some View {
        self.colorMultiply(matrix.color)
            .contrast(matrix.contrast)
            .brightness(matrix.brightness)
    }
}

fileprivate struct ColorMatrix {
    let color: Color
    let contrast: Double
    let brightness: Double

    static let cinematic = ColorMatrix(color: .init(red: 1.0, green: 0.95, blue: 0.85), contrast: 1.15, brightness: -0.05)
}
import SwiftUI

/// A template that mimics the look of a cinematic film strip.
struct FilmWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        watermarkBar(width: self.width)
    }

    @ViewBuilder
    private func watermarkBar(width: CGFloat) -> some View {
        let baseFontSize = width * 0.025

        HStack {
            Text("SHOT ON \(watermarkInfo.cameraMake?.uppercased() ?? "")")
            
            Spacer()
            
            Text("\(watermarkInfo.focalLength ?? "") F\(watermarkInfo.aperture?.replacingOccurrences(of: "f/", with: "") ?? "") \(watermarkInfo.shutterSpeed?.uppercased() ?? "") ISO\(watermarkInfo.iso?.replacingOccurrences(of: "ISO ", with: "") ?? "")")
        }
        .font(.system(size: baseFontSize, weight: .bold, design: .monospaced))
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, baseFontSize * 1.5)
        .padding(.vertical, baseFontSize)
        .background(Color.black)
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
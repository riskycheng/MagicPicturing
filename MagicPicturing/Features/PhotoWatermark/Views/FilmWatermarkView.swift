import SwiftUI

/// A template that mimics the look of a cinematic film strip.
struct FilmWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo
    let isPreview: Bool

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                // Applying a subtle cinematic color grade
                .colorMatrix(ColorMatrix.cinematic)

            // Black bottom bar with monospaced, film-style text
            HStack {
                Text("SHOT ON \(watermarkInfo.cameraMake?.uppercased() ?? "")")
                    .font(.system(size: isPreview ? 6 : 10, weight: .bold, design: .monospaced))
                
                Spacer()
                
                Text("\(watermarkInfo.focalLength ?? "") F\(watermarkInfo.aperture?.replacingOccurrences(of: "f/", with: "") ?? "") \(watermarkInfo.shutterSpeed?.uppercased() ?? "") ISO\(watermarkInfo.iso?.replacingOccurrences(of: "ISO ", with: "") ?? "")")
                    .font(.system(size: isPreview ? 6 : 10, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, isPreview ? 6 : 12)
            .padding(.vertical, isPreview ? 4 : 8)
            .background(Color.black)
        }
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
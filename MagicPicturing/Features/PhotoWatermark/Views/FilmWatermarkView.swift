import SwiftUI

/// A template that mimics the look of a cinematic film strip.
struct FilmWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo
    let isPreview: Bool
    let width: CGFloat

    var body: some View {
        if isPreview {
            previewOverlay
        } else {
            finalRenderView
        }
    }

    @ViewBuilder
    private var previewOverlay: some View {
        ZStack(alignment: .bottom) {
            // The color matrix is part of the film look, so we apply it here for the preview.
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .colorMatrix(ColorMatrix.cinematic)
            watermarkBar(width: self.width)
        }
    }

    @ViewBuilder
    private var finalRenderView: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .colorMatrix(ColorMatrix.cinematic)

            watermarkBar(width: self.width)
        }
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
        FilmWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false,
            width: 400
        )
        .previewLayout(.sizeThatFits)
        
        FilmWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true,
            width: 400
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
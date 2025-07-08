import SwiftUI

/// An artistic watermark template with creative design elements.
struct ArtisticWatermarkView: View {
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
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .overlay(
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        artisticCorner(width: self.width)
                    }
                    Spacer()
                    watermarkBar(width: self.width)
                }
            )
    }

    @ViewBuilder
    private var finalRenderView: some View {
        VStack(spacing: 0) {
            imageWithArtisticBorder(width: self.width)
            watermarkBar(width: self.width)
        }
    }
    
    @ViewBuilder
    private func imageWithArtisticBorder(width: CGFloat) -> some View {
        let padding = width * 0.01
        let imagePadding = width * 0.02
        let outerCornerRadius = width * 0.06
        let innerCornerRadius = width * 0.04

        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(imagePadding)
                .background(
                    RoundedRectangle(cornerRadius: innerCornerRadius)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            artisticCorner(width: width)
                        }
                        Spacer()
                    }
                )
        }
        .background(
            RoundedRectangle(cornerRadius: outerCornerRadius)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.9, green: 0.8, blue: 0.6),
                            Color(red: 0.8, green: 0.7, blue: 0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding(padding)
    }

    @ViewBuilder
    private func watermarkBar(width: CGFloat) -> some View {
        let baseFontSize = width * 0.025
        let padding = width * 0.04
        let barCornerRadius = width * 0.03

        VStack(spacing: 0) {
            // Decorative line
            HStack(spacing: baseFontSize * 0.2) {
                ForEach(0..<15) { _ in
                    Circle()
                        .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .frame(width: baseFontSize * 0.15, height: baseFontSize * 0.15)
                }
            }
            .padding(.vertical, baseFontSize * 0.2)

            // Main content
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: baseFontSize * 0.1) {
                    Text("📷").font(.system(size: baseFontSize))
                    Text(watermarkInfo.cameraModel ?? "Camera")
                        .font(.system(size: baseFontSize * 0.9, weight: .medium, design: .serif))
                        .foregroundColor(.black.opacity(0.8))
                }

                Spacer()

                VStack(spacing: baseFontSize * 0.1) {
                    Text("✧ ARTISTIC ✧")
                        .font(.system(size: baseFontSize * 0.8, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                    Text("PHOTOGRAPHY")
                        .font(.system(size: baseFontSize * 0.6, weight: .medium, design: .serif))
                        .foregroundColor(.black.opacity(0.6))
                        .tracking(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: baseFontSize * 0.1) {
                    Text("⚡").font(.system(size: baseFontSize))
                    Text([watermarkInfo.focalLength, watermarkInfo.aperture].compactMap { $0 }.joined(separator: " "))
                        .font(.system(size: baseFontSize * 0.9, weight: .medium, design: .serif))
                        .foregroundColor(.black.opacity(0.8))
                }
            }
            .padding(.horizontal, padding)
            .padding(.vertical, padding * 0.75)
            .background(
                RoundedRectangle(cornerRadius: barCornerRadius)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 0.95, green: 0.9, blue: 0.8), Color(red: 0.9, green: 0.85, blue: 0.75)]), startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: barCornerRadius)
                    .stroke(LinearGradient(gradient: Gradient(colors: [Color(red: 0.6, green: 0.4, blue: 0.2), Color(red: 0.8, green: 0.6, blue: 0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func artisticCorner(width: CGFloat) -> some View {
        let baseFontSize = width * 0.02

        VStack(spacing: baseFontSize * 0.2) {
            Text("✦")
                .font(.system(size: baseFontSize * 1.5))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            
            Text(watermarkInfo.cameraMake ?? "ART")
                .font(.system(size: baseFontSize, weight: .bold, design: .serif))
                .foregroundColor(.white)
        }
        .padding(.horizontal, baseFontSize * 1.2)
        .padding(.vertical, baseFontSize * 0.8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.3), lineWidth: 0.5))
        )
        .rotationEffect(.degrees(15))
        .padding([.top, .trailing], width * 0.05)
    }
}

struct ArtisticWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        ArtisticWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false,
            width: 400
        )
        .previewLayout(.sizeThatFits)
        
        ArtisticWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true,
            width: 400
        )
        .previewLayout(.fixed(width: 400, height: 500))
    }
}
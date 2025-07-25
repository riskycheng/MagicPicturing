import SwiftUI

/// A natural watermark template with organic design elements.
struct NaturalWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        let baseFontSize = width * 0.028
        let padding = width * 0.04
        let barCornerRadius = width * 0.03

        VStack(spacing: 0) {
            decorativeLine(size: baseFontSize * 0.15, spacing: baseFontSize * 0.1, reversed: false)

            HStack(alignment: .center) {
                // Left: Camera Info
                VStack(alignment: .leading, spacing: baseFontSize * 0.1) {
                    HStack(spacing: baseFontSize * 0.2) {
                        Image(systemName: "leaf.fill").font(.system(size: baseFontSize * 0.8))
                        Text("NATURE").font(.system(size: baseFontSize * 0.6, weight: .medium, design: .serif))
                    }.foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.3))
                    Text(watermarkInfo.cameraModel ?? "Natural Camera")
                        .font(.system(size: baseFontSize, weight: .medium, design: .serif))
                        .foregroundColor(.black.opacity(0.8))
                }

                Spacer()

                // Center: Logo
                VStack(spacing: baseFontSize * 0.1) {
                    Image(systemName: "camera.filters").font(.system(size: baseFontSize * 1.5))
                    Text("ORGANIC").font(.system(size: baseFontSize * 0.5, weight: .medium, design: .serif)).tracking(1)
                }.foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.3))

                Spacer()

                // Right: Specs
                VStack(alignment: .trailing, spacing: baseFontSize * 0.1) {
                    HStack(spacing: baseFontSize * 0.2) {
                        Text("PURE").font(.system(size: baseFontSize * 0.6, weight: .medium, design: .serif))
                        Image(systemName: "drop.fill").font(.system(size: baseFontSize * 0.8))
                    }.foregroundColor(Color(red: 0.4, green: 0.6, blue: 0.3))
                    Text([watermarkInfo.focalLength, watermarkInfo.aperture].compactMap { $0 }.joined(separator: " "))
                        .font(.system(size: baseFontSize, weight: .medium, design: .serif))
                        .foregroundColor(.black.opacity(0.8))
                }
            }
            .padding(.horizontal, padding)
            .frame(height: width * 0.13)
            .background(
                RoundedRectangle(cornerRadius: barCornerRadius)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 0.95, green: 0.98, blue: 0.95), Color(red: 0.9, green: 0.95, blue: 0.9)]), startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: barCornerRadius)
                    .stroke(LinearGradient(gradient: Gradient(colors: [Color(red: 0.4, green: 0.6, blue: 0.3), Color(red: 0.5, green: 0.7, blue: 0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )

            decorativeLine(size: baseFontSize * 0.15, spacing: baseFontSize * 0.1, reversed: true)
        }
    }

    @ViewBuilder
    private func decorativeLine(size: CGFloat, spacing: CGFloat, reversed: Bool) -> some View {
        HStack(spacing: spacing) {
            ForEach(0..<20) { index in
                Circle()
                    .fill(Color(red: 0.5, green: 0.7, blue: 0.4))
                    .frame(width: size, height: size)
                    .scaleEffect((index % 2 == 0) == reversed ? 0.7 : 1.0)
            }
        }
        .padding(.vertical, spacing * 2)
    }
}

struct NaturalCornerView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        let baseFontSize = width * 0.025

        VStack(spacing: baseFontSize * 0.2) {
            Text("🌿")
                .font(.system(size: baseFontSize * 1.5))
            Text(watermarkInfo.cameraMake ?? "NATURE")
                .font(.system(size: baseFontSize, weight: .medium, design: .serif))
                .foregroundColor(.white)
        }
        .padding(.horizontal, baseFontSize * 1.5)
        .padding(.vertical, baseFontSize)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 0.4, green: 0.6, blue: 0.3), Color(red: 0.3, green: 0.5, blue: 0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.3), lineWidth: 0.5))
        .padding([.top, .trailing], width * 0.04)
    }
}

struct NaturalWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Image("beach")
                .resizable()
                .scaledToFit()
                .overlay(
                    HStack {
                        Spacer()
                        VStack {
                            NaturalCornerView(watermarkInfo: .placeholder, width: 400)
                            Spacer()
                        }
                    }
                )
            NaturalWatermarkView(
                watermarkInfo: .placeholder,
                width: 400
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
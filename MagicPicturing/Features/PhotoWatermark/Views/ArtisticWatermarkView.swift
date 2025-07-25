import SwiftUI

/// An artistic watermark template with creative design elements.
struct ArtisticWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
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
                Text(watermarkInfo.cameraModel ?? "Camera")
                    .font(.system(size: baseFontSize, weight: .semibold, design: .serif))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer()

                Text("✧")
                    .font(.system(size: baseFontSize * 1.2, weight: .light))

                Spacer()

                Text([watermarkInfo.focalLength, watermarkInfo.aperture, watermarkInfo.shutterSpeed, watermarkInfo.iso]
                        .compactMap { $0 }
                        .joined(separator: " ・ "))
                    .font(.system(size: baseFontSize * 0.9, weight: .medium, design: .serif))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            .padding(.horizontal, padding)
            .frame(height: width * 0.13)
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
}

struct ArtisticCornerView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
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
        VStack(spacing: 0) {
            Image("beach")
                .resizable()
                .scaledToFit()
                .overlay(
                    HStack {
                        Spacer()
                        VStack {
                            ArtisticCornerView(watermarkInfo: .placeholder, width: 400)
                            Spacer()
                        }
                    }
                )
            ArtisticWatermarkView(
                watermarkInfo: .placeholder,
                width: 400
            )
        }
        .previewLayout(.sizeThatFits)
    }
}
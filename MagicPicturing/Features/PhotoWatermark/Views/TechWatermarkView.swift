import SwiftUI

/// A futuristic tech-style watermark template.
struct TechWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    let width: CGFloat

    var body: some View {
        let baseFontSize = width * 0.028
        let padding = width * 0.04

        VStack(spacing: 0) {
            techBorder(width: width, reversed: false)

            HStack(alignment: .center) {
                // Left: Device info
                HStack(spacing: baseFontSize * 0.4) {
                    Image(systemName: "cpu").font(.system(size: baseFontSize * 0.9))
                    Text(watermarkInfo.cameraModel ?? "Device")
                        .font(.system(size: baseFontSize, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                Spacer()

                // Center: Tech logo
                Image(systemName: "camera.aperture")
                    .font(.system(size: baseFontSize * 1.5))

                Spacer()

                // Right: Technical specs
                Text([watermarkInfo.focalLength, watermarkInfo.aperture, watermarkInfo.shutterSpeed, watermarkInfo.iso]
                        .compactMap { $0 }
                        .joined(separator: " "))
                    .font(.system(size: baseFontSize, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, padding)
            .padding(.vertical, padding)
            .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.9), Color.black.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
            .overlay(techGridOverlay(gridSize: baseFontSize))

            techBorder(width: width, reversed: true)
        }
    }

    @ViewBuilder
    private func techBorder(width: CGFloat, reversed: Bool) -> some View {
        let barWidth = width / 25
        HStack(spacing: 0) {
            ForEach(0..<25) { index in
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: reversed ? [Color.blue, Color.cyan] : [Color.cyan, Color.blue]), startPoint: .top, endPoint: .bottom))
                    .frame(width: barWidth, height: width * 0.005)
                    .opacity((index % 2 == 0) == reversed ? 0.3 : 1.0)
            }
        }
    }

    @ViewBuilder
    private func techGridOverlay(gridSize: CGFloat) -> some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                for x in stride(from: 0, through: width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                
                for y in stride(from: 0, through: height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.cyan.opacity(0.1), lineWidth: 0.5)
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
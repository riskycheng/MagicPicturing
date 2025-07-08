import SwiftUI

/// A minimalist watermark template with clean lines and modern design.
struct MinimalistWatermarkView: View {
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
                        cornerWatermark(width: self.width)
                    }
                    Spacer()
                    watermarkBar(width: self.width)
                }
            )
    }

    @ViewBuilder
    private var finalRenderView: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .overlay(
                    HStack {
                        Spacer()
                        VStack {
                            cornerWatermark(width: self.width)
                            Spacer()
                        }
                    }
                )
            watermarkBar(width: self.width)
        }
    }
    
    @ViewBuilder
    private func watermarkBar(width: CGFloat) -> some View {
        let baseFontSize = width * 0.03

        HStack(alignment: .center) {
            // Camera info
            VStack(alignment: .leading, spacing: baseFontSize * 0.1) {
                Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                    .font(.system(size: baseFontSize, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
            }

            Spacer()

            // Separator line
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 1, height: baseFontSize * 1.5)

            Spacer()

            // Shot details
            VStack(alignment: .trailing, spacing: baseFontSize * 0.1) {
                Text([watermarkInfo.focalLength, watermarkInfo.aperture]
                        .compactMap { $0 }
                        .joined(separator: " "))
                    .font(.system(size: baseFontSize, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                if let date = watermarkInfo.creationDate {
                    Text(date)
                        .font(.system(size: baseFontSize * 0.8, weight: .light))
                        .foregroundColor(.black.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, baseFontSize * 1.5)
        .padding(.vertical, baseFontSize)
        .background(Color.white.opacity(0.95))
    }
    
    @ViewBuilder
    private func cornerWatermark(width: CGFloat) -> some View {
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
        MinimalistWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false,
            width: 400
        )
        .previewLayout(.sizeThatFits)
        
        MinimalistWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true,
            width: 400
        )
        .previewLayout(.fixed(width: 400, height: 300))
    }
}
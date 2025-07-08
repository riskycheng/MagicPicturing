import SwiftUI

/// A minimalist watermark template with clean lines and modern design.
struct MinimalistWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo
    let isPreview: Bool

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .overlay(
                    // Subtle corner watermark
                    VStack {
                        HStack {
                            Spacer()
                            cornerWatermark
                                .padding(.top, isPreview ? 8 : 16)
                                .padding(.trailing, isPreview ? 8 : 16)
                        }
                        Spacer()
                    }
                )

            // Minimal bottom bar
            HStack(alignment: .center) {
                // Camera info
                VStack(alignment: .leading, spacing: isPreview ? 1 : 2) {
                    Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                        .font(.system(size: isPreview ? 8 : 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }

                Spacer()

                // Separator line
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 1, height: isPreview ? 12 : 20)

                Spacer()

                // Shot details
                VStack(alignment: .trailing, spacing: isPreview ? 1 : 2) {
                    Text([watermarkInfo.focalLength, watermarkInfo.aperture]
                            .compactMap { $0 }
                            .joined(separator: " "))
                        .font(.system(size: isPreview ? 8 : 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                    if let date = watermarkInfo.creationDate {
                        Text(date)
                            .font(.system(size: isPreview ? 6 : 10, weight: .light))
                            .foregroundColor(.black.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, isPreview ? 8 : 16)
            .padding(.vertical, isPreview ? 6 : 12)
            .background(Color.white.opacity(0.95))
        }
    }
    
    @ViewBuilder
    private var cornerWatermark: some View {
        HStack(spacing: isPreview ? 2 : 4) {
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: isPreview ? 4 : 6, height: isPreview ? 4 : 6)
            
            Text(watermarkInfo.cameraMake ?? "CAMERA")
                .font(.system(size: isPreview ? 6 : 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, isPreview ? 4 : 8)
        .padding(.vertical, isPreview ? 2 : 4)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
    }
}

struct MinimalistWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        MinimalistWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false
        )
        .previewLayout(.sizeThatFits)
        
        MinimalistWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true
        )
        .previewLayout(.fixed(width: 200, height: 150))
    }
} 
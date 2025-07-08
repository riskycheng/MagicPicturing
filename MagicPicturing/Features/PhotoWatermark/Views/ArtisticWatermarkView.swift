import SwiftUI

/// An artistic watermark template with creative design elements.
struct ArtisticWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo
    let isPreview: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Artistic border around the image
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(isPreview ? 8 : 16)
                    .background(
                        RoundedRectangle(cornerRadius: isPreview ? 8 : 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        // Artistic corner decoration
                        VStack {
                            HStack {
                                Spacer()
                                artisticCorner
                                    .padding(.top, isPreview ? 4 : 8)
                                    .padding(.trailing, isPreview ? 4 : 8)
                            }
                            Spacer()
                        }
                    )
            }
            .background(
                RoundedRectangle(cornerRadius: isPreview ? 12 : 24)
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
            .padding(isPreview ? 4 : 8)

            // Artistic bottom section
            VStack(spacing: 0) {
                // Decorative line
                HStack(spacing: isPreview ? 2 : 4) {
                    ForEach(0..<10, id: \.self) { index in
                        Circle()
                            .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .frame(width: isPreview ? 2 : 4, height: isPreview ? 2 : 4)
                    }
                }
                .padding(.vertical, isPreview ? 2 : 4)

                // Main content with artistic layout
                HStack(alignment: .center) {
                    // Left: Artistic camera info
                    VStack(alignment: .leading, spacing: isPreview ? 1 : 2) {
                        Text("📷")
                            .font(.system(size: isPreview ? 8 : 12))
                        
                        Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                            .font(.system(size: isPreview ? 7 : 11, weight: .medium, design: .serif))
                            .foregroundColor(.black.opacity(0.8))
                    }

                    Spacer()

                    // Center: Artistic signature
                    VStack(spacing: isPreview ? 1 : 2) {
                        Text("✧ ARTISTIC ✧")
                            .font(.system(size: isPreview ? 6 : 9, weight: .bold, design: .serif))
                            .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
                        
                        Text("PHOTOGRAPHY")
                            .font(.system(size: isPreview ? 4 : 6, weight: .medium, design: .serif))
                            .foregroundColor(.black.opacity(0.6))
                            .tracking(1)
                    }

                    Spacer()

                    // Right: Technical details with artistic flair
                    VStack(alignment: .trailing, spacing: isPreview ? 1 : 2) {
                        Text("⚡")
                            .font(.system(size: isPreview ? 8 : 12))
                        
                        Text([watermarkInfo.focalLength, watermarkInfo.aperture]
                                .compactMap { $0 }
                                .joined(separator: " "))
                            .font(.system(size: isPreview ? 7 : 11, weight: .medium, design: .serif))
                            .foregroundColor(.black.opacity(0.8))
                    }
                }
                .padding(.horizontal, isPreview ? 8 : 16)
                .padding(.vertical, isPreview ? 6 : 12)
                .background(
                    RoundedRectangle(cornerRadius: isPreview ? 8 : 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.95, green: 0.9, blue: 0.8),
                                    Color(red: 0.9, green: 0.85, blue: 0.75)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isPreview ? 8 : 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.6, green: 0.4, blue: 0.2),
                                    Color(red: 0.8, green: 0.6, blue: 0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
        }
    }
    
    @ViewBuilder
    private var artisticCorner: some View {
        VStack(spacing: isPreview ? 1 : 2) {
            Text("✦")
                .font(.system(size: isPreview ? 6 : 10))
                .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.2))
            
            Text(watermarkInfo.cameraMake ?? "ART")
                .font(.system(size: isPreview ? 4 : 6, weight: .bold, design: .serif))
                .foregroundColor(.white)
        }
        .padding(.horizontal, isPreview ? 3 : 5)
        .padding(.vertical, isPreview ? 2 : 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
        )
        .rotationEffect(.degrees(15))
    }
}

struct ArtisticWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        ArtisticWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false
        )
        .previewLayout(.sizeThatFits)
        
        ArtisticWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true
        )
        .previewLayout(.fixed(width: 200, height: 150))
    }
} 
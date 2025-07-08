import SwiftUI

/// A magazine-style watermark template with editorial layout.
struct MagazineWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo
    let isPreview: Bool

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .overlay(
                    // Magazine-style corner badge
                    VStack {
                        HStack {
                            Spacer()
                            magazineBadge
                                .padding(.top, isPreview ? 8 : 16)
                                .padding(.trailing, isPreview ? 8 : 16)
                        }
                        Spacer()
                    }
                )

            // Magazine-style bottom section
            VStack(spacing: 0) {
                // Top accent line
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: isPreview ? 2 : 4)

                // Main content area
                HStack(alignment: .top, spacing: isPreview ? 8 : 16) {
                    // Left column: Camera info
                    VStack(alignment: .leading, spacing: isPreview ? 2 : 4) {
                        Text("EQUIPMENT")
                            .font(.system(size: isPreview ? 6 : 8, weight: .bold, design: .default))
                            .foregroundColor(.blue)
                            .tracking(1)
                        
                        Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                            .font(.system(size: isPreview ? 8 : 12, weight: .semibold))
                            .foregroundColor(.black)
                        
                        if let lensModel = watermarkInfo.lensModel, !lensModel.isEmpty {
                            Text(lensModel)
                                .font(.system(size: isPreview ? 6 : 10, weight: .light))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Center: Brand logo with style
                    VStack(spacing: isPreview ? 2 : 4) {
                        brandLogo
                            .font(.system(size: isPreview ? 16 : 24))
                            .foregroundColor(.blue)
                        
                        Text("PHOTOGRAPHY")
                            .font(.system(size: isPreview ? 4 : 6, weight: .bold, design: .default))
                            .foregroundColor(.blue)
                            .tracking(0.5)
                    }

                    // Right column: Technical specs
                    VStack(alignment: .trailing, spacing: isPreview ? 2 : 4) {
                        Text("SPECIFICATIONS")
                            .font(.system(size: isPreview ? 6 : 8, weight: .bold, design: .default))
                            .foregroundColor(.blue)
                            .tracking(1)
                        
                        Text([watermarkInfo.focalLength, watermarkInfo.aperture]
                                .compactMap { $0 }
                                .joined(separator: " "))
                            .font(.system(size: isPreview ? 8 : 12, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text([watermarkInfo.shutterSpeed, watermarkInfo.iso]
                                .compactMap { $0 }
                                .joined(separator: " "))
                            .font(.system(size: isPreview ? 6 : 10, weight: .light))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, isPreview ? 8 : 16)
                .padding(.vertical, isPreview ? 8 : 12)
                .background(Color.white)

                // Bottom accent line
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: isPreview ? 2 : 4)
            }
        }
    }
    
    @ViewBuilder
    private var magazineBadge: some View {
        VStack(spacing: isPreview ? 1 : 2) {
            Text("MAGAZINE")
                .font(.system(size: isPreview ? 4 : 6, weight: .bold, design: .default))
                .foregroundColor(.white)
                .tracking(0.5)
            
            Text("STYLE")
                .font(.system(size: isPreview ? 3 : 5, weight: .medium, design: .default))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, isPreview ? 4 : 6)
        .padding(.vertical, isPreview ? 2 : 3)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var brandLogo: some View {
        if let make = watermarkInfo.cameraMake?.lowercased() {
            if make.contains("apple") {
                Image(systemName: "apple.logo")
            } else if make.contains("fujifilm") {
                Text("FUJIFILM")
                    .font(.system(size: isPreview ? 6 : 10, weight: .bold, design: .monospaced))
            } else if make.contains("sony") {
                Text("SONY")
                    .font(.system(size: isPreview ? 7 : 12, weight: .bold, design: .default))
            } else if make.contains("canon") {
                Text("Canon")
                    .font(.system(size: isPreview ? 8 : 14, weight: .bold, design: .serif))
            } else {
                Image(systemName: "camera.fill")
            }
        } else {
            Image(systemName: "camera.fill")
        }
    }
}

struct MagazineWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        MagazineWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false
        )
        .previewLayout(.sizeThatFits)
        
        MagazineWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true
        )
        .previewLayout(.fixed(width: 200, height: 150))
    }
} 
import SwiftUI

/// A magazine-style watermark template with editorial layout.
struct MagazineWatermarkView: View {
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
                        magazineBadge(width: self.width)
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
                            magazineBadge(width: self.width)
                            Spacer()
                        }
                    }
                )
            watermarkBar(width: self.width)
        }
    }
    
    @ViewBuilder
    private func watermarkBar(width: CGFloat) -> some View {
        let baseFontSize = width * 0.025
        let accentLineHeight = baseFontSize * 0.1

        VStack(spacing: 0) {
            // Top accent line
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                .frame(height: accentLineHeight)

            // Main content area
            HStack(alignment: .top, spacing: baseFontSize) {
                // Left column: Camera info
                VStack(alignment: .leading, spacing: baseFontSize * 0.2) {
                    Text("EQUIPMENT")
                        .font(.system(size: baseFontSize * 0.8, weight: .bold))
                        .foregroundColor(.blue)
                        .tracking(1)
                    
                    Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                        .font(.system(size: baseFontSize, weight: .semibold))
                        .foregroundColor(.black)
                    
                    if let lensModel = watermarkInfo.lensModel, !lensModel.isEmpty {
                        Text(lensModel)
                            .font(.system(size: baseFontSize * 0.8, weight: .light))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                // Center: Brand logo with style
                VStack(spacing: baseFontSize * 0.2) {
                    brandLogo(size: baseFontSize * 1.8)
                        .foregroundColor(.blue)
                    
                    Text("PHOTOGRAPHY")
                        .font(.system(size: baseFontSize * 0.6, weight: .bold))
                        .foregroundColor(.blue)
                        .tracking(0.5)
                }

                // Right column: Technical specs
                VStack(alignment: .trailing, spacing: baseFontSize * 0.2) {
                    Text("SPECIFICATIONS")
                        .font(.system(size: baseFontSize * 0.8, weight: .bold))
                        .foregroundColor(.blue)
                        .tracking(1)
                    
                    Text([watermarkInfo.focalLength, watermarkInfo.aperture].compactMap { $0 }.joined(separator: " "))
                        .font(.system(size: baseFontSize, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text([watermarkInfo.shutterSpeed, watermarkInfo.iso].compactMap { $0 }.joined(separator: " "))
                        .font(.system(size: baseFontSize * 0.8, weight: .light))
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
            }
            .padding(baseFontSize)
            .background(Color.white)

            // Bottom accent line
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing))
                .frame(height: accentLineHeight)
        }
    }
    
    @ViewBuilder
    private func magazineBadge(width: CGFloat) -> some View {
        let baseFontSize = width * 0.02

        VStack(spacing: baseFontSize * 0.2) {
            Text("MAGAZINE")
                .font(.system(size: baseFontSize, weight: .bold))
                .foregroundColor(.white)
                .tracking(0.5)
            
            Text("STYLE")
                .font(.system(size: baseFontSize * 0.8, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, baseFontSize * 1.5)
        .padding(.vertical, baseFontSize * 0.8)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        .padding([.top, .trailing], width * 0.04)
    }
    
    @ViewBuilder
    private func brandLogo(size: CGFloat) -> some View {
        if let make = watermarkInfo.cameraMake?.lowercased() {
            if make.contains("apple") {
                Image(systemName: "apple.logo").font(.system(size: size))
            } else if make.contains("fujifilm") {
                Text("FUJIFILM").font(.custom("Tungsten-Semibold", size: size))
            } else if make.contains("sony") {
                Text("SONY").font(.system(size: size * 0.8, weight: .bold))
            } else if make.contains("canon") {
                Text("Canon").font(.custom("Trajan Pro", size: size * 0.9))
            } else {
                Image(systemName: "camera.fill").font(.system(size: size * 0.9))
            }
        } else {
            Image(systemName: "camera.fill").font(.system(size: size * 0.9))
        }
    }
}

struct MagazineWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        MagazineWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false,
            width: 400
        )
        .previewLayout(.sizeThatFits)
        
        MagazineWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true,
            width: 400
        )
        .previewLayout(.fixed(width: 400, height: 450))
    }
}
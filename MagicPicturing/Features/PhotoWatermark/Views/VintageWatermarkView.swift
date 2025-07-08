import SwiftUI

/// A vintage watermark template with nostalgic film aesthetics.
struct VintageWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo
    let isPreview: Bool
    let width: CGFloat

    private var vintageFilter: some View {
        Color.clear
            .colorMultiply(Color(red: 1.1, green: 0.95, blue: 0.8))
            .contrast(1.1)
    }

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
            .overlay(vintageFilter)
            .overlay(
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        vintageStamp(width: self.width)
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
                .overlay(vintageFilter)
                .overlay(
                    HStack {
                        Spacer()
                        VStack {
                            vintageStamp(width: self.width)
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

        VStack(spacing: 0) {
            // Film perforations
            HStack(spacing: baseFontSize * 0.5) {
                ForEach(0..<Int(width / (baseFontSize * 1.5)), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: baseFontSize * 0.1)
                        .fill(Color.black)
                        .frame(width: baseFontSize, height: baseFontSize * 0.6)
                }
            }
            .padding(.horizontal, baseFontSize)
            .padding(.vertical, baseFontSize * 0.5)
            .background(Color.black)

            // Main watermark area
            HStack(alignment: .center) {
                // Left: Camera and date
                VStack(alignment: .leading, spacing: baseFontSize * 0.2) {
                    Text(watermarkInfo.cameraMake?.uppercased() ?? "CAMERA")
                        .font(.system(size: baseFontSize, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    if let date = watermarkInfo.creationDate {
                        Text(date)
                            .font(.system(size: baseFontSize * 0.8, weight: .medium, design: .serif))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Center: Film strip icon
                Image(systemName: "film")
                    .font(.system(size: baseFontSize * 1.8))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                // Right: Technical details
                VStack(alignment: .trailing, spacing: baseFontSize * 0.2) {
                    Text("\(watermarkInfo.focalLength ?? "") \(watermarkInfo.aperture ?? "")")
                        .font(.system(size: baseFontSize, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    Text("\(watermarkInfo.shutterSpeed ?? "") \(watermarkInfo.iso ?? "")")
                        .font(.system(size: baseFontSize * 0.8, weight: .medium, design: .serif))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, baseFontSize * 1.5)
            .padding(.vertical, baseFontSize)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.black.opacity(0.9)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    @ViewBuilder
    private func vintageStamp(width: CGFloat) -> some View {
        let baseFontSize = width * 0.02

        VStack(spacing: baseFontSize * 0.2) {
            Text("VINTAGE")
                .font(.system(size: baseFontSize * 1.2, weight: .bold, design: .serif))
                .foregroundColor(.white)
            
            Text(watermarkInfo.cameraModel ?? "FILM")
                .font(.system(size: baseFontSize, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, baseFontSize * 1.5)
        .padding(.vertical, baseFontSize * 0.8)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
        )
        .rotationEffect(.degrees(-15))
        .padding([.top, .trailing], width * 0.04)
    }
}

struct VintageWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        VintageWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false,
            width: 400
        )
        .previewLayout(.sizeThatFits)
        
        VintageWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true,
            width: 400
        )
        .previewLayout(.fixed(width: 400, height: 300))
    }
}
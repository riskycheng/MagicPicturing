import SwiftUI

/// A vintage watermark template with nostalgic film aesthetics.
struct VintageWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo
    let isPreview: Bool

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .colorMultiply(Color(red: 1.1, green: 0.95, blue: 0.8))
                .contrast(1.1)
                .overlay(
                    // Vintage corner stamp
                    VStack {
                        HStack {
                            Spacer()
                            vintageStamp
                                .padding(.top, isPreview ? 8 : 16)
                                .padding(.trailing, isPreview ? 8 : 16)
                        }
                        Spacer()
                    }
                )

            // Vintage bottom border with film perforations
            VStack(spacing: 0) {
                // Film perforations
                HStack(spacing: isPreview ? 2 : 4) {
                    ForEach(0..<20, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.black)
                            .frame(width: isPreview ? 3 : 6, height: isPreview ? 2 : 4)
                    }
                }
                .padding(.horizontal, isPreview ? 4 : 8)
                .padding(.vertical, isPreview ? 2 : 4)
                .background(Color.black)

                // Main watermark area
                HStack(alignment: .center) {
                    // Left: Camera and date
                    VStack(alignment: .leading, spacing: isPreview ? 1 : 2) {
                        Text(watermarkInfo.cameraMake?.uppercased() ?? "CAMERA")
                            .font(.system(size: isPreview ? 6 : 10, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        if let date = watermarkInfo.creationDate {
                            Text(date)
                                .font(.system(size: isPreview ? 5 : 8, weight: .medium, design: .serif))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    Spacer()

                    // Center: Film strip icon
                    Image(systemName: "film")
                        .font(.system(size: isPreview ? 12 : 20))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    // Right: Technical details
                    VStack(alignment: .trailing, spacing: isPreview ? 1 : 2) {
                        Text("\(watermarkInfo.focalLength ?? "") \(watermarkInfo.aperture ?? "")")
                            .font(.system(size: isPreview ? 6 : 10, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                        Text("\(watermarkInfo.shutterSpeed ?? "") \(watermarkInfo.iso ?? "")")
                            .font(.system(size: isPreview ? 5 : 8, weight: .medium, design: .serif))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, isPreview ? 8 : 16)
                .padding(.vertical, isPreview ? 6 : 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.black.opacity(0.9)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
    
    @ViewBuilder
    private var vintageStamp: some View {
        VStack(spacing: isPreview ? 1 : 2) {
            Text("VINTAGE")
                .font(.system(size: isPreview ? 4 : 6, weight: .bold, design: .serif))
                .foregroundColor(.white)
            
            Text(watermarkInfo.cameraModel ?? "FILM")
                .font(.system(size: isPreview ? 3 : 5, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, isPreview ? 4 : 6)
        .padding(.vertical, isPreview ? 2 : 3)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
        )
        .rotationEffect(.degrees(-15))
    }
}

struct VintageWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        VintageWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false
        )
        .previewLayout(.sizeThatFits)
        
        VintageWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true
        )
        .previewLayout(.fixed(width: 200, height: 150))
    }
} 
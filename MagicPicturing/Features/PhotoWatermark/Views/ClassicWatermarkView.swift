import SwiftUI

/// A classic watermark template that displays EXIF data at the bottom of an image.
struct ClassicWatermarkView: View {
    let watermarkInfo: WatermarkInfo
    var width: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let barHeight = geometry.size.width * 0.13
            let baseFontSize = geometry.size.width * 0.04

            HStack(alignment: .center, spacing: 0) {
                // Left side: Camera and Lens
                VStack(alignment: .leading, spacing: baseFontSize * 0.1) {
                    Text(watermarkInfo.cameraModel ?? "Unknown Camera")
                        .font(.system(size: baseFontSize * 0.8, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(formattedLensModel())
                        .font(.system(size: baseFontSize * 0.65, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Center: Logo
                brandLogo(size: baseFontSize * 1.5)

                Spacer()

                // Right side: Shot details and Date
                VStack(alignment: .trailing, spacing: baseFontSize * 0.1) {
                    Text(formattedShotDetails())
                        .font(.system(size: baseFontSize * 0.8, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    if let date = watermarkInfo.creationDate {
                        Text(date)
                            .font(.system(size: baseFontSize * 0.65, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, geometry.size.width * 0.05)
            .frame(width: geometry.size.width, height: barHeight)
            .background(Color.white)
            .foregroundColor(.black)
        }
        .frame(width: width, height: width * 0.13)
    }

    private func formattedLensModel() -> String {
        guard let lensModel = watermarkInfo.lensModel, !lensModel.isEmpty else { return "" }
        
        // Best case: Regex finds the specific "mm f/..." pattern.
        let pattern = "(\\d+\\.?\\d*mm f/\\d+\\.?\\d*)"
        if let range = lensModel.range(of: pattern, options: .regularExpression) {
            return String(lensModel[range])
        }
        
        // Fallback: Aggressively clean the string.
        let cameraModel = watermarkInfo.cameraModel ?? ""
        var cleanedLens = lensModel.replacingOccurrences(of: cameraModel, with: "")
        
        // Remove common verbose phrases.
        let verbosePhrases = ["back triple camera", "back dual camera", "back camera", "front camera"]
        for phrase in verbosePhrases {
            cleanedLens = cleanedLens.replacingOccurrences(of: phrase, with: "")
        }

        return cleanedLens.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formattedShotDetails() -> String {
        var details: [String] = []
        
        if let focalLength = watermarkInfo.focalLength, !focalLength.isEmpty {
            details.append(focalLength)
        }
        if let aperture = watermarkInfo.aperture, !aperture.isEmpty {
            details.append(aperture.replacingOccurrences(of: "f/", with: "F"))
        }
        if let shutter = watermarkInfo.shutterSpeed, !shutter.isEmpty {
            details.append(shutter)
        }
        
        // Only add ISO if there's room (i.e., less than 3 items already)
        if details.count < 3, let iso = watermarkInfo.iso, !iso.isEmpty {
            details.append(iso.uppercased())
        }
        
        return details.joined(separator: " | ")
    }
    
    /// A view builder for the brand logo.
    @ViewBuilder
    private func brandLogo(size: CGFloat) -> some View {
        if let make = watermarkInfo.cameraMake?.lowercased() {
            if make.contains("apple") {
                Image(systemName: "apple.logo").font(.system(size: size, weight: .semibold))
            } else if make.contains("fujifilm") {
                Text("FUJIFILM").font(.custom("Tungsten-Semibold", size: size))
            } else if make.contains("sony") {
                Text("SONY").font(.system(size: size * 0.8, weight: .bold))
            } else if make.contains("canon") {
                Text("Canon").font(.custom("Trajan Pro", size: size * 0.9))
            } else {
                Image(systemName: "camera.fill").font(.system(size: size * 0.9, weight: .semibold))
            }
        } else {
            Image(systemName: "camera.fill").font(.system(size: size * 0.9, weight: .semibold))
        }
    }
}


struct ClassicWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Image("beach")
                .resizable()
                .scaledToFill()
                .frame(width: 400)
                .clipped()
            ClassicWatermarkView(
                watermarkInfo: .placeholder,
                width: 400
            )
        }
        .previewLayout(.sizeThatFits)
        
        Image("beach")
            .resizable()
            .scaledToFill()
            .frame(width: 400)
            .clipped()
            .overlay(
                VStack {
                    Spacer()
                    ClassicWatermarkView(
                        watermarkInfo: .placeholder,
                        width: 400
                    )
                }
            )
            .previewLayout(.fixed(width: 400, height: 350))
    }
} 
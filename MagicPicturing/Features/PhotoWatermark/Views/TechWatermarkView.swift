import SwiftUI

/// A futuristic tech-style watermark template.
struct TechWatermarkView: View {
    let image: UIImage
    let watermarkInfo: WatermarkInfo
    let isPreview: Bool

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .overlay(
                    // Tech corner overlay
                    VStack {
                        HStack {
                            Spacer()
                            techCorner
                                .padding(.top, isPreview ? 8 : 16)
                                .padding(.trailing, isPreview ? 8 : 16)
                        }
                        Spacer()
                    }
                )

            // Tech-style bottom section
            VStack(spacing: 0) {
                // Animated tech border
                HStack(spacing: 0) {
                    ForEach(0..<20, id: \.self) { index in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.cyan, Color.blue]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: isPreview ? 2 : 4, height: isPreview ? 1 : 2)
                            .opacity(index % 2 == 0 ? 1.0 : 0.3)
                    }
                }

                // Main tech content
                HStack(alignment: .center) {
                    // Left: Device info
                    VStack(alignment: .leading, spacing: isPreview ? 1 : 2) {
                        HStack(spacing: isPreview ? 2 : 4) {
                            Image(systemName: "cpu")
                                .font(.system(size: isPreview ? 6 : 10))
                                .foregroundColor(.cyan)
                            
                            Text("DEVICE")
                                .font(.system(size: isPreview ? 5 : 7, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        
                        Text(watermarkInfo.cameraModel ?? "Unknown Device")
                            .font(.system(size: isPreview ? 7 : 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Center: Tech logo
                    VStack(spacing: isPreview ? 1 : 2) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: isPreview ? 16 : 24))
                            .foregroundColor(.cyan)
                        
                        Text("TECH")
                            .font(.system(size: isPreview ? 4 : 6, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .tracking(2)
                    }

                    Spacer()

                    // Right: Technical specs
                    VStack(alignment: .trailing, spacing: isPreview ? 1 : 2) {
                        HStack(spacing: isPreview ? 2 : 4) {
                            Text("SPECS")
                                .font(.system(size: isPreview ? 5 : 7, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                            
                            Image(systemName: "gearshape")
                                .font(.system(size: isPreview ? 6 : 10))
                                .foregroundColor(.cyan)
                        }
                        
                        Text([watermarkInfo.focalLength, watermarkInfo.aperture]
                                .compactMap { $0 }
                                .joined(separator: " "))
                            .font(.system(size: isPreview ? 7 : 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, isPreview ? 8 : 16)
                .padding(.vertical, isPreview ? 8 : 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Tech grid overlay
                    GeometryReader { geometry in
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let gridSize: CGFloat = isPreview ? 8 : 16
                            
                            // Vertical lines
                            for x in stride(from: 0, through: width, by: gridSize) {
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: height))
                            }
                            
                            // Horizontal lines
                            for y in stride(from: 0, through: height, by: gridSize) {
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: width, y: y))
                            }
                        }
                        .stroke(Color.cyan.opacity(0.1), lineWidth: 0.5)
                    }
                )

                // Bottom tech border
                HStack(spacing: 0) {
                    ForEach(0..<20, id: \.self) { index in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: isPreview ? 2 : 4, height: isPreview ? 1 : 2)
                            .opacity(index % 2 == 0 ? 0.3 : 1.0)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var techCorner: some View {
        VStack(spacing: isPreview ? 1 : 2) {
            Text("⚡")
                .font(.system(size: isPreview ? 6 : 10))
            
            Text(watermarkInfo.cameraMake ?? "TECH")
                .font(.system(size: isPreview ? 4 : 6, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, isPreview ? 4 : 6)
        .padding(.vertical, isPreview ? 2 : 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.cyan, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
    }
}

struct TechWatermarkView_Previews: PreviewProvider {
    static var previews: some View {
        TechWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: false
        )
        .previewLayout(.sizeThatFits)
        
        TechWatermarkView(
            image: UIImage(named: "beach")!,
            watermarkInfo: .placeholder,
            isPreview: true
        )
        .previewLayout(.fixed(width: 200, height: 150))
    }
} 
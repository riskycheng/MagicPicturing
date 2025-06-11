import SwiftUI

struct CollagePreviewView: View {
    let images: [UIImage]
    let layout: CollageLayout
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<min(images.count, layout.frames.count), id: \.self) { index in
                    let image = images[index]
                    let frame = layout.frames[index]
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width * frame.width,
                            height: geometry.size.height * frame.height
                        )
                        .clipped()
                        .position(
                            x: geometry.size.width * frame.midX,
                            y: geometry.size.height * frame.midY
                        )
                }
            }
        }
    }
} 
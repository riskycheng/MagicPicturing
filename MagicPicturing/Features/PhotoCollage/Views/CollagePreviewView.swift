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
                    
                    // Create a "window" for the image using a Rectangle.
                    // Then, overlay the image and let it fill the window,
                    // preserving its aspect ratio. Finally, clip it.
                    // This is the correct way to crop, not squash.
                    Rectangle()
                        .fill(Color.clear) // The frame itself is invisible
                        .frame(
                            width: geometry.size.width * frame.width,
                            height: geometry.size.height * frame.height
                        )
                        .overlay(
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit() // Changed from .scaledToFill to fit the whole image
                                .frame(width: geometry.size.width * frame.width, height: geometry.size.height * frame.height)
                                .background(Color.black) // Add black background for letterboxing
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
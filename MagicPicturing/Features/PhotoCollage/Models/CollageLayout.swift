import SwiftUI

/// Defines the structure for a single collage layout.
struct CollageLayout: Identifiable {
    let id = UUID()
    let name: String
    let aspectRatio: CGFloat
    
    /// An array of CGRects that define the frames for each image within a unit square (1x1).
    /// These relative frames will be scaled to the actual view size.
    let frames: [CGRect]
    
    /// A small preview of the layout for the selection UI.
    var preview: AnyView {
        // This will be a Shape-based view that draws the layout.
        // For now, a placeholder.
        AnyView(
            ZStack {
                ForEach(frames, id: \.self) { frame in
                    Rectangle()
                        .stroke(Color.white, lineWidth: 1)
                        .frame(width: frame.width * 50, height: frame.height * 50)
                        .offset(x: frame.midX * 50 - 25, y: frame.midY * 50 - 25)
                }
            }
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
        )
    }
}

// Conforming to Hashable to be used in ForEach with id: \.self
extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin.x)
        hasher.combine(origin.y)
        hasher.combine(size.width)
        hasher.combine(size.height)
    }
} 
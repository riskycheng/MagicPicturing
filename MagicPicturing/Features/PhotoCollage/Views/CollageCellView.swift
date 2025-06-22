import SwiftUI

struct CollageCellView: View {
    @ObservedObject var state: CollageImageState
    let isSelected: Bool
    
    // States for live gesture tracking
    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            let magnificationGesture = MagnificationGesture()
                .onChanged { value in
                    self.currentScale = value
                }
                .onEnded { value in
                    // Apply the cumulative scale, ensuring it doesn't go below a minimum useful value
                    state.scale = max(state.scale * value, 0.5)
                    self.currentScale = 1.0
                    
                    // After scaling, we need to clamp the offset
                    clampOffset(geometry: geometry)
                }
            
            let dragGesture = DragGesture()
                .onChanged { value in
                    self.currentOffset = value.translation
                }
                .onEnded { value in
                    state.offset.width += value.translation.width
                    state.offset.height += value.translation.height
                    self.currentOffset = .zero
                    
                    // After dragging, clamp the offset
                    clampOffset(geometry: geometry)
                }
            
            let combinedGesture = dragGesture.simultaneously(with: magnificationGesture)

            ZStack {
                Image(uiImage: state.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    // Apply transformations
                    .scaleEffect(state.scale * currentScale)
                    .offset(x: state.offset.width + currentOffset.width, y: state.offset.height + currentOffset.height)
                    .rotationEffect(state.rotation)
                    .scaleEffect(x: state.isFlippedHorizontally ? -1 : 1, y: state.isFlippedVertically ? -1 : 1, anchor: .center)
            }
            .clipped()
            .contentShape(Rectangle())
            .overlay(
                // Selection highlight
                isSelected ? Rectangle().stroke(Color.accentColor, lineWidth: 3) : nil
            )
            .gesture(isSelected ? combinedGesture : nil)
        }
    }

    private func clampOffset(geometry: GeometryProxy) {
        let imageSize = state.image.size
        let viewSize = geometry.size
        
        let scaledImageSize = CGSize(width: imageSize.width * state.scale, height: imageSize.height * state.scale)
        
        // Calculate the maximum allowable offset in each direction.
        // If the scaled image is smaller than the view, the offset should be zero.
        let maxOffsetX = max(0, (scaledImageSize.width - viewSize.width) / 2)
        let maxOffsetY = max(0, (scaledImageSize.height - viewSize.height) / 2)
        
        state.offset.width = max(-maxOffsetX, min(maxOffsetX, state.offset.width))
        state.offset.height = max(-maxOffsetY, min(maxOffsetY, state.offset.height))
    }
}

struct CropHandlesView: View {
    @Binding var state: CollageImageState
    let containerSize: CGSize
    private let handleLength: CGFloat = 100
    private let handleThickness: CGFloat = 20

    var body: some View {
        let _ = print("--- CropHandlesView LOG --- Rendering handles!")
        return ZStack {
            // Top Handle
            handle(for: .top)
                .frame(maxHeight: .infinity, alignment: .top)
                .gesture(dragGesture(for: .top))

            // Bottom Handle
            handle(for: .bottom)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .gesture(dragGesture(for: .bottom))

            // Leading Handle
            handle(for: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .gesture(dragGesture(for: .leading))

            // Trailing Handle
            handle(for: .trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .gesture(dragGesture(for: .trailing))
        }
    }

    private func handle(for edge: Edge) -> some View {
        Capsule()
            .fill(Color.white.opacity(0.8))
            .overlay(Capsule().stroke(Color.accentColor, lineWidth: 2))
            .frame(
                width: edge.isHorizontal ? handleLength : handleThickness,
                height: edge.isHorizontal ? handleThickness : handleLength
            )
    }

    private func dragGesture(for edge: Edge) -> some Gesture {
        DragGesture()
            .onChanged { value in
                handleDragChanged(value: value, edge: edge)
            }
    }

    private func handleDragChanged(value: DragGesture.Value, edge: Edge) {
        let translation = value.translation
        var rect = state.cropRect

        switch edge {
        case .top:
            let delta = translation.height / containerSize.height
            let newY = rect.origin.y + delta
            let newHeight = rect.height - delta
            if newHeight > 0.1 { // minimum 10% height
                state.cropRect.origin.y = newY
                state.cropRect.size.height = newHeight
            }
        case .bottom:
            let delta = translation.height / containerSize.height
            let newHeight = rect.height + delta
            if newHeight > 0.1 {
                state.cropRect.size.height = newHeight
            }
        case .leading:
            let delta = translation.width / containerSize.width
            let newX = rect.origin.x + delta
            let newWidth = rect.width - delta
            if newWidth > 0.1 { // minimum 10% width
                state.cropRect.origin.x = newX
                state.cropRect.size.width = newWidth
            }
        case .trailing:
            let delta = translation.width / containerSize.width
            let newWidth = rect.width + delta
            if newWidth > 0.1 {
                state.cropRect.size.width = newWidth
            }
        default:
            break
        }
        
        // Clamp values to prevent invalid rects
        state.cropRect.origin.x = max(0, state.cropRect.origin.x)
        state.cropRect.origin.y = max(0, state.cropRect.origin.y)
        state.cropRect.size.width = min(1 - state.cropRect.origin.x, state.cropRect.size.width)
        state.cropRect.size.height = min(1 - state.cropRect.origin.y, state.cropRect.size.height)
    }
}

fileprivate extension Edge {
    var isHorizontal: Bool { self == .top || self == .bottom }
    var isVertical: Bool { self == .leading || self == .trailing }
} 
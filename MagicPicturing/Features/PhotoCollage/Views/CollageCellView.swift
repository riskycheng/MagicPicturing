import SwiftUI

struct CollageCellView: View {
    let image: UIImage
    @Binding var state: CollageImageState
    let isSelected: Bool
    
    // States for live gesture tracking
    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    
    var body: some View {
        let _ = print("--- CollageCellView LOG --- isSelected: \(isSelected)")
        return GeometryReader { geometry in
            let magnificationGesture = MagnificationGesture()
                .onChanged { value in
                    self.currentScale = value
                }
                .onEnded { value in
                    state.scale *= value
                    self.currentScale = 1.0
                }
            
            let dragGesture = DragGesture()
                .onChanged { value in
                    self.currentOffset = value.translation
                }
                .onEnded { value in
                    state.offset.width += value.translation.width
                    state.offset.height += value.translation.height
                    self.currentOffset = .zero
                }
            
            let combinedGesture = dragGesture.simultaneously(with: magnificationGesture)

            ZStack {
                // MARK: - Clipped Image
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(x: 1 / state.cropRect.width, y: 1 / state.cropRect.height, anchor: .topLeading)
                        .offset(x: -state.cropRect.origin.x * geometry.size.width / state.cropRect.width, y: -state.cropRect.origin.y * geometry.size.height / state.cropRect.height)
                        .scaleEffect(state.scale * currentScale)
                        .offset(x: state.offset.width + currentOffset.width, y: state.offset.height + currentOffset.height)
                        .rotationEffect(state.rotation)
                        .scaleEffect(x: state.isFlippedHorizontally ? -1 : 1, y: state.isFlippedVertically ? -1 : 1, anchor: .center)
                }
                .clipped()
                .contentShape(Rectangle())
                .gesture(isSelected ? combinedGesture : nil)

                // MARK: - Selection Overlay (not clipped)
                if isSelected {
                    let _ = print("--- BORDER LOG --- Green border and its overlay are being evaluated.")
                    Rectangle()
                        .stroke(Color.green, lineWidth: 4)
                        .overlay(
                            // Ultimate Debug: A simple, hardcoded shape to test rendering.
                            Circle()
                                .fill(Color.red)
                                .frame(width: 50, height: 50)
                        )
                }
            }
        }
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
            .fill(Color.pink)
            .overlay(Capsule().stroke(Color.yellow, lineWidth: 4))
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
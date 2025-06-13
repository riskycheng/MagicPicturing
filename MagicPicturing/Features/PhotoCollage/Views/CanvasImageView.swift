import SwiftUI

struct CanvasImageView: View {
    let state: CanvasImageState
    let isSelected: Bool
    let onUpdate: (CanvasImageState) -> Void
    let onSelect: (String) -> Void
    let onRemove: (String) -> Void
    let allImages: [CanvasImageState]

    // Gesture states
    @State private var dragStartPosition: CGPoint? = nil
    @State private var startScale: CGFloat? = nil
    
    @State private var showGuideLine = false
    @State private var guideLinePos: CGPoint = .zero
    @State private var guideLineAxis: Axis = .horizontal
    
    // Snap threshold
    private let snapThreshold: CGFloat = 10.0

    var body: some View {
        // Define gestures for when the view is selected
        let dragGesture = DragGesture()
            .onChanged { value in
                if dragStartPosition == nil {
                    dragStartPosition = state.position
                }
                guard let startPosition = dragStartPosition else { return }

                var newPos = CGPoint(
                    x: startPosition.x + value.translation.width,
                    y: startPosition.y + value.translation.height
                )
                
                // Snapping logic...
                var snapped = false
                for other in allImages where other.id != state.id {
                    if abs(newPos.x - other.position.x) < snapThreshold {
                        newPos.x = other.position.x
                        showGuideLine = true
                        guideLinePos = CGPoint(x: newPos.x, y: (newPos.y + other.position.y) / 2)
                        guideLineAxis = .vertical
                        snapped = true
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                    if abs(newPos.y - other.position.y) < snapThreshold {
                        newPos.y = other.position.y
                        showGuideLine = true
                        guideLinePos = CGPoint(x: (newPos.x + other.position.x) / 2, y: newPos.y)
                        guideLineAxis = .horizontal
                        snapped = true
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
                if !snapped {
                    showGuideLine = false
                }
                
                var updatedState = state
                updatedState.position = newPos
                onUpdate(updatedState)
            }
            .onEnded { value in
                dragStartPosition = nil
                showGuideLine = false
            }

        let magnificationGesture = MagnificationGesture()
            .onChanged { value in
                if startScale == nil {
                    startScale = state.scale
                }
                guard let startingScale = startScale else { return }
                var updatedState = state
                updatedState.scale = startingScale * value
                onUpdate(updatedState)
            }
            .onEnded { value in
                startScale = nil
            }
        
        let activeGestures = dragGesture.simultaneously(with: magnificationGesture)

        let view = ZStack {
            Image(uiImage: state.image)
                .resizable()
                .scaledToFill()
                .frame(width: state.size.width * state.scale, height: state.size.height * state.scale)
                .rotationEffect(state.rotation)
                .scaleEffect(x: state.isFlippedHorizontally ? -1 : 1, y: state.isFlippedVertically ? -1 : 1)
        }
        .overlay(
            Group {
                if isSelected {
                    Rectangle()
                        .stroke(Color.green, lineWidth: 2)
                }
            }
        )
        .position(x: state.position.x, y: state.position.y)
        .onTapGesture {
            onSelect(state.id)
        }

        // Conditionally apply drag and scale gestures only if the image is selected
        if isSelected {
            return AnyView(view.gesture(activeGestures))
        } else {
            return AnyView(view)
        }
    }
} 
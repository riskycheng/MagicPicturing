import SwiftUI

struct CanvasImageView: View {
    let state: CanvasImageState
    let isSelected: Bool
    let onUpdate: (CanvasImageState) -> Void
    let onSelect: (String) -> Void
    let onRemove: (String) -> Void
    var allImages: [CanvasImageState] = []

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var scale: CGFloat = 1.0
    @State private var showGuideLine: Bool = false
    @State private var guideLinePos: CGPoint = .zero
    @State private var guideLineAxis: Axis? = nil

    let snapThreshold: CGFloat = 20

    var body: some View {
        ZStack {
            Image(uiImage: state.image)
                .resizable()
                .frame(width: state.size.width, height: state.size.height)
                .scaleEffect(state.scale * scale)
                .rotationEffect(state.rotation)
                .position(x: state.position.x + dragOffset.width, y: state.position.y + dragOffset.height)
                .border(isSelected ? Color.blue : Color.clear, width: 3)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onChanged { value in
                            var newPos = CGPoint(x: state.position.x + value.translation.width, y: state.position.y + value.translation.height)
                            var snapped = false
                            for other in allImages where other.id != state.id {
                                if abs(newPos.x - other.position.x) < snapThreshold {
                                    newPos.x = other.position.x
                                    showGuideLine = true
                                    guideLinePos = CGPoint(x: newPos.x, y: newPos.y)
                                    guideLineAxis = .vertical
                                    snapped = true
                                    UISelectionFeedbackGenerator().selectionChanged()
                                }
                                if abs(newPos.y - other.position.y) < snapThreshold {
                                    newPos.y = other.position.y
                                    showGuideLine = true
                                    guideLinePos = CGPoint(x: newPos.x, y: newPos.y)
                                    guideLineAxis = .horizontal
                                    snapped = true
                                    UISelectionFeedbackGenerator().selectionChanged()
                                }
                            }
                            if !snapped { showGuideLine = false }
                        }
                        .onEnded { value in
                            var newState = state
                            newState.position.x += value.translation.width
                            newState.position.y += value.translation.height
                            onUpdate(newState)
                            showGuideLine = false
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .updating($scale) { value, state, _ in
                            state = value
                        }
                        .onEnded { value in
                            var newState = state
                            newState.scale *= value
                            onUpdate(newState)
                        }
                )
                .onTapGesture {
                    onSelect(state.id)
                }
                .contextMenu {
                    Button("移回底部") {
                        onRemove(state.id)
                    }
                }
            if showGuideLine, let axis = guideLineAxis {
                if axis == .vertical {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 2, height: 200)
                        .position(x: guideLinePos.x, y: guideLinePos.y)
                } else {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 200, height: 2)
                        .position(x: guideLinePos.x, y: guideLinePos.y)
                }
            }
        }
    }
} 
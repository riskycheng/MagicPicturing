import SwiftUI

struct CanvasImageView: View {
    let state: CanvasImageState
    let isSelected: Bool
    let onUpdate: (CanvasImageState) -> Void
    let onSelect: (String) -> Void
    let onRemove: (String) -> Void
    let allImages: [CanvasImageState]

    // Gesture states
    @State private var previousMoveLocation: CGPoint? = nil
    @State private var startImageOffset: CGPoint? = nil
    @State private var startScale: CGFloat? = nil
    
    @State private var showGuideLine = false
    @State private var guideLinePos: CGPoint = .zero
    @State private var guideLineAxis: Axis = .horizontal
    
    // Snap threshold
    private let snapThreshold: CGFloat = 10.0

    // To identify which handle is being dragged
    @State private var draggingHandle: Edge? = nil
    @State private var draggingMoveHandle = false

    var body: some View {
        // Define gestures for when the view is selected
        let dragGesture = DragGesture()
            .onChanged { value in
                guard draggingHandle == nil, !draggingMoveHandle else { return }

                if startImageOffset == nil {
                    startImageOffset = state.imageOffset
                }
                guard let startOffset = startImageOffset else { return }

                var updatedState = state
                let newOffsetX = startOffset.x + value.translation.width
                let newOffsetY = startOffset.y + value.translation.height
                
                let scaledImageSize = CGSize(
                    width: state.image.size.width * state.scale,
                    height: state.image.size.height * state.scale
                )

                let xLimit = (scaledImageSize.width - state.size.width) / 2
                let yLimit = (scaledImageSize.height - state.size.height) / 2

                if xLimit > 0 {
                    updatedState.imageOffset.x = max(-xLimit, min(xLimit, newOffsetX))
                } else {
                    updatedState.imageOffset.x = 0
                }

                if yLimit > 0 {
                    updatedState.imageOffset.y = max(-yLimit, min(yLimit, newOffsetY))
                } else {
                    updatedState.imageOffset.y = 0
                }
                
                onUpdate(updatedState)
            }
            .onEnded { value in
                startImageOffset = nil
            }

        let magnificationGesture = MagnificationGesture()
            .onChanged { value in
                guard draggingHandle == nil, !draggingMoveHandle else { return }
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
                .scaleEffect(state.scale)
                .frame(
                    width: state.image.size.width * state.scale,
                    height: state.image.size.height * state.scale
                )
                .offset(x: state.imageOffset.x, y: state.imageOffset.y)
        }
        .frame(width: state.size.width, height: state.size.height)
        .clipped()
        .rotationEffect(state.rotation)
        .scaleEffect(x: state.isFlippedHorizontally ? -1 : 1, y: state.isFlippedVertically ? -1 : 1)
        .overlay(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.green, lineWidth: 2)

                    // Handles for cropping
                    let handleWidth: CGFloat = 44
                    let handleHeight: CGFloat = 44
                    let visualHandleWidth: CGFloat = 40
                    let visualHandleHeight: CGFloat = 6

                    // Top handle
                    handleView(for: .top, width: handleWidth, height: handleHeight, visualWidth: visualHandleWidth, visualHeight: visualHandleHeight)
                        .position(x: state.size.width / 2, y: 0)
                    
                    // Bottom handle
                    handleView(for: .bottom, width: handleWidth, height: handleHeight, visualWidth: visualHandleWidth, visualHeight: visualHandleHeight)
                        .position(x: state.size.width / 2, y: state.size.height)

                    // Left handle
                    handleView(for: .leading, width: handleWidth, height: handleHeight, visualWidth: visualHandleHeight, visualHeight: visualHandleWidth)
                        .position(x: 0, y: state.size.height / 2)
                    
                    // Right handle
                    handleView(for: .trailing, width: handleWidth, height: handleHeight, visualWidth: visualHandleHeight, visualHeight: visualHandleWidth)
                        .position(x: state.size.width, y: state.size.height / 2)

                    // Center move handle
                    moveHandleView()
                        .position(x: state.size.width / 2, y: state.size.height / 2)
                }
            }
        )
        .position(x: state.position.x, y: state.position.y)
        .onTapGesture {
            onSelect(state.id)
        }

        // Conditionally apply drag and scale gestures only if the image is selected
        if isSelected {
            return AnyView(view.gesture(activeGestures).gesture(cropGesture()))
        } else {
            return AnyView(view)
        }
    }

    // Helper to create a handle view with a gesture
    @ViewBuilder
    private func handleView(for edge: Edge, width: CGFloat, height: CGFloat, visualWidth: CGFloat, visualHeight: CGFloat) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: width, height: height)
            .contentShape(Rectangle())
            .overlay(
                Capsule()
                    .fill(Color.green)
                    .frame(width: visualWidth, height: visualHeight)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !draggingMoveHandle else { return }
                        if draggingHandle == nil {
                            draggingHandle = edge
                        }
                        guard draggingHandle == edge else { return }

                        var updatedState = state
                        let translation = value.translation
                        
                        let scaledImageSize = CGSize(
                            width: state.image.size.width * state.scale,
                            height: state.image.size.height * state.scale
                        )

                        switch edge {
                        case .top:
                            let delta = translation.height
                            let newHeight = updatedState.size.height - delta
                            let maxCropHeight = scaledImageSize.height - 2 * updatedState.imageOffset.y
                            if newHeight > 0, newHeight <= maxCropHeight {
                                updatedState.size.height = newHeight
                                updatedState.position.y += delta / 2
                                updatedState.imageOffset.y -= delta / 2
                            }
                        case .bottom:
                            let delta = translation.height
                            let newHeight = updatedState.size.height + delta
                            let maxCropHeight = scaledImageSize.height + 2 * updatedState.imageOffset.y
                            if newHeight > 0, newHeight <= maxCropHeight {
                                updatedState.size.height = newHeight
                                updatedState.position.y += delta / 2
                                updatedState.imageOffset.y -= delta / 2
                            }
                        case .leading:
                            let delta = translation.width
                            let newWidth = updatedState.size.width - delta
                            let maxCropWidth = scaledImageSize.width - 2 * updatedState.imageOffset.x
                            if newWidth > 0, newWidth <= maxCropWidth {
                                updatedState.size.width = newWidth
                                updatedState.position.x += delta / 2
                                updatedState.imageOffset.x -= delta / 2
                            }
                        case .trailing:
                            let delta = translation.width
                            let newWidth = updatedState.size.width + delta
                            let maxCropWidth = scaledImageSize.width + 2 * updatedState.imageOffset.x
                            if newWidth > 0, newWidth <= maxCropWidth {
                                updatedState.size.width = newWidth
                                updatedState.position.x += delta / 2
                                updatedState.imageOffset.x -= delta / 2
                            }
                        }
                        onUpdate(updatedState)
                    }
                    .onEnded { _ in
                        draggingHandle = nil
                    }
            )
    }

    @ViewBuilder
    private func moveHandleView() -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                .background(Circle().fill(Color.black.opacity(0.3)))
                .frame(width: 32, height: 32)
            
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .foregroundColor(Color.white.opacity(0.9))
                .font(.system(size: 16))
        }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if !draggingMoveHandle {
                        draggingMoveHandle = true
                        previousMoveLocation = value.location
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    
                    guard let previousLocation = previousMoveLocation else { return }

                    let delta = CGPoint(
                        x: value.location.x - previousLocation.x,
                        y: value.location.y - previousLocation.y
                    )

                    var newPos = CGPoint(
                        x: state.position.x + delta.x,
                        y: state.position.y + delta.y
                    )

                    self.previousMoveLocation = value.location
                    
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
                .onEnded { _ in
                    draggingMoveHandle = false
                    previousMoveLocation = nil
                    showGuideLine = false
                }
        )
    }

    private func cropGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                // This gesture is now handled by the handle views
            }
    }
} 
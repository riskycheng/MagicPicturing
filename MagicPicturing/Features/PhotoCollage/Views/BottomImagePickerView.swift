import SwiftUI

struct BottomImagePickerView: View {
    let images: [CanvasViewModel.UIImageWithID]
    let onDragStart: (CanvasViewModel.UIImageWithID, CGPoint, CGRect) -> Void
    let onDragUpdate: (CGPoint) -> Void
    let onDragEnd: (CGPoint?) -> Void

    @State private var pressedImageID: String? = nil
    @State private var dragStarted: [String: Bool] = [:]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 0) {
                ForEach(images) { img in
                    ZStack {
                        GeometryReader { geo in
                            Image(uiImage: img.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .contentShape(Rectangle())
                                .scaleEffect(pressedImageID == img.id ? 0.92 : 1.0)
                                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressedImageID == img.id)
                                .gesture(
                                    LongPressGesture(minimumDuration: 0.05)
                                        .onEnded { _ in
                                            pressedImageID = img.id
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        }
                                )
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0, coordinateSpace: .named("workspace"))
                                        .onChanged { value in
                                            let frame = geo.frame(in: .global)
                                            if dragStarted[img.id] != true {
                                                // 第一次拖动，触发onDragStart
                                                onDragStart(img, value.location, frame)
                                                dragStarted[img.id] = true
                                            } else {
                                                // 后续持续更新位置
                                                onDragUpdate(value.location)
                                            }
                                        }
                                        .onEnded { value in
                                            onDragEnd(value.location)
                                            pressedImageID = nil
                                            dragStarted[img.id] = false
                                        }
                                )
                        }
                        .frame(width: 60, height: 60)
                    }
                    .frame(width: 60, height: 60)
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.1))
    }
} 
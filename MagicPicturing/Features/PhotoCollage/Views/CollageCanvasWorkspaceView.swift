import SwiftUI
import Photos

struct CollageCanvasWorkspaceView: View {
    @StateObject private var viewModel: CanvasViewModel
    let canvasSize = CGSize(width: UIScreen.main.bounds.width - 32, height: UIScreen.main.bounds.width - 32)

    // 新增：管理当前悬浮拖拽图片和位置
    @State private var draggingImage: CanvasViewModel.UIImageWithID? = nil
    @State private var dragPosition: CGPoint? = nil
    @State private var isDragging: Bool = false

    // 画布区域的全局frame
    @State private var canvasFrame: CGRect = .zero

    init(selectedAssets: [PHAsset], images: [UIImage]) {
        _viewModel = StateObject(wrappedValue: CanvasViewModel(selectedAssets: selectedAssets, images: images))
    }

    var body: some View {
        ZStack {
            VStack {
                CanvasView(viewModel: viewModel, canvasSize: canvasSize)
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .padding(.top, 32)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    canvasFrame = geo.frame(in: .global)
                                }
                                .onChange(of: geo.frame(in: .global)) { newValue in
                                    canvasFrame = newValue
                                }
                        }
                    )
                Spacer()
                BottomImagePickerView(
                    images: viewModel.bottomImages,
                    onDragStart: { img, startLocation, imageFrame in
                        draggingImage = img
                        dragPosition = startLocation
                        isDragging = true
                    },
                    onDragUpdate: { location in
                        dragPosition = location
                    },
                    onDragEnd: { location in
                        if let img = draggingImage, let pos = location {
                            // The drop point is the final center of the dragged image preview, which is the finger's last position
                            let dropPoint = pos
                            if canvasFrame.contains(dropPoint) {
                                // Convert to canvas-local coordinates
                                let canvasPoint = CGPoint(x: dropPoint.x - canvasFrame.minX, y: dropPoint.y - canvasFrame.minY)
                                viewModel.addImage(at: canvasPoint, image: img, canvasSize: canvasSize)
                            }
                        }
                        draggingImage = nil
                        dragPosition = nil
                        isDragging = false
                    }
                )
            }

            if let draggingImage = draggingImage, let dragPosition = dragPosition, isDragging {
                Image(uiImage: draggingImage.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .opacity(0.8)
                    .position(x: dragPosition.x, y: dragPosition.y)
                    .allowsHitTesting(false)
                    .zIndex(10)
            }
        }
        .coordinateSpace(name: "workspace")
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
} 
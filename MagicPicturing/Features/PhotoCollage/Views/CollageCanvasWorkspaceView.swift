import SwiftUI
import Photos

struct CollageCanvasWorkspaceView: View {
    @StateObject private var viewModel: CanvasViewModel
    let canvasSize = CGSize(width: UIScreen.main.bounds.width - 32, height: UIScreen.main.bounds.width - 32)

    // 新增：管理当前悬浮拖拽图片和位置
    @State private var draggingImage: CanvasViewModel.UIImageWithID? = nil
    @State private var dragPosition: CGPoint? = nil
    @State private var isDragging: Bool = false
    @State private var dragImageOffset: CGSize? = nil // 新增，记录手指在图片内的偏移

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
                        let offset = CGSize(width: startLocation.x - imageFrame.minX, height: startLocation.y - imageFrame.minY)
                        dragImageOffset = offset
                        isDragging = true
                    },
                    onDragUpdate: { location in
                        dragPosition = location
                    },
                    onDragEnd: { location in
                        if let img = draggingImage, let pos = location, let offset = dragImageOffset {
                            let dropPoint = CGPoint(x: pos.x - offset.width + 40, y: pos.y - offset.height + 40)
                            if canvasFrame.contains(dropPoint) {
                                let canvasPoint = CGPoint(x: dropPoint.x - canvasFrame.minX, y: dropPoint.y - canvasFrame.minY)
                                viewModel.addImage(at: canvasPoint, image: img, canvasSize: canvasSize)
                            }
                        }
                        draggingImage = nil
                        dragPosition = nil
                        dragImageOffset = nil
                        isDragging = false
                    }
                )
            }

            if let draggingImage = draggingImage, let dragPosition = dragPosition, let offset = dragImageOffset, isDragging {
                Image(uiImage: draggingImage.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .opacity(0.8)
                    .position(x: dragPosition.x - offset.width + 40, y: dragPosition.y - offset.height + 40)
                    .allowsHitTesting(false)
                    .zIndex(10)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
} 
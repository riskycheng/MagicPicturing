import SwiftUI
import Photos

struct CanvasImageState: Identifiable {
    let id: String // asset.localIdentifier
    var image: UIImage
    var position: CGPoint
    var scale: CGFloat // a new property to control the scale of the image within the frame
    var rotation: Angle
    var size: CGSize // this will now represent the size of the crop frame
    var imageOffset: CGPoint = .zero // new property to control the offset of the image within the frame
    var isSelected: Bool
    var isFlippedHorizontally: Bool = false
    var isFlippedVertically: Bool = false
}

class CanvasViewModel: ObservableObject {
    @Published var canvasImages: [CanvasImageState] = []
    @Published var selectedImageID: String? = nil
    @Published var bottomImages: [UIImageWithID] = [] // 未拖入画布的图片

    struct UIImageWithID: Identifiable {
        let id: String
        let image: UIImage
    }

    // 初始化时传入所有已选图片
    init(selectedAssets: [PHAsset], images: [UIImage]) {
        // 保证顺序一致
        self.bottomImages = zip(selectedAssets, images).map { asset, img in
            UIImageWithID(id: asset.localIdentifier, image: img)
        }
    }

    // 拖入画布
    func addImageToCanvas(_ image: UIImageWithID) {
        // 自动排布：每张图片初始位置错开
        let offset = CGFloat(canvasImages.count) * 60
        let state = CanvasImageState(
            id: image.id,
            image: image.image,
            position: CGPoint(x: 120 + offset, y: 120 + offset),
            scale: 1.0,
            rotation: .zero,
            size: CGSize(width: 120, height: 120),
            isSelected: false,
            isFlippedHorizontally: false,
            isFlippedVertically: false
        )
        canvasImages.append(state)
        // 从底部移除
        bottomImages.removeAll { $0.id == image.id }
    }

    // 拖回底部
    func removeImageFromCanvas(_ id: String) {
        if let idx = canvasImages.firstIndex(where: { $0.id == id }) {
            let img = canvasImages[idx]
            bottomImages.append(UIImageWithID(id: img.id, image: img.image))
            canvasImages.remove(at: idx)
        }
    }

    // 更新图片状态
    func updateImage(_ updated: CanvasImageState) {
        if let idx = canvasImages.firstIndex(where: { $0.id == updated.id }) {
            canvasImages[idx] = updated
        }
    }

    // 拖入画布（指定位置）
    func addImage(at point: CGPoint, image: UIImageWithID, canvasSize: CGSize) {
        // 限制图片中心点不能超出画布
        let safeX = min(max(point.x, 60), canvasSize.width - 60)
        let safeY = min(max(point.y, 60), canvasSize.height - 60)
        
        // 根据图片原始比例计算尺寸
        let aspectRatio = image.image.size.height > 0 ? image.image.size.width / image.image.size.height : 1.0
        let initialWidth: CGFloat = 150
        let initialSize = CGSize(width: initialWidth, height: initialWidth / aspectRatio)

        let state = CanvasImageState(
            id: image.id,
            image: image.image,
            position: CGPoint(x: safeX, y: safeY),
            scale: 1.0,
            rotation: .zero,
            size: initialSize,
            isSelected: false,
            isFlippedHorizontally: false,
            isFlippedVertically: false
        )
        canvasImages.append(state)
        // 从底部移除
        bottomImages.removeAll { $0.id == image.id }
    }
} 
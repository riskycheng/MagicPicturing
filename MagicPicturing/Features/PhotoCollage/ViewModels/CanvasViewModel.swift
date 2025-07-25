import SwiftUI
import Photos
import Combine

class CanvasImageState: Identifiable, ObservableObject {
    let id: String // asset.localIdentifier
    @Published var image: UIImage
    @Published var position: CGPoint
    @Published var scale: CGFloat
    @Published var rotation: Angle
    @Published var size: CGSize
    @Published var imageOffset: CGPoint = .zero
    @Published var isSelected: Bool
    @Published var isFlippedHorizontally: Bool = false
    @Published var isFlippedVertically: Bool = false
    
    init(id: String, image: UIImage, position: CGPoint, scale: CGFloat, rotation: Angle, size: CGSize, isSelected: Bool) {
        self.id = id
        self.image = image
        self.position = position
        self.scale = scale
        self.rotation = rotation
        self.size = size
        self.isSelected = isSelected
    }
}

class CanvasViewModel: ObservableObject {
    @Published var assets: [PHAsset]
    @Published var canvasImages: [CanvasImageState] = []
    @Published var selectedImageID: String? = nil
    @Published var bottomImages: [UIImageWithID] = [] // 未拖入画布的图片

    private var cancellables = Set<AnyCancellable>()

    struct UIImageWithID: Identifiable {
        let id: String
        let image: UIImage
    }

    init(initialAssets: [PHAsset]) {
        self.assets = initialAssets
        
        $assets
            .removeDuplicates()
            .sink { [weak self] newAssets in
                self?.loadBottomImages(from: newAssets)
            }
            .store(in: &cancellables)
    }

    private func loadBottomImages(from assets: [PHAsset]) {
        // Only load images that are not already on the canvas
        let canvasAssetIDs = Set(canvasImages.map { $0.id })
        let assetsToLoad = assets.filter { !canvasAssetIDs.contains($0.localIdentifier) }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        // Use a smaller size for thumbnails at the bottom for better performance
        let targetSize = CGSize(width: 200, height: 200)

        var loadedImages: [UIImageWithID] = []
        let dispatchGroup = DispatchGroup()

        for asset in assetsToLoad {
            dispatchGroup.enter()
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                if let image = image {
                    loadedImages.append(UIImageWithID(id: asset.localIdentifier, image: image))
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            // Reorder to match asset order
            let assetOrder = assets.map { $0.localIdentifier }
            self.bottomImages = loadedImages.sorted {
                let firstIndex = assetOrder.firstIndex(of: $0.id) ?? -1
                let secondIndex = assetOrder.firstIndex(of: $1.id) ?? -1
                return firstIndex < secondIndex
            }
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
            isSelected: false
        )
        canvasImages.append(state)
        // 从底部移除
        bottomImages.removeAll { $0.id == image.id }
    }

    // 拖回底部
    func removeImageFromCanvas(_ id: String) {
        if let idx = canvasImages.firstIndex(where: { $0.id == id }) {
            let imgState = canvasImages[idx]
            // We need to refetch a thumbnail version for the bottom bar.
            // A simpler approach for now is to just add it back to assets, which will trigger a reload.
            if let asset = assets.first(where: { $0.localIdentifier == imgState.id }) {
                 // This will trigger the sink in init and reload the bottom bar
                 // (This is a simplified approach. A more direct one would be to just add it to bottomImages.)
            }
            canvasImages.remove(at: idx)
            loadBottomImages(from: assets) // Explicitly reload bottom images
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

        // Create the state with the initial low-res thumbnail
        let state = CanvasImageState(
            id: image.id,
            image: image.image,
            position: CGPoint(x: safeX, y: safeY),
            scale: 1.0,
            rotation: .zero,
            size: initialSize,
            isSelected: false
        )
        canvasImages.append(state)
        
        // Remove from bottom bar
        bottomImages.removeAll { $0.id == image.id }

        // Asynchronously fetch the full-resolution image and update the state
        guard let originalAsset = assets.first(where: { $0.localIdentifier == image.id }) else { return }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(for: originalAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { fullResImage, _ in
            DispatchQueue.main.async {
                if let fullResImage = fullResImage {
                    // Find the state object and update its image.
                    // Because CanvasImageState is a class and its 'image' property is @Published,
                    // the corresponding CanvasImageView will update automatically.
                    if let existingState = self.canvasImages.first(where: { $0.id == image.id }) {
                        existingState.image = fullResImage
                    }
                }
            }
        }
    }
} 
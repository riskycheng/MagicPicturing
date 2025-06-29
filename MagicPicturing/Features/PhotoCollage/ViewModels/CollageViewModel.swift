import SwiftUI
import Combine
import Photos

class CollageViewModel: ObservableObject {
    // Inputs
    @Published var assets: [PHAsset]

    // Outputs
    @Published var imageStates: [CollageImageState] = []
    @Published var availableLayouts: [CollageLayout] = []
    @Published var selectedLayout: CollageLayout? {
        didSet {
            setupLayoutSubscription()
        }
    }
    @Published var selectedImageIndex: Int?

    // Background & Border
    @Published var backgroundColor: Color = Color(.systemBackground) {
        didSet {
            // Any change to solid color clears the gradient
            if backgroundGradient != nil {
                backgroundGradient = nil
            }
        }
    }
    @Published var backgroundGradient: Gradient?
    @Published var backgroundMaterialOpacity: CGFloat = 0.0
    @Published var borderWidth: CGFloat = 4
    @Published var cornerRadius: CGFloat = 0
    @Published var shadowRadius: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()
    private var layoutCancellable: AnyCancellable?
    private var isUpdatingLayout = false
    
    init(initialAssets: [PHAsset]) {
        self.assets = initialAssets
        
        $assets
            .removeDuplicates()
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] newAssets in
                self?.setupCollage(with: newAssets)
            }
            .store(in: &cancellables)
    }
    
    func add(assets newAssets: [PHAsset]) {
        let existingAssetIDs = Set(self.assets.map { $0.localIdentifier })
        let uniqueNewAssets = newAssets.filter { !existingAssetIDs.contains($0.localIdentifier) }
        
        if !uniqueNewAssets.isEmpty {
            self.assets.append(contentsOf: uniqueNewAssets)
        }
    }

    private func setupLayoutSubscription() {
        layoutCancellable?.cancel()
        layoutCancellable = selectedLayout?.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    private func setupCollage(with assets: [PHAsset]) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        
        let targetSize = PHImageManagerMaximumSize
        var loadedImageStates: [CollageImageState?] = Array(repeating: nil, count: assets.count)
        let dispatchGroup = DispatchGroup()

        for (index, asset) in assets.enumerated() {
            dispatchGroup.enter()
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                if let image = image {
                    let existingState = self.imageStates.first { $0.assetId == asset.localIdentifier }
                    if let state = existingState {
                        state.image = image // Update image in case it was a low-res thumbnail
                        loadedImageStates[index] = state
                    } else {
                        loadedImageStates[index] = CollageImageState(image: image, assetId: asset.localIdentifier)
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let newImageStates = loadedImageStates.compactMap { $0 }
            
            // Reorder newImageStates to match the order of assets
            let assetOrder = assets.map { $0.localIdentifier }
            self.imageStates = newImageStates.sorted {
                let firstIndex = assetOrder.firstIndex(of: $0.assetId) ?? -1
                let secondIndex = assetOrder.firstIndex(of: $1.assetId) ?? -1
                return firstIndex < secondIndex
            }

            self.loadLayouts()
        }
    }

    private func loadLayouts() {
        let currentImageCount = self.imageStates.count
        
        let isCurrentLayoutStillValid = selectedLayout?.cellStates.count == currentImageCount
        
        self.availableLayouts = JSONCollageLayoutProvider().loadTemplates(for: currentImageCount)
        
        if isCurrentLayoutStillValid, let currentLayoutName = selectedLayout?.name {
            self.selectedLayout = availableLayouts.first { $0.name == currentLayoutName } ?? availableLayouts.first
        } else {
            self.selectedLayout = availableLayouts.first
        }
    }
    
    // MARK: - Image State Manipulation
    
    func rotateSelectedImage() {
        guard let index = selectedImageIndex else { return }
        imageStates[index].rotation += .degrees(90)
    }
    
    func flipSelectedImageHorizontally() {
        guard let index = selectedImageIndex else { return }
        imageStates[index].isFlippedHorizontally.toggle()
    }
    
    func flipSelectedImageVertically() {
        guard let index = selectedImageIndex else { return }
        imageStates[index].isFlippedVertically.toggle()
    }
    
    func swapImages(from sourceIndex: Int, to destinationIndex: Int) {
        imageStates.swapAt(sourceIndex, destinationIndex)
    }

    func exportCollage(in windowScene: UIWindowScene?, completion: @escaping (Error?) -> Void) {
        print("[Export] Starting export process...")

        // Give SwiftUI a moment to ensure the view hierarchy is up to date.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("[Export] Attempting to get frame for 'collage_preview'")
            guard let frame = ViewFinder.getFrame(for: "collage_preview") else {
                completion(NSError(domain: "CollageApp", code: -5, userInfo: [NSLocalizedDescriptionKey: "未能获取拼贴画坐标，请稍后再试。"]))
                return
            }

            print("[Export] Frame obtained: \(frame). Taking screenshot.")
            let view = Color.clear // An empty view to call the snapshotter
            guard let fullScreenImage = view.snapshotScreen(in: windowScene) else {
                completion(NSError(domain: "CollageApp", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to take screenshot."]))
                return
            }

            print("[Export] Screenshot taken. Cropping image.")
            let scale = UIScreen.main.scale
            let cropRect = CGRect(
                x: frame.origin.x * scale,
                y: frame.origin.y * scale,
                width: frame.size.width * scale,
                height: frame.size.height * scale
            )

            guard let cgImage = fullScreenImage.cgImage?.cropping(to: cropRect.integral) else {
                print("[Export] ERROR: Cropping failed.")
                completion(NSError(domain: "CollageApp", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to crop image."]))
                return
            }
            
            print("[Export] Cropping successful. Saving image.")
            let croppedImage = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
            PhotoLibraryService.save(image: croppedImage, completion: completion)
        }
    }

    func saveImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        PhotoLibraryService.save(image: image) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving image: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Image saved successfully")
                    completion(true)
                }
            }
        }
    }

    private func fetchImages() {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        // ... existing code ...
    }

    func removeImage(at index: Int) {
        self.imageStates.remove(at: index)
        self.assets.remove(at: index)
        
        // After removing an image, the available layouts might change.
        updateLayouts()
    }

    func selectLayout(_ layout: CollageLayout) {
        let newLayout = layout.copy()
        self.selectedLayout = newLayout
    }

    func updateLayouts() {
        let currentImageCount = self.imageStates.count
        
        let isCurrentLayoutStillValid = selectedLayout?.cellStates.count == currentImageCount
        
        self.availableLayouts = JSONCollageLayoutProvider().loadTemplates(for: currentImageCount)
        
        if !isCurrentLayoutStillValid {
            self.selectedLayout = availableLayouts.first
        }
    }

    func resetLayoutParameters() {
        // ... (existing code)
    }

    func setRandomGradientBackground() {
        let randomColor1 = Color.random()
        let randomColor2 = Color.random()
        self.backgroundGradient = Gradient(colors: [randomColor1, randomColor2])
    }
} 
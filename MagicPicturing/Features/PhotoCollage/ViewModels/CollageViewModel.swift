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

    // MARK: - Collage Style Properties
    @Published var borderWidth: CGFloat = 4
    @Published var cornerRadius: CGFloat = 0
    @Published var shadowRadius: CGFloat = 0
    @Published var backgroundBlur: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()
    private var layoutCancellable: AnyCancellable?
    
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
        
        let isCurrentLayoutStillValid = selectedLayout?.frames.count == currentImageCount
        
        self.availableLayouts = CollageLayoutProvider.getLayouts(for: currentImageCount)
        
        if isCurrentLayoutStillValid, let currentLayoutId = selectedLayout?.id {
            self.selectedLayout = availableLayouts.first { $0.id == currentLayoutId } ?? availableLayouts.first
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

    func exportCollage(completion: @escaping (Error?) -> Void) {
        guard let layout = selectedLayout else {
            completion(NSError(domain: "CollageApp", code: -1, userInfo: [NSLocalizedDescriptionKey: "No layout selected."]))
            return
        }

        let collageView = CollagePreviewView(viewModel: self)
            .frame(width: 2048, height: 2048) // High resolution export

        guard let image = collageView.snapshot() else {
            completion(NSError(domain: "CollageApp", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to render image."]))
            return
        }
        
        PhotoLibraryService.save(image: image, completion: completion)
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
} 
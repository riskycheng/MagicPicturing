import SwiftUI
import Combine
import Photos

class CollageViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    @Published var availableLayouts: [CollageLayout] = []
    @Published var selectedLayout: CollageLayout?

    private var assets: [PHAsset]
    private let photoLibraryService = PhotoLibraryService()
    
    init(assets: [PHAsset]) {
        self.assets = assets
        loadFullSizeImages()
    }

    private func loadFullSizeImages() {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false // Perform asynchronously
        
        let targetSize = PHImageManagerMaximumSize // Fetch full resolution
        var loadedImages: [UIImage?] = Array(repeating: nil, count: assets.count)
        let dispatchGroup = DispatchGroup()

        for (index, asset) in assets.enumerated() {
            dispatchGroup.enter()
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
                if let image = image {
                    loadedImages[index] = image
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.images = loadedImages.compactMap { $0 }
            
            self.loadLayouts()
        }
    }

    func loadLayouts() {
        // This will be populated by CollageLayoutProvider
        self.availableLayouts = CollageLayoutProvider.getLayouts(for: self.images.count)
        self.selectedLayout = availableLayouts.first
    }
    
    func exportCollage(completion: @escaping (Error?) -> Void) {
        guard let layout = selectedLayout else {
            completion(NSError(domain: "CollageApp", code: -1, userInfo: [NSLocalizedDescriptionKey: "No layout selected."]))
            return
        }

        let collageView = CollagePreviewView(images: images, layout: layout)
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
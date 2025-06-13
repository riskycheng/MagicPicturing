import SwiftUI
import Photos
import Combine

class PhotoLibraryService {
    
    static func requestAuthorization(completion: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            switch status {
            case .authorized, .limited:
                print("Photo Library access granted.")
                DispatchQueue.main.async {
                    completion()
                }
                
            case .denied, .restricted:
                print("Photo Library access denied.")
                // Here you might want to show an alert to the user.
                
            case .notDetermined:
                print("Photo Library access not determined.")
                
            @unknown default:
                fatalError()
            }
        }
    }
    
    static func fetchAllPhotos(completion: @escaping ([PHAsset]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var assets: [PHAsset] = []
            fetchResult.enumerateObjects { (asset, _, _) in
                assets.append(asset)
            }
            
            DispatchQueue.main.async {
                print("LOG: fetchAllPhotos order: \(assets.map { $0.localIdentifier })")
                completion(assets)
            }
        }
    }
    
    static func fetchImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
            completion(image)
        }
    }
    
    static func save(image: UIImage, completion: @escaping (Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { _, error in
            DispatchQueue.main.async {
                completion(error)
            }
        }
    }
    
    // Additional methods to fetch photos and save images will be added here.
    
} 
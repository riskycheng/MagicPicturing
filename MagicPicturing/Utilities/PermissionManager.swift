import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
import Photos

class PermissionManager {
    enum PermissionType {
        case photoLibrary
        case photoLibraryAddOnly
    }
    
    static func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    static func checkPhotoLibraryPermission() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    static func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// Extension to save images safely
extension UIImage {
    func saveToPhotoLibrary(completion: @escaping (Bool, Error?) -> Void) {
        PermissionManager.requestPhotoLibraryPermission { granted in
            if granted {
                UIImageWriteToSavedPhotosAlbum(self, nil, nil, nil)
                completion(true, nil)
            } else {
                completion(false, NSError(domain: "PermissionDenied", code: 403, userInfo: [NSLocalizedDescriptionKey: "Photo library permission denied"]))
            }
        }
    }
}
#endif

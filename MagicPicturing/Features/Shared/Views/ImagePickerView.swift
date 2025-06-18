import SwiftUI
import Photos
import UIKit
import AnyImageKit

fileprivate struct SelectionState {
    let isSelected: Bool
    let selectionIndex: Int?
}

// 1. Coordinator to handle delegate callbacks
class ImagePickerCoordinator: NSObject, ImagePickerControllerDelegate {
    var parent: ImagePickerView

    init(_ parent: ImagePickerView) {
        self.parent = parent
    }

    func imagePicker(_ picker: ImagePickerController, didFinishPicking result: PickerResult) {
        let assets = result.assets.map { $0.phAsset }
        let images = result.assets.map { $0.image }

        picker.dismiss(animated: true) {
            // Check if the number of selected images meets the minimum requirement
            if images.count >= self.parent.minSelection {
                self.parent.onNext(assets, images)
            } else {
                // If not enough images are selected, treat it as a cancellation.
                self.parent.onCancel()
            }
        }
    }

    func imagePickerDidCancel(_ picker: ImagePickerController) {
        picker.dismiss(animated: true) {
            self.parent.onCancel()
        }
    }
}

// 2. UIViewControllerRepresentable to wrap the UIKit controller
struct ImagePickerView: UIViewControllerRepresentable {
    
    // Callbacks and configuration
    var onCancel: () -> Void
    var onNext: ([PHAsset], [UIImage]) -> Void
    var selectionLimit: Int = 9
    var minSelection: Int = 2

    func makeCoordinator() -> ImagePickerCoordinator {
        ImagePickerCoordinator(self)
    }

    func makeUIViewController(context: Context) -> ImagePickerController {
        var options = PickerOptionsInfo()
        
        // --- Correct API Configuration based on the provided source code ---
        
        // Max selection limit - This is the correct property name
        options.selectLimit = selectionLimit
        
        // Enable editor
        options.editorOptions = .photo
        
        // Set selection tap action
        options.selectionTapAction = .openEditor
        
        // Configure editor tools
        var editorPhotoOptions = EditorPhotoOptionsInfo()
        editorPhotoOptions.toolOptions = [.pen, .text, .crop, .mosaic]
        options.editorPhotoOptions = editorPhotoOptions

        // Removing theme customization for now to ensure compilation
        // options.theme.tintColor = UIColor.green
        
        let controller = ImagePickerController(options: options, delegate: context.coordinator)
        controller.modalPresentationStyle = .fullScreen
        return controller
    }

    func updateUIViewController(_ uiViewController: ImagePickerController, context: Context) {
        // Not needed for this implementation
    }
}

// MARK: - Photo Cell
private struct PhotoCell: View {
    let asset: PHAsset
    let selectionState: SelectionState?
    @Binding var imageDict: [String: UIImage]
    @State private var image: UIImage? = nil
    private let imageSize = UIScreen.main.bounds.width / 3

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: imageSize, height: imageSize)
        .clipped()
        .overlay(
            Group {
                if let state = selectionState, state.isSelected {
                    ZStack(alignment: .topTrailing) {
                        Color.black.opacity(0.4)
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 4)
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(state.selectionIndex ?? 0)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .padding(4)
                    }
                }
            }
        )
        .onAppear {
            let retinaSize = CGSize(width: imageSize * UIScreen.main.scale, height: imageSize * UIScreen.main.scale)
            PhotoLibraryService.fetchImage(for: asset, targetSize: retinaSize) { fetchedImage in
                self.image = fetchedImage
                if let img = fetchedImage {
                    imageDict[asset.localIdentifier] = img
                }
            }
        }
    }
} 
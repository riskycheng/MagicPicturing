import SwiftUI
import Photos

struct CanvasView: View {
    @StateObject private var viewModel: CanvasViewModel
    
    // Define a fixed canvas size for simplicity, or it could come from a higher-level view.
    private let canvasSize = CGSize(width: UIScreen.main.bounds.width - 32, height: (UIScreen.main.bounds.width - 32) * 1.2)

    init(initialAssets: [PHAsset]) {
        _viewModel = StateObject(wrappedValue: CanvasViewModel(initialAssets: initialAssets))
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectedImageID = nil
                }
            
            ForEach(viewModel.canvasImages) { imgState in
                CanvasImageView(
                    state: imgState,
                    isSelected: viewModel.selectedImageID == imgState.id,
                    onUpdate: { updated in
                        viewModel.updateImage(updated)
                    },
                    onSelect: { id in
                        viewModel.selectedImageID = id
                    },
                    onRemove: { id in
                        viewModel.removeImageFromCanvas(id)
                    },
                    allImages: viewModel.canvasImages
                )
                .zIndex(viewModel.selectedImageID == imgState.id ? 1 : 0)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .background(Color(white: 0.95))
        .cornerRadius(16)
    }
} 
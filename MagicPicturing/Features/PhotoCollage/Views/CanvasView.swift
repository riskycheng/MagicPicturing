import SwiftUI
import Photos

struct CanvasView: View {
    @ObservedObject var viewModel: CanvasViewModel
    let canvasSize: CGSize

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
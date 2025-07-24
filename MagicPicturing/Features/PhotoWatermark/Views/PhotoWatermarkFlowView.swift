import SwiftUI
import Photos

struct PhotoWatermarkFlowView: View {
    @Environment(\.dismiss) private var dismiss
    
    // State for the entire flow
    @State private var selectedImage: UIImage?
    @State private var selectedAsset: PHAsset?
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Show the entry view only after an image has been selected.
                if let image = selectedImage, let asset = selectedAsset {
                    PhotoWatermarkEntryView(image: image, asset: asset)
                } else {
                    // While the picker is active, show a loading or placeholder view.
                    Color.clear
                        .onAppear {
                            print("PhotoWatermarkFlowView: Appeared, triggering image picker.")
                            // Trigger the image picker as soon as the flow starts.
                            showImagePicker = true
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePickerView(
                onCancel: {
                    print("PhotoWatermarkFlowView: Image picker cancelled.")
                    showImagePicker = false
                    // If the user cancels the initial image selection, dismiss the whole flow.
                    if selectedImage == nil {
                        dismiss()
                    }
                },
                onNext: { assets, images in
                    print("PhotoWatermarkFlowView: Image selected, transitioning to entry view.")
                    if let firstAsset = assets.first, let firstImage = images.first {
                        self.selectedAsset = firstAsset
                        self.selectedImage = firstImage
                    }
                    showImagePicker = false
                },
                selectionLimit: 1,
                minSelection: 1
            )
        }
    }
}

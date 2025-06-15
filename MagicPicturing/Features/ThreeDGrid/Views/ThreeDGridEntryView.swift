import SwiftUI
import Photos

struct ThreeDGridEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // State to manage the navigation to the main grid workspace
    @State private var isNavigatingToWorkspace = false
    
    // State to hold the selected photos from the picker
    @State private var selectedAssets: [PHAsset] = []
    @State private var selectedImages: [UIImage] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Hidden NavigationLink to programmatically trigger navigation
                NavigationLink(
                    destination: ThreeDGridView(selectedImages: selectedImages),
                    isActive: $isNavigatingToWorkspace
                ) {
                    EmptyView()
                }
                
                // Our unified, reusable image picker
                ImagePickerView(
                    onCancel: {
                        // Dismiss the modal presentation
                        presentationMode.wrappedValue.dismiss()
                    },
                    onNext: { assets, images in
                        // When the user taps "Next", store the selections and trigger the navigation
                        self.selectedAssets = assets
                        self.selectedImages = images
                        self.isNavigatingToWorkspace = true
                    },
                    selectionLimit: 10, // Max 1 for main subject + 9 for grid
                    minSelection: 2      // Min 1 for main subject + 1 for grid
                )
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }
} 
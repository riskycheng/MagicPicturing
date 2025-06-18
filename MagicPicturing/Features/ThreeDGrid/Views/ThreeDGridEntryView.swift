import SwiftUI
import Photos

// A simple ViewModel to manage the state and navigation logic
class ThreeDGridEntryViewModel: ObservableObject {
    @Published var selectedAssets: [PHAsset] = []
    @Published var selectedImages: [UIImage] = []
    @Published var isNavigatingToWorkspace = false
    
    func processSelectedPhotos(assets: [PHAsset], images: [UIImage]) {
        self.selectedAssets = assets
        self.selectedImages = images
        
        // Use a slight delay to allow the dismiss animation of the picker to complete
        // before triggering the navigation. This is a common SwiftUI pattern to avoid
        // navigation state conflicts.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isNavigatingToWorkspace = true
        }
    }
}

struct ThreeDGridEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ThreeDGridEntryViewModel()
    
    // State to control the picker presentation
    @State private var showPicker = true
    
    var body: some View {
        // The NavigationView is crucial for the NavigationLink to work.
        NavigationView {
            ZStack {
                // A hidden NavigationLink to the workspace, controlled by the ViewModel.
                NavigationLink(
                    destination: ThreeDGridView(selectedImages: viewModel.selectedImages),
                    isActive: $viewModel.isNavigatingToWorkspace
                ) {
                    EmptyView()
                }
                
                // A placeholder background.
                Color.black.edgesIgnoringSafeArea(.all)
            }
            .navigationBarHidden(true)
            .onAppear {
                // When this view appears, if we have already navigated to the workspace,
                // it means the user has tapped the back button from ThreeDGridView.
                // In that case, we should dismiss this intermediate entry view.
                if viewModel.isNavigatingToWorkspace {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationViewStyle(.stack) // Use stack style to avoid sidebar on iPad
        .fullScreenCover(isPresented: $showPicker) {
            ImagePickerView(
                onCancel: {
                    // The picker dismisses itself, then calls this.
                    // We must dismiss this EntryView.
                    self.presentationMode.wrappedValue.dismiss()
                },
                onNext: { assets, images in
                    // The picker dismisses itself, then calls this.
                    // We let the view model handle the logic.
                    // The showPicker state will be set to false automatically by SwiftUI.
                    viewModel.processSelectedPhotos(assets: assets, images: images)
                },
                selectionLimit: 10,
                minSelection: 2
            )
        }
    }
} 
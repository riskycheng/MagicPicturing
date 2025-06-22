import SwiftUI
import Photos

/// The main entry point for the photo collage feature.
/// This view wraps the entire flow in a NavigationView and handles dismissal.

// A simple ViewModel to manage the state and navigation logic, mirroring the ThreeDGrid pattern.
class CollageEntryViewModel: ObservableObject {
    @Published var selectedAssets: [PHAsset] = []
    @Published var isNavigatingToWorkspace = false
    
    func processSelectedPhotos(assets: [PHAsset]) {
        self.selectedAssets = assets
        
        // Use a slight delay to allow the dismiss animation of the picker to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isNavigatingToWorkspace = true
        }
    }
}

struct CollageEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = CollageEntryViewModel()
    
    // State to control the picker presentation
    @State private var showPicker = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // A hidden NavigationLink to the workspace, controlled by the ViewModel.
                NavigationLink(
                    destination: CollageModeSelectionView(assets: viewModel.selectedAssets),
                    isActive: $viewModel.isNavigatingToWorkspace
                ) {
                    EmptyView()
                }
                
                // A placeholder background.
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            }
            .navigationBarHidden(true)
            .onAppear {
                // When this view appears again after navigating away, dismiss it.
                if viewModel.isNavigatingToWorkspace {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(isPresented: $showPicker) {
            ImagePickerView(
                onCancel: {
                    self.presentationMode.wrappedValue.dismiss()
                },
                onNext: { assets, _ in
                    viewModel.processSelectedPhotos(assets: assets)
                },
                selectionLimit: 9,
                minSelection: 2
            )
        }
    }
} 
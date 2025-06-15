import SwiftUI
import Photos

fileprivate struct SelectionState {
    let isSelected: Bool
    let selectionIndex: Int?
}

struct ImagePickerView: View {
    
    var onCancel: () -> Void
    var onNext: ([PHAsset], [UIImage]) -> Void // Use a closure for the next step

    @State private var allPhotos: [PHAsset] = []
    @State private var selectedPhotoIDs: [String] = []
    @State private var selectionState: [String: SelectionState] = [:]
    @State private var imageDict: [String: UIImage] = [:]

    private let imageSize = UIScreen.main.bounds.width / 3
    // Allow selecting a single image for ThreeDGrid, or multiple for others
    var selectionLimit: Int = 9
    var minSelection: Int = 2

    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(imageSize), spacing: 2), count: 3), spacing: 2) {
                    ForEach(allPhotos, id: \.localIdentifier) { asset in
                        PhotoCell(
                            asset: asset,
                            selectionState: selectionState[asset.localIdentifier],
                            imageDict: $imageDict
                        )
                        .onTapGesture {
                            toggleSelection(for: asset)
                        }
                    }
                }
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .onAppear(perform: loadPhotos)
    }
    
    private func loadPhotos() {
        PhotoLibraryService.requestAuthorization {
            PhotoLibraryService.fetchAllPhotos { assets in
                self.allPhotos = assets.sorted {
                    $0.creationDate ?? .distantPast > $1.creationDate ?? .distantPast
                }
            }
        }
    }
    
    private func toggleSelection(for asset: PHAsset) {
        let id = asset.localIdentifier
        if let index = selectedPhotoIDs.firstIndex(of: id) {
            selectedPhotoIDs.remove(at: index)
        } else if selectedPhotoIDs.count < selectionLimit {
            selectedPhotoIDs.append(id)
        }
        // Rebuild the selection state dictionary after every change
        var newSelectionState: [String: SelectionState] = [:]
        for (index, id) in selectedPhotoIDs.enumerated() {
            newSelectionState[id] = SelectionState(isSelected: true, selectionIndex: index + 1)
        }
        self.selectionState = newSelectionState
    }
    
    private var headerView: some View {
        HStack {
            Button("取消", action: onCancel)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("选择照片")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            nextButton
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    private var nextButton: some View {
        let isValidSelection = selectedPhotoIDs.count >= minSelection
        
        return Button(action: {
            // Fetch selected assets and images and pass them to the closure
            let selectedAssets = allPhotos.filter { selectedPhotoIDs.contains($0.localIdentifier) }
            let selectedImages = selectedAssets.compactMap { imageDict[$0.localIdentifier] }
            onNext(selectedAssets, selectedImages)
        }) {
            Text("下一步 (\(selectedPhotoIDs.count))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isValidSelection ? .blue : .gray)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isValidSelection ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
        .disabled(!isValidSelection)
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
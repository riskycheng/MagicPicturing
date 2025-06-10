import SwiftUI
import Photos

struct CollageImageSelectionView: View {
    
    var onCancel: () -> Void
    
    @State private var allPhotos: [PHAsset] = []
    @State private var selectedPhotos: [PHAsset] = []
    
    private let imageSize = UIScreen.main.bounds.width / 3
    private let selectionLimit = 9

    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(imageSize), spacing: 2), count: 3), spacing: 2) {
                    ForEach(allPhotos, id: \.self) { asset in
                        PhotoCell(asset: asset, isSelected: selectedPhotos.contains(asset), selectionIndex: selectedPhotos.firstIndex(of: asset))
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
                self.allPhotos = assets
            }
        }
    }
    
    private func toggleSelection(for asset: PHAsset) {
        if let index = selectedPhotos.firstIndex(of: asset) {
            selectedPhotos.remove(at: index)
        } else {
            if selectedPhotos.count < selectionLimit {
                selectedPhotos.append(asset)
            }
        }
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
        let isValidSelection = selectedPhotos.count >= 2
        
        let destination = CollageWorkspaceView(assets: selectedPhotos)
        
        return NavigationLink(destination: destination) {
            Text("下一步 (\(selectedPhotos.count))")
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
    let isSelected: Bool
    let selectionIndex: Int?
    
    @State private var image: UIImage? = nil
    private let imageSize = UIScreen.main.bounds.width / 3

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
            }
            
            if isSelected {
                ZStack(alignment: .topTrailing) {
                    Color.black.opacity(0.4)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(selectionIndex.map { $0 + 1 } ?? 0)")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        )
                        .padding(4)
                }
                Rectangle().stroke(Color.blue, lineWidth: 4)
            }
        }
        .frame(width: imageSize, height: imageSize)
        .clipped()
        .onAppear {
            let retinaSize = CGSize(width: imageSize * UIScreen.main.scale, height: imageSize * UIScreen.main.scale)
            PhotoLibraryService.fetchImage(for: asset, targetSize: retinaSize) { fetchedImage in
                self.image = fetchedImage
            }
        }
    }
} 
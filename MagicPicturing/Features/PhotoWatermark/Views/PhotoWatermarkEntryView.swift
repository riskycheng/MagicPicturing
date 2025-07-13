import SwiftUI
import Photos

struct PhotoWatermarkEntryView: View {
    @StateObject private var viewModel = PhotoWatermarkViewModel()
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Main Image Display Area
                GeometryReader { geo in
                    ZStack {
                        if let image = viewModel.sourceImage {
                            let containerSize = calculateContainerSize(for: geo.size, aspectRatio: viewModel.sourceImageAspectRatio)
                            
                            // This is the composite view of the image and the watermark
                            ZStack(alignment: .bottom) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: containerSize.width, height: containerSize.height)
                                    .clipped()
                                
                                if let info = viewModel.watermarkInfo {
                                    viewModel.selectedTemplate
                                        .makeView(watermarkInfo: info, width: containerSize.width)
                                        .id(viewModel.selectedTemplate)
                                }
                            }
                            .frame(width: containerSize.width, height: containerSize.height)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                            
                        } else {
                            // Placeholder view for when no image is selected
                            placeholderView
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height) // Center content in the GeometryReader
                }

                Spacer()

                // MARK: - Template Gallery
                if viewModel.sourceImage != nil {
                    templateGallery
                }
            }
            .background(Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all))
            .animation(.spring(), value: viewModel.sourceImage)
            .navigationTitle("Add Watermark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: navigationToolbar)
            .sheet(isPresented: $showImagePicker, content: imagePickerSheet)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func calculateContainerSize(for availableSize: CGSize, aspectRatio: CGFloat) -> CGSize {
        // Define the maximum bounding box for our preview area
        let maxBoundingWidth = availableSize.width - 32 // 16pt padding on each side
        let maxBoundingHeight = availableSize.height * 0.8 // Use up to 80% of the available height
        
        // Calculate the size if we were to fit the image to the max width
        let sizeFittingWidth = CGSize(width: maxBoundingWidth, height: maxBoundingWidth / aspectRatio)
        
        // Calculate the size if we were to fit the image to the max height
        let sizeFittingHeight = CGSize(width: maxBoundingHeight * aspectRatio, height: maxBoundingHeight)
        
        // If fitting to the width makes the image too tall, we must constrain by height.
        // Otherwise, constraining by width is correct.
        if sizeFittingWidth.height > maxBoundingHeight {
            return sizeFittingHeight
        } else {
            return sizeFittingWidth
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var placeholderView: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .cornerRadius(12)
            Button(action: { showImagePicker = true }) {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                    Text("Select a photo")
                        .font(.headline)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var templateGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(viewModel.templates) { template in
                    TemplatePreviewCard(
                        previewImage: viewModel.templatePreviews[template],
                        isSelected: viewModel.selectedTemplate == template,
                        aspectRatio: viewModel.sourceImageAspectRatio
                    ) {
                        viewModel.selectedTemplate = template
                    }
                }
            }
            .padding()
        }
        .frame(height: 160)
        .background(Color(UIColor.systemBackground))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    @ToolbarContentBuilder
    private func navigationToolbar() -> some ToolbarContent {
        if viewModel.sourceImage != nil {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showImagePicker = true }) {
                    Image(systemName: "photo.on.rectangle.angled")
                }
            }
        }
    }
    
    private func imagePickerSheet() -> some View {
        ImagePickerView(
            onCancel: { showImagePicker = false },
            onNext: { assets, _ in
                guard let asset = assets.first else { return showImagePicker = false }
                
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                options.version = .original
                
                PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                    DispatchQueue.main.async {
                        if let error = info?[PHImageErrorKey] as? Error {
                            print("Error fetching image data: \(error.localizedDescription)")
                            return showImagePicker = false
                        }
                        
                        guard let imageData = data, let fullImage = UIImage(data: imageData) else {
                            print("Failed to get image data from asset.")
                            return showImagePicker = false
                        }
                        
                        viewModel.sourceImageData = imageData
                        viewModel.sourceImage = fullImage
                        showImagePicker = false
                    }
                }
            },
            selectionLimit: 1,
            minSelection: 1
        )
    }
}

// MARK: - Template Preview Card
private struct TemplatePreviewCard: View {
    let previewImage: UIImage?
    let isSelected: Bool
    let aspectRatio: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Group {
                if let image = previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    ZStack {
                        Color.secondary.opacity(0.1)
                            .aspectRatio(CGSize(width: 1, height: aspectRatio), contentMode: .fit)
                        ProgressView()
                    }
                }
            }
            .frame(height: 100)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: isSelected ? 3 : 0)
            )
            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.1), radius: isSelected ? 6 : 3, y: isSelected ? 3 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(), value: isSelected)
    }
}

struct PhotoWatermarkEntryView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoWatermarkEntryView()
    }
} 
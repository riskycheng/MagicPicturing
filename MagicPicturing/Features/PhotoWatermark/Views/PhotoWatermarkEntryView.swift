import SwiftUI
import Photos

struct PhotoWatermarkEntryView: View {
    @State private var showSaveSuccessAlert = false
    @State private var alertMessage = ""
    @StateObject private var viewModel: PhotoWatermarkViewModel
    @State private var showImageEditor = false
    
    // The new initializer requires both the image and the PHAsset.
    init(image: UIImage, asset: PHAsset) {
        _viewModel = StateObject(wrappedValue: PhotoWatermarkViewModel(initialImage: image, asset: asset))
        print("PhotoWatermarkEntryView: Initialized with selected image.")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Main Image Display Area
            GeometryReader { geo in
                ZStack {
                    if viewModel.sourceImage != nil {
                        let containerSize = calculateContainerSize(for: geo.size, aspectRatio: viewModel.sourceImageAspectRatio)
                        
                        // The composed view of the image and watermark.
                        WatermarkedImageView(
                            viewModel: viewModel,
                            containerSize: containerSize
                        )
                        .onTapGesture {
                            print("PhotoWatermarkEntryView: Image tapped, showing editor.")
                            showImageEditor = true
                        }
                    } else {
                        // Placeholder view for when no image is selected
                        placeholderView
                    }
                }
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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // The close button is implicitly handled by NavigationView
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    saveWatermarkedImage()
                }
                .disabled(viewModel.sourceImage == nil)
            }
        }
        .alert("Success", isPresented: $showSaveSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showImageEditor) {
            ImageEditorSheet(image: $viewModel.sourceImage)
        }
    }

    @MainActor
    private func saveWatermarkedImage() {
        guard let imageToSave = renderFinalImage() else {
            alertMessage = "Failed to render the final image."
            showSaveSuccessAlert = true // Or a different alert for failure
            return
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: imageToSave)
        }) { success, error in
            if success {
                DispatchQueue.main.async {
                    alertMessage = "Image saved successfully to your photo library."
                    showSaveSuccessAlert = true
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "Error saving image: \(error.localizedDescription)"
                    showSaveSuccessAlert = true // Or a different alert for failure
                }
            }
        }
    }

    @MainActor
    private func renderFinalImage() -> UIImage? {
        guard let sourceImage = viewModel.sourceImage else { return nil }

        // Use the original image dimensions for the highest quality snapshot.
        let finalSize = sourceImage.size
        let viewToRender = WatermarkedImageView(viewModel: viewModel, containerSize: finalSize, isForExport: true)

        return viewToRender.snapshot()
    }
    
    private func calculateContainerSize(for availableSize: CGSize, aspectRatio: CGFloat) -> CGSize {
        let width = availableSize.width
        let height = width / aspectRatio
        return CGSize(width: width, height: height)
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var placeholderView: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var templateGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(viewModel.templates) { template in
                    TemplateIndicatorCard(
                        template: template,
                        isSelected: viewModel.selectedTemplate == template
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
}

// MARK: - Watermarked Image View
private struct WatermarkedImageView: View {
    @ObservedObject var viewModel: PhotoWatermarkViewModel
    let containerSize: CGSize
    var isForExport: Bool = false

    var body: some View {
        if let image = viewModel.sourceImage {
            let composedView = VStack(spacing: 0) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: containerSize.width)
                    .clipped()

                if let info = viewModel.watermarkInfo {
                    viewModel.selectedTemplate
                        .makeView(watermarkInfo: info, width: containerSize.width)
                        .id(viewModel.selectedTemplate.id)
                }
            }

            if isForExport {
                composedView
            } else {
                composedView
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Template Indicator Card
private struct TemplateIndicatorCard: View {
    let template: WatermarkTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.systemGray4))
                        .frame(width: 80, height: 60)

                    VStack(spacing: 0) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(UIColor.systemGray6))
                            .frame(height: 20)
                            .overlay(
                                HStack(spacing: 5) {
                                    ForEach(Array(template.indicatorLayout.enumerated()), id: \.offset) { _, component in
                                        switch component {
                                        case .logo:
                                            Circle().fill(Color.green).frame(width: 10, height: 10)
                                        case .text:
                                            Rectangle().fill(Color.black).frame(width: 20, height: 6)
                                        }
                                    }
                                }
                            )
                    }
                    .frame(width: 80, height: 60)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: isSelected ? 3 : 0)
                )

                Text(template.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(), value: isSelected)
    }
}

struct PhotoWatermarkEntryView_Previews: PreviewProvider {
    static var previews: some View {
        // Helper to fetch a real asset for a more realistic preview
        let (image, asset) = getPreviewAsset()
        
        if let image = image, let asset = asset {
            NavigationView {
                PhotoWatermarkEntryView(image: image, asset: asset)
            }
        } else {
            Text("No photo available for preview. Please add a photo to your library.")
        }
    }
    
    // Fetches the first available photo from the user's library to use in the preview.
    static func getPreviewAsset() -> (UIImage?, PHAsset?) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard let asset = fetchResult.firstObject else {
            return (nil, nil)
        }
        
        var fetchedImage: UIImage? = nil
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true // Make the request synchronous for the preview
        requestOptions.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 800, height: 600), contentMode: .aspectFill, options: requestOptions) { image, _ in
            fetchedImage = image
        }
        
        return (fetchedImage, asset)
    }
} 
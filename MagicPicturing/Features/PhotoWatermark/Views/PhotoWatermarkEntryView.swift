import SwiftUI

struct PhotoWatermarkEntryView: View {
    @StateObject private var viewModel = PhotoWatermarkViewModel()
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Main Image Display
                if let image = viewModel.sourceImage {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                        if let info = viewModel.watermarkInfo {
                            GeometryReader { geo in
                                viewModel.selectedTemplate.makeView(image: image, watermarkInfo: info, isPreview: true, width: geo.size.width)
                                    .id(viewModel.selectedTemplate)
                            }
                        }
                    }
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                } else {
                    // Placeholder view
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
                
                Spacer() // Pushes the template selector to the bottom
                
                // MARK: - Template Gallery
                if viewModel.sourceImage != nil {
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
            }
            .padding(.top)
            .background(Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all))
            .animation(.spring(), value: viewModel.sourceImage)
            .navigationTitle("Add Watermark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.sourceImage != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showImagePicker = true }) {
                            Image(systemName: "photo.on.rectangle.angled")
                        }
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(
                    onCancel: { showImagePicker = false },
                    onNext: { assets, images in
                        viewModel.sourceImage = images.first
                        showImagePicker = false
                    },
                    selectionLimit: 1,
                    minSelection: 1
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
                        .scaledToFit() // Ensure the entire watermarked image is visible
                } else {
                    // Placeholder while rendering
                    ZStack {
                        Color.secondary.opacity(0.1)
                            .aspectRatio(CGSize(width: 1, height: aspectRatio), contentMode: .fit)
                        ProgressView()
                    }
                }
            }
            .frame(height: 100) // Enforce a consistent height for all cards
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
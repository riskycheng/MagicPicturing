import SwiftUI

struct PhotoWatermarkEntryView: View {
    @StateObject private var viewModel = PhotoWatermarkViewModel()
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Main Image Display
                if let image = viewModel.processedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding([.horizontal, .top])
                        .shadow(radius: 5)
                } else {
                    ZStack {
                        Color(UIColor.secondarySystemBackground)
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
                
                Spacer()
                
                // MARK: - Template Selector
                if viewModel.sourceImage != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("选择模板")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.templates) { template in
                                    TemplatePreviewButton(
                                        template: template,
                                        isSelected: viewModel.selectedTemplate == template,
                                        previewImage: UIImage(named: "beach") ?? UIImage()
                                    ) {
                                        viewModel.selectedTemplate = template
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                        }
                    }
                    .frame(height: 95)
                    .background(Color(UIColor.secondarySystemBackground))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(), value: viewModel.sourceImage)
            .navigationTitle("Add Watermark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Button to re-select an image, only visible when an image is loaded
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

// MARK: - Template Preview Button
private struct TemplatePreviewButton: View {
    let template: WatermarkTemplate
    let isSelected: Bool
    let previewImage: UIImage
    let action: () -> Void
    
    private static let placeholderInfo = WatermarkInfo.placeholder
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                template.makeView(image: previewImage, watermarkInfo: Self.placeholderInfo)
                    .frame(width: 80, height: 60)
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .overlay(
                        ZStack {
                            if isSelected {
                                Color.black.opacity(0.4)
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                            }
                        }
                        .cornerRadius(6)
                    )
                
                Text(template.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
        }
    }
}

struct PhotoWatermarkEntryView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoWatermarkEntryView()
    }
} 
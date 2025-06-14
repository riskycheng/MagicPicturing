import SwiftUI
import Combine
import Photos

struct CollageWorkspaceView: View {

    @StateObject private var viewModel: CollageViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showSaveSuccessAlert = false

    init(assets: [PHAsset]) {
        _viewModel = StateObject(wrappedValue: CollageViewModel(assets: assets))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header - Stays fixed at the top
            headerView

            // Spacer to push the preview into the middle, allowing it to resize freely
            Spacer()

            if !viewModel.images.isEmpty, let layout = viewModel.selectedLayout {
                CollagePreviewView(viewModel: viewModel)
                    // The aspect ratio is now driven by the layout itself
                    .aspectRatio(layout.aspectRatio, contentMode: .fit)
                    .padding(.horizontal)
            } else {
                ProgressView()
            }
            
            // Spacer to push the layout selector to the bottom
            Spacer()

            // Bottom controls - Stays fixed at the bottom
            Group {
                if viewModel.selectedImageIndex == nil {
                    LayoutSelectorView(
                        layouts: viewModel.availableLayouts,
                        selectedLayout: $viewModel.selectedLayout
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    PhotoEditControlsView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            // .animation(.easeInOut, value: viewModel.selectedImageIndex) // DEBUG: Temporarily disable to fix animation conflict
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .foregroundColor(.white)
        .alert("已保存至相册", isPresented: $showSaveSuccessAlert) {
            Button("好", role: .cancel) { }
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .padding()
            }
            .contentShape(Rectangle())

            Spacer()

            Text("编辑拼图")
                .font(.headline)
                .fontWeight(.bold)

            Spacer()

            Button("保存") {
                saveCollage()
            }
            .font(.headline)
            .padding()
        }
        .padding(.horizontal, 4)
        .frame(height: 44)
    }
    
    private func saveCollage() {
        guard !viewModel.images.isEmpty, let layout = viewModel.selectedLayout else {
            return
        }

        let renderWidth: CGFloat = 1080
        let renderHeight = renderWidth / layout.aspectRatio
        
        let collageToRender = CollagePreviewView(viewModel: viewModel)
            .frame(width: renderWidth, height: renderHeight)

        guard let renderedImage = collageToRender.snapshot() else {
            print("Error: Could not render the collage view to an image.")
            return
        }

        viewModel.saveImage(renderedImage) { success in
            if success {
                self.showSaveSuccessAlert = true
            }
        }
    }
}

// MARK: - Layout Selector
private struct LayoutSelectorView: View {
    let layouts: [CollageLayout]
    @Binding var selectedLayout: CollageLayout?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("布局")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(layouts, id: \.id) { layout in
                        layout.preview
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedLayout?.id == layout.id ? Color.blue : Color.clear, lineWidth: 3)
                            )
                            .onTapGesture {
                                selectedLayout = layout
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color.black.opacity(0.5))
    }
} 
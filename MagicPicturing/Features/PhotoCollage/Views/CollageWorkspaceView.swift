import SwiftUI
import Combine
import Photos

struct CollageWorkspaceView: View {

    @StateObject private var viewModel: CollageViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showSaveSuccessAlert = false
    @State private var showImagePicker = false
    @State private var showMoreTemplates = false

    @State private var activeSheet: (tab: ControlTab, id: UUID)? = nil

    init(assets: [PHAsset]) {
        _viewModel = StateObject(wrappedValue: CollageViewModel(initialAssets: assets))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            collagePreviewArea
            bottomControls
        }
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .environment(\.colorScheme, .light)
        .foregroundColor(Color(UIColor.label))
        .alert("已保存至相册", isPresented: $showSaveSuccessAlert) {
            Button("好", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(
                onCancel: { showImagePicker = false },
                onNext: { selectedAssets, _ in
                    viewModel.add(assets: selectedAssets)
                    showImagePicker = false
                },
                selectionLimit: 9 - viewModel.assets.count
            )
        }
        .sheet(isPresented: $showMoreTemplates) {
            MoreTemplatesView(
                isPresented: $showMoreTemplates,
                imageCount: viewModel.assets.count,
                onLayoutSelected: { newLayout in
                    viewModel.selectedLayout = newLayout
                }
            )
        }
    }

    private var collagePreviewArea: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectedImageIndex = nil
                }
            
            VStack {
                if !viewModel.imageStates.isEmpty, let layout = viewModel.selectedLayout {
                    CollagePreviewView(viewModel: viewModel)
                        .aspectRatio(layout.aspectRatio, contentMode: .fit)
                        .padding(.horizontal)
                } else {
                    ProgressView()
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var bottomControls: some View {
        Group {
            if viewModel.selectedImageIndex == nil {
                BottomControlSystem(viewModel: viewModel, activeSheet: $activeSheet, showImagePicker: $showImagePicker, showMoreTemplates: $showMoreTemplates)
            } else {
                PhotoEditControlsView(viewModel: viewModel)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedImageIndex)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: activeSheet?.id)
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }

            Spacer()

            Text("编辑拼图")
                .font(.headline)
                .fontWeight(.bold)

            Spacer()

            Button("保存") {
                saveCollage()
            }
            .font(.headline)
        }
        .padding()
        .background(.regularMaterial)
    }
    
    private func saveCollage() {
        guard !viewModel.imageStates.isEmpty, let layout = viewModel.selectedLayout else {
            return
        }

        let renderWidth: CGFloat = 1080
        let renderHeight = renderWidth / layout.aspectRatio
        
        let originalSelection = viewModel.selectedImageIndex
        viewModel.selectedImageIndex = nil
        
        let collageToRender = CollagePreviewView(viewModel: viewModel)
            .frame(width: renderWidth, height: renderHeight)
            .background(Color(UIColor.systemBackground))

        guard let renderedImage = collageToRender.snapshot() else {
            print("Error: Could not render the collage view to an image.")
            viewModel.selectedImageIndex = originalSelection
            return
        }
        
        viewModel.selectedImageIndex = originalSelection

        viewModel.saveImage(renderedImage) { success in
            if success {
                self.showSaveSuccessAlert = true
            }
        }
    }
} 
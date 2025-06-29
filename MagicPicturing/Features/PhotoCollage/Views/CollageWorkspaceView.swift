import SwiftUI
import Combine
import Photos

struct CollageWorkspaceView: View {

    @StateObject private var viewModel: CollageViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var activeSheet: (tab: ControlTab, id: UUID)? = nil
    @State private var showImagePicker = false
    @State private var showSaveConfirmation = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

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
        .alert("已保存至相册", isPresented: $showSaveConfirmation) {
            Button("好", role: .cancel) { }
        }
        .alert("错误", isPresented: $showErrorAlert) {
            Button("好", role: .cancel) { }
        } message: {
            Text(errorMessage)
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
                        .padding(4)
                        .background(ViewFinder.view(withId: "collage_preview"))
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
                BottomControlSystem(viewModel: viewModel, activeSheet: $activeSheet, showImagePicker: $showImagePicker)
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
                dismiss()
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
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                viewModel.exportCollage(in: windowScene) { error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        self.showErrorAlert = true
                    } else {
                        self.showSaveConfirmation = true
                    }
                }
            }
            .font(.headline)
        }
        .padding()
        .background(.regularMaterial)
    }
} 
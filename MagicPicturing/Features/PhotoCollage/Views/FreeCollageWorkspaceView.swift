import SwiftUI
import Photos

struct FreeCollageWorkspaceView: View {
    @StateObject private var viewModel: CanvasViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // State for drag and drop
    @State private var draggingImage: (id: String, image: UIImage)?
    @State private var dragPosition: CGPoint?
    
    private let canvasSize = CGSize(width: UIScreen.main.bounds.width - 32, height: (UIScreen.main.bounds.width - 32) * 1.2)
    
    init(initialAssets: [PHAsset]) {
        _viewModel = StateObject(wrappedValue: CanvasViewModel(initialAssets: initialAssets))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Spacer()
            
            CanvasView(viewModel: viewModel, canvasSize: canvasSize)
                .coordinateSpace(name: "workspace")
            
            Spacer()
            
            if !viewModel.bottomImages.isEmpty {
                bottomBar
            }
        }
        .overlay(
            draggedImageOverlay
        )
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .environment(\.colorScheme, .light)
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            Spacer()
            Text("自由拼图")
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            Button("保存") {
                // TODO: Implement save logic
            }
            .font(.headline)
        }
        .padding()
        .foregroundColor(Color.primary)
        .background(.regularMaterial)
    }
    
    private var bottomBar: some View {
        BottomImagePickerView(
            images: viewModel.bottomImages,
            onDragStart: { image, location, _ in
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                draggingImage = (id: image.id, image: image.image)
                dragPosition = location
            },
            onDragUpdate: { location in
                dragPosition = location
            },
            onDragEnd: { location in
                if let loc = location, let img = draggingImage {
                    // Check if dropped onto the canvas area
                    if loc.y < (UIScreen.main.bounds.height - 200) {
                        viewModel.addImage(at: loc, image: .init(id: img.id, image: img.image), canvasSize: canvasSize)
                    }
                }
                draggingImage = nil
                dragPosition = nil
            }
        )
        .frame(height: 100)
        .background(.regularMaterial)
    }
    
    @ViewBuilder
    private var draggedImageOverlay: some View {
        if let img = draggingImage, let pos = dragPosition {
            Image(uiImage: img.image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .cornerRadius(12)
                .shadow(radius: 10)
                .position(pos)
                .allowsHitTesting(false)
        }
    }
} 
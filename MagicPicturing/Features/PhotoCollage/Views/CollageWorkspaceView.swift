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
                    BottomControlsView(
                        layouts: viewModel.availableLayouts,
                        selectedLayout: $viewModel.selectedLayout
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    PhotoEditControlsView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: viewModel.selectedImageIndex)
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

// MARK: - Bottom Controls

private enum ControlTab: String, CaseIterable {
    case layout = "布局"
    case border = "边框"
    case blur = "模糊"
    case add = "添加"
    
    var icon: String {
        switch self {
        case .layout: return "square.grid.2x2"
        case .border: return "squareshape.controlhandles.on.squareshape.controlhandles"
        case .blur: return "drop.fill"
        case .add: return "plus"
        }
    }
}

private struct BottomControlsView: View {
    @State private var selectedTab: ControlTab = .layout
    
    let layouts: [CollageLayout]
    @Binding var selectedLayout: CollageLayout?

    var body: some View {
        VStack(spacing: 0) {
            // Content for the selected tab
            Group {
                switch selectedTab {
                case .layout:
                    LayoutSelectorScrollView(layouts: layouts, selectedLayout: $selectedLayout)
                case .border, .blur, .add:
                    // Placeholder for other controls
                    Text("\(selectedTab.rawValue) 功能待开发")
                        .foregroundColor(.gray)
                        .frame(height: 80, alignment: .center)
                }
            }
            .background(Color.black.opacity(0.8))


            // Tab bar
            HStack {
                ForEach(ControlTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(selectedTab == tab ? .blue : .gray)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 20)
            .background(Color(UIColor.systemGray6).opacity(0.2))
        }
    }
}

private struct LayoutSelectorScrollView: View {
    let layouts: [CollageLayout]
    @Binding var selectedLayout: CollageLayout?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(layouts) { layout in
                    LayoutPreviewCell(
                        layout: layout,
                        isSelected: selectedLayout?.id == layout.id
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedLayout = layout
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 80)
    }
}

private struct LayoutPreviewCell: View {
    let layout: CollageLayout
    let isSelected: Bool

    var body: some View {
        ZStack {
            ForEach(layout.frames, id: \.self) { frame in
                Rectangle()
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 1.5)
                    .frame(width: frame.width * 44, height: frame.height * 44)
                    .offset(x: frame.midX * 44 - 22, y: frame.midY * 44 - 22)
            }
        }
        .frame(width: 50, height: 50)
    }
} 
import SwiftUI
import Combine
import Photos

struct CollageWorkspaceView: View {

    @StateObject private var viewModel: CollageViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showSaveSuccessAlert = false
    @State private var showImagePicker = false

    // State for the new control panel design. Using a tuple with a UUID to ensure a new ID every time.
    @State private var activeSheet: (tab: ControlTab, id: UUID)? = nil

    init(assets: [PHAsset]) {
        _viewModel = StateObject(wrappedValue: CollageViewModel(initialAssets: assets))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ZStack {
                // Background tap area for deselection
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedImageIndex = nil
                    }
                
                // The actual collage content, centered
                VStack {
                    if !viewModel.imageStates.isEmpty, let layout = viewModel.selectedLayout {
                        CollagePreviewView(viewModel: viewModel)
                            .aspectRatio(layout.aspectRatio, contentMode: .fit)
                            .padding(.horizontal)
                    } else {
                        // Show a progress indicator while images are loading
                        ProgressView()
                    }
                }
            }
            .frame(maxHeight: .infinity)

            // Redesigned Bottom Controls
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
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .environment(\.colorScheme, .light)
        .foregroundColor(Color(UIColor.label))
        .alert("已保存至相册", isPresented: $showSaveSuccessAlert) {
            Button("好", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            // The image picker sheet
            ImagePickerView(
                onCancel: { showImagePicker = false },
                onNext: { selectedAssets, _ in
                    viewModel.add(assets: selectedAssets)
                    showImagePicker = false
                },
                selectionLimit: 9 - viewModel.assets.count // Allow adding up to 9 images total
            )
        }
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
        
        // Temporarily deselect to hide handles before rendering
        let originalSelection = viewModel.selectedImageIndex
        viewModel.selectedImageIndex = nil
        
        let collageToRender = CollagePreviewView(viewModel: viewModel)
            .frame(width: renderWidth, height: renderHeight)
            .background(Color(UIColor.systemBackground))

        guard let renderedImage = collageToRender.snapshot() else {
            print("Error: Could not render the collage view to an image.")
            viewModel.selectedImageIndex = originalSelection // Restore selection
            return
        }
        
        // Restore selection immediately after snapshot
        viewModel.selectedImageIndex = originalSelection

        viewModel.saveImage(renderedImage) { success in
            if success {
                self.showSaveSuccessAlert = true
            }
        }
    }
}

// MARK: - Redesigned Bottom Control System

private enum ControlTab: String, CaseIterable, Identifiable {
    case layout = "布局"
    case border = "边框"
    case blur = "模糊"
    case add = "添加"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .layout: return "square.grid.2x2"
        case .border: return "squareshape.controlhandles.on.squareshape.controlhandles"
        case .blur: return "drop.fill"
        case .add: return "plus"
        }
    }
}

private struct BottomControlSystem: View {
    @ObservedObject var viewModel: CollageViewModel
    @Binding var activeSheet: (tab: ControlTab, id: UUID)?
    @Binding var showImagePicker: Bool

    var body: some View {
        VStack(spacing: 0) {
            // The slide-up panel for controls
            if let sheetInfo = activeSheet {
                SubControlPanel(tab: sheetInfo.tab, viewModel: viewModel, activeSheet: $activeSheet)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id(sheetInfo.id) // Force recreation of the view and its state when the ID changes.
            }
            
            // Main Tab Bar
            HStack {
                ForEach(ControlTab.allCases) { tab in
                    Button(action: {
                        if tab == .add {
                            activeSheet = nil
                            showImagePicker = true
                        } else {
                            // The icon's only job is to SHOW the panel by giving it a new unique ID.
                            activeSheet = (tab, UUID())
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22))
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(activeSheet?.tab == tab ? .accentColor : Color(UIColor.secondaryLabel))
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 65)
            .background(.regularMaterial)
            .cornerRadius(20)
            .padding(.horizontal)
            .padding(.bottom, 5)
        }
    }
}

private struct SubControlPanel: View {
    let tab: ControlTab
    @ObservedObject var viewModel: CollageViewModel
    @Binding var activeSheet: (tab: ControlTab, id: UUID)?
    
    // State for the drag-to-dismiss gesture
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Grabber handle to indicate draggable area
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 50, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            // Panel Content
            switch tab {
            case .layout:
                LayoutSelectorScrollView(
                    layouts: viewModel.availableLayouts,
                    selectedLayout: $viewModel.selectedLayout
                )
            case .border:
                BorderControlsView(
                    borderWidth: $viewModel.borderWidth,
                    cornerRadius: $viewModel.cornerRadius,
                    shadowRadius: $viewModel.shadowRadius
                )
            case .blur:
                BlurControlView(backgroundBlur: $viewModel.backgroundBlur)
            case .add:
                EmptyView() // 'Add' is handled directly by the tab bar now
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
        )
        .padding(.horizontal)
        .padding(.bottom, 10)
        .offset(y: dragOffset) // Apply vertical offset from drag
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Allow dragging down, but not up past the original point.
                    self.dragOffset = max(0, gesture.translation.height)
                }
                .onEnded { gesture in
                    // If dragged more than a threshold, dismiss the panel
                    if gesture.translation.height > 60 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.activeSheet = nil
                        }
                    } else {
                        // Otherwise, snap back to its original position
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            // This is a failsafe, but the .id() modifier is the primary fix.
            self.dragOffset = 0
        }
    }
}

// MARK: - Specific Control Panels

private struct BorderControlsView: View {
    @Binding var borderWidth: CGFloat
    @Binding var cornerRadius: CGFloat
    @Binding var shadowRadius: CGFloat

    var body: some View {
        VStack(spacing: 16) {
            FancySlider(label: "间距", value: $borderWidth, range: 0...40, icon: "arrow.left.and.right")
            FancySlider(label: "圆角", value: $cornerRadius, range: 0...50, icon: "app.badge")
            FancySlider(label: "阴影", value: $shadowRadius, range: 0...15, icon: "shadow")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct FancySlider: View {
    let label: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 30)
                .foregroundColor(.accentColor)
            
            Text(label)
                .font(.system(size: 15))
                .frame(width: 40, alignment: .leading)

            // Custom Slider implementation
            GeometryReader { geometry in
                let valueRatio = (self.value - self.range.lowerBound) / (self.range.upperBound - self.range.lowerBound)
                let clampedRatio = max(0, min(1, CGFloat(valueRatio)))
                let thumbPositionX = geometry.size.width * clampedRatio

                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(height: 4)
                    
                    // Filled part of the track
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: thumbPositionX, height: 4)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                        .position(x: thumbPositionX, y: geometry.size.height / 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gestureValue in
                                    let newRatio = gestureValue.location.x / geometry.size.width
                                    let clampedNewRatio = max(0, min(1, newRatio))
                                    let newValue = (clampedNewRatio * (self.range.upperBound - self.range.lowerBound)) + self.range.lowerBound
                                    self.value = newValue
                                }
                        )
                }
                .frame(maxHeight: .infinity) // Center ZStack vertically
            }
            .frame(height: 22) // Give GeometryReader a defined height

            Text(String(format: "%.0f", value))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .frame(width: 35, alignment: .trailing)
                .foregroundColor(.secondary)
        }
    }
}

private struct BlurControlView: View {
    @Binding var backgroundBlur: CGFloat

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("模糊").frame(width: 50)
                Slider(value: $backgroundBlur, in: 0...30)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 15)
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
                        withAnimation(.spring()) {
                            selectedLayout = layout
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .frame(height: 60)
    }
}

private struct LayoutPreviewCell: View {
    let layout: CollageLayout
    let isSelected: Bool

    var body: some View {
        ZStack {
            ForEach(layout.frames, id: \.self) { frame in
                Rectangle()
                    .strokeBorder(isSelected ? Color.accentColor : Color.gray, lineWidth: 1.5)
                    .frame(width: frame.width * 44, height: frame.height * 44)
                    .offset(x: frame.midX * 44 - 22, y: frame.midY * 44 - 22)
            }
        }
        .frame(width: 50, height: 50)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
} 
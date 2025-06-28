import SwiftUI

enum ControlTab: String, CaseIterable, Identifiable {
    case layout = "布局"
    case border = "边框"
    case blur = "背景"
    case add = "添加"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .layout: return "square.grid.2x2"
        case .border: return "squareshape.controlhandles.on.squareshape.controlhandles"
        case .blur: return "paintpalette"
        case .add: return "plus"
        }
    }
}

struct BottomControlSystem: View {
    @ObservedObject var viewModel: CollageViewModel
    @Binding var activeSheet: (tab: ControlTab, id: UUID)?
    @Binding var showImagePicker: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let sheetInfo = activeSheet {
                SubControlPanel(tab: sheetInfo.tab, viewModel: viewModel, activeSheet: $activeSheet)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id(sheetInfo.id)
            }
            mainTabBar
        }
    }
    
    private var mainTabBar: some View {
        HStack {
            ForEach(ControlTab.allCases) { tab in
                Button(action: {
                    if tab == .add {
                        activeSheet = nil
                        showImagePicker = true
                    } else {
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

struct SubControlPanel: View {
    let tab: ControlTab
    @ObservedObject var viewModel: CollageViewModel
    @Binding var activeSheet: (tab: ControlTab, id: UUID)?
    
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 50, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            panelContent
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
        )
        .padding(.horizontal)
        .padding(.bottom, 10)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    self.dragOffset = max(0, gesture.translation.height)
                }
                .onEnded { gesture in
                    if gesture.translation.height > 60 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.activeSheet = nil
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            self.dragOffset = 0
        }
    }
    
    @ViewBuilder
    private var panelContent: some View {
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
            BackgroundColorPicker(viewModel: viewModel)
        case .add:
            EmptyView()
        }
    }
}

struct BorderControlsView: View {
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

struct FancySlider: View {
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
                .frame(width: 50, alignment: .leading)

            Slider(value: $value, in: range)
            
            let displayText = (label == "透明度") ?
                String(format: "%.0f%%", value * 100) :
                String(format: "%.0f", value)

            Text(displayText)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .frame(width: 45, alignment: .trailing)
                .foregroundColor(.secondary)
        }
    }
}

struct BackgroundColorPicker: View {
    @ObservedObject var viewModel: CollageViewModel

    let presetColors: [Color] = [
        .black, .white, .gray, .red, .blue, .green, .yellow, .purple, .orange
    ]

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 15) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        // Gradient Button
                        Button(action: {
                            viewModel.setRandomGradientBackground()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.blue, Color.pink]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Image(systemName: "wand.and.rays")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            }
                            .frame(width: 32, height: 32)
                        }
                        
                        // Preset Color Swatches
                        ForEach(presetColors, id: \.self) { color in
                            Button(action: {
                                self.viewModel.backgroundColor = color
                            }) {
                                ZStack {
                                    Circle().fill(color)
                                    Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    Circle()
                                        .stroke(
                                            viewModel.backgroundGradient == nil && viewModel.backgroundColor == color ? Color.accentColor : Color.clear,
                                            lineWidth: 2
                                        )
                                }
                                .frame(width: 32, height: 32)
                                .shadow(color: .black.opacity(0.1), radius: 1)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Custom Color Picker
                ZStack {
                    ColorPicker(selection: $viewModel.backgroundColor, supportsOpacity: true) { }
                        .labelsHidden()
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())

            }
            .padding(.horizontal)

            // Opacity Slider
            FancySlider(
                label: "透明度",
                value: $viewModel.backgroundMaterialOpacity,
                range: 0...1,
                icon: "sparkles"
            )
        }
        .padding(.vertical)
    }
}

struct LayoutSelectorScrollView: View {
    let layouts: [CollageLayout]
    @Binding var selectedLayout: CollageLayout?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(layouts) { layout in
                    Button(action: {
                        self.selectedLayout = layout
                    }) {
                        VStack {
                            layout.preview
                                .frame(width: 60, height: 60)
                                .padding(2)
                                .background(self.selectedLayout?.name == layout.name ? Color.accentColor.opacity(0.85) : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 80)
    }
}

struct LayoutPreviewCell: View {
    let layout: CollageLayout
    let isSelected: Bool

    var body: some View {
        ZStack {
            ForEach(layout.cellStates, id: \.self) { cell in
                Rectangle()
                    .strokeBorder(isSelected ? Color.accentColor : Color.gray, lineWidth: 1.5)
                    .frame(width: cell.frame.width * 44, height: cell.frame.height * 44)
                    .rotationEffect(cell.rotation)
                    .offset(x: cell.frame.midX * 44 - 22, y: cell.frame.midY * 44 - 22)
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

fileprivate struct ControlTabButton: View {
    let tab: ControlTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                Text(tab.rawValue)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .accentColor : Color(UIColor.secondaryLabel))
            .frame(maxWidth: .infinity)
        }
    }
}

struct ControlSlider: View {
    let label: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let iconName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .frame(width: 30)
                .foregroundColor(.accentColor)
            
            Text(label)
                .font(.system(size: 15))
                .frame(width: 40, alignment: .leading)

            Slider(value: $value, in: range)

            Text(String(format: "%.0f", value))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .frame(width: 35, alignment: .trailing)
                .foregroundColor(.secondary)
        }
    }
} 
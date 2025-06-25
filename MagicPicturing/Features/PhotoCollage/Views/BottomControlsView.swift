import SwiftUI

enum ControlTab: String, CaseIterable, Identifiable {
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

struct BottomControlSystem: View {
    @ObservedObject var viewModel: CollageViewModel
    @Binding var activeSheet: (tab: ControlTab, id: UUID)?
    @Binding var showImagePicker: Bool
    @Binding var showMoreTemplates: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let sheetInfo = activeSheet {
                SubControlPanel(tab: sheetInfo.tab, viewModel: viewModel, activeSheet: $activeSheet, showMoreTemplates: $showMoreTemplates)
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
    @Binding var showMoreTemplates: Bool
    
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
                selectedLayout: $viewModel.selectedLayout,
                showMoreTemplates: $showMoreTemplates
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
                .frame(width: 40, alignment: .leading)

            Slider(value: $value, in: range)

            Text(String(format: "%.0f", value))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .frame(width: 35, alignment: .trailing)
                .foregroundColor(.secondary)
        }
    }
}

struct BlurControlView: View {
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

struct LayoutSelectorScrollView: View {
    let layouts: [CollageLayout]
    @Binding var selectedLayout: CollageLayout?
    @Binding var showMoreTemplates: Bool

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
                
                Button(action: {
                    showMoreTemplates = true
                }) {
                    VStack {
                        Image(systemName: "ellipsis")
                            .font(.title)
                            .frame(width: 50, height: 50)
                        Text("更多")
                            .font(.caption)
                    }
                    .frame(width: 60)
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
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
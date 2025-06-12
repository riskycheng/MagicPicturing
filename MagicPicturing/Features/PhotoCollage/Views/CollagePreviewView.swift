import SwiftUI

struct CollagePreviewView: View {
    @ObservedObject var viewModel: CollageViewModel
    
    var body: some View {
        let _ = print("LOG: CollagePreviewView rendering...")
        GeometryReader { geometry in
            ZStack {
                // Background to dismiss selection
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedImageIndex = nil
                    }

                if let layout = viewModel.selectedLayout {
                    ForEach(0..<min(viewModel.images.count, layout.frames.count), id: \.self) { index in
                        let frame = layout.frames[index]
                        
                        // Use a container to position and size the cell
                        CollageCellView(
                            image: viewModel.images[index],
                            state: $viewModel.imageStates[index],
                            isSelected: viewModel.selectedImageIndex == index
                        )
                        .frame(width: geometry.size.width * frame.width, height: geometry.size.height * frame.height)
                        .position(x: geometry.size.width * frame.midX, y: geometry.size.height * frame.midY)
                        .onTapGesture {
                            viewModel.selectedImageIndex = index
                        }
                    }
                    
                    // Add Divider Handle for adjustable layouts
                    if let layout = viewModel.selectedLayout,
                       viewModel.selectedImageIndex != nil, // Only show when an image is selected
                       layout.name.contains("Adjustable") {
                        
                        // Logic for 2-image layouts
                        if layout.name == "2-H-Adjustable" {
                            let frame = layout.frames[0]
                            DividerView(layout: layout, parameterName: "h_split", axis: .vertical, viewSize: geometry.size)
                                .position(x: frame.maxX * geometry.size.width, y: geometry.size.height / 2)
                        } else if layout.name == "2-V-Adjustable" {
                            let frame = layout.frames[0]
                            DividerView(layout: layout, parameterName: "v_split", axis: .horizontal, viewSize: geometry.size)
                                .position(x: geometry.size.width / 2, y: frame.maxY * geometry.size.height)
                        }
                        
                        // Previous logic for 5-image layout can be adapted similarly...
                        else if let selectedIndex = viewModel.selectedImageIndex, layout.name == "5-L-Big-Grid-Adjustable" {
                            let frames = layout.frames
                            
                            // Vertical Divider Handle
                            let vDividerX = (frames[0].maxX - 0.5) * geometry.size.width
                            let vDivider = DividerView(layout: layout, parameterName: "h_split", axis: .vertical, viewSize: geometry.size)
                                .position(x: vDividerX, y: geometry.size.height / 2)

                            if selectedIndex == 0 || selectedIndex > 0 { // Show for left frame or any right frame
                               vDivider
                            }
                            
                            // Horizontal Divider Handles
                            if selectedIndex > 0 && selectedIndex < 5 {
                                // Divider above selected cell
                                if selectedIndex > 1 {
                                    let frame = frames[selectedIndex - 1]
                                    DividerView(layout: layout, parameterName: "v_split\(selectedIndex-1)", axis: .horizontal, viewSize: geometry.size)
                                        .position(x: (frame.midX) * geometry.size.width, y: frame.maxY * geometry.size.height)
                                }
                                // Divider below selected cell
                                if selectedIndex < 4 {
                                    let frame = frames[selectedIndex]
                                    DividerView(layout: layout, parameterName: "v_split\(selectedIndex)", axis: .horizontal, viewSize: geometry.size)
                                        .position(x: (frame.midX) * geometry.size.width, y: frame.maxY * geometry.size.height)
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                // Ensure there's a selected layout to observe
                if viewModel.selectedLayout == nil {
                    viewModel.selectedLayout = viewModel.availableLayouts.first
                }
            }
            .onChange(of: viewModel.selectedImageIndex) { _, newValue in
                if newValue != nil && viewModel.selectedLayout?.name.contains("Adjustable") ?? false {
                    Haptics.impact(style: .medium)
                }
            }
        }
    }
}

fileprivate struct Haptics {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

struct DividerView: View {
    @ObservedObject var layout: CollageLayout
    let parameterName: String
    let axis: Axis
    let viewSize: CGSize
    
    @State private var initialValue: CGFloat?
    @State private var lastHapticValue: CGFloat?

    var body: some View {
        Rectangle()
            .fill(Color.green.opacity(0.8))
            .frame(width: axis == .vertical ? 12 : 50, height: axis == .horizontal ? 12 : 50)
            .cornerRadius(6)
            .overlay(
                Rectangle()
                    .stroke(Color.white, lineWidth: 1)
                    .cornerRadius(6)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if initialValue == nil {
                            initialValue = layout.parameters[parameterName]?.value
                            lastHapticValue = initialValue
                        }
                        
                        guard let startValue = initialValue else { return }

                        let dragProportion = axis == .vertical ? gesture.translation.width / viewSize.width : gesture.translation.height / viewSize.height
                        
                        let newValue = startValue + dragProportion
                        print("LOG: Divider Dragged: param=\(parameterName), newValue=\(newValue)")
                        
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                            layout.updateParameter(parameterName, value: newValue)
                        }
                        
                        if let currentValue = layout.parameters[parameterName]?.value,
                           let lastVal = lastHapticValue,
                           abs(currentValue - lastVal) > 0.02 {
                            Haptics.selection()
                            lastHapticValue = currentValue
                        }
                    }
                    .onEnded { _ in
                        initialValue = nil
                        lastHapticValue = nil
                    }
            )
    }
} 
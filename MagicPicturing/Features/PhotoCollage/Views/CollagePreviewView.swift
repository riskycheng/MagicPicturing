import SwiftUI

struct CollagePreviewView: View {
    @ObservedObject var viewModel: CollageViewModel
    
    var body: some View {
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
                        .position(x: geometry.size.width * (frame.minX + frame.width / 2), y: geometry.size.height * (frame.minY + frame.height / 2))
                        .onTapGesture {
                            viewModel.selectedImageIndex = index
                        }
                    }
                    
                    // Add Divider Handle for adjustable layouts
                    if let layout = viewModel.selectedLayout,
                       viewModel.selectedImageIndex != nil, // Only show when an image is selected
                       !layout.parameters.isEmpty {
                        
                        // This logic can be expanded for other adjustable layouts
                        if layout.name == "2-H-Adjustable" {
                            let frame = layout.frames[0]
                            DividerView(layout: layout, parameterName: "h_split", axis: .vertical, viewSize: geometry.size)
                                .position(x: frame.maxX * geometry.size.width, y: geometry.size.height / 2)
                        } else if layout.name == "2-V-Adjustable" {
                            let frame = layout.frames[0]
                            DividerView(layout: layout, parameterName: "v_split", axis: .horizontal, viewSize: geometry.size)
                                .position(x: geometry.size.width / 2, y: frame.maxY * geometry.size.height)
                        } else if layout.name == "5-L-Big-Grid", let selectedIndex = viewModel.selectedImageIndex {
                            let frames = layout.frames
                            
                            // Vertical Divider Handle (between left and right columns)
                            DividerView(layout: layout, parameterName: "h_split", axis: .vertical, viewSize: geometry.size)
                                .position(x: frames[0].maxX * geometry.size.width, y: geometry.size.height / 2)

                            // Horizontal Divider Handles (for the right column)
                            if selectedIndex > 0 { // Any image on the right is selected
                                // Divider above the selected cell
                                if selectedIndex > 1 {
                                    let prevFrame = frames[selectedIndex - 1]
                                    DividerView(layout: layout, parameterName: "v_split\(selectedIndex - 1)", axis: .horizontal, viewSize: geometry.size)
                                        .position(x: prevFrame.midX * geometry.size.width, y: prevFrame.maxY * geometry.size.height)
                                }
                                // Divider below the selected cell
                                if selectedIndex < 4 {
                                    let currentFrame = frames[selectedIndex]
                                    DividerView(layout: layout, parameterName: "v_split\(selectedIndex)", axis: .horizontal, viewSize: geometry.size)
                                        .position(x: currentFrame.midX * geometry.size.width, y: currentFrame.maxY * geometry.size.height)
                                }
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.selectedImageIndex) { _, newValue in
                if newValue != nil && viewModel.selectedLayout?.parameters.isEmpty == false {
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
        let handleWidth: CGFloat = axis == .vertical ? 14 : 60
        let handleHeight: CGFloat = axis == .horizontal ? 14 : 60
        
        return Rectangle()
            .fill(Color.blue.opacity(0.8))
            .frame(width: handleWidth, height: handleHeight)
            .cornerRadius(7)
            .overlay(
                Capsule()
                    .fill(Color.white)
                    .frame(
                        width: axis == .vertical ? 4 : 24,
                        height: axis == .horizontal ? 4 : 24
                    )
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
                        
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) {
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
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
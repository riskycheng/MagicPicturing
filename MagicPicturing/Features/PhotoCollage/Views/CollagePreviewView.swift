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
                        CollageCellView(
                            image: viewModel.images[index],
                            state: $viewModel.imageStates[index],
                            isSelected: viewModel.selectedImageIndex == index
                        )
                        .frame(
                            width: geometry.size.width * frame.width,
                            height: geometry.size.height * frame.height
                        )
                        .clipped()
                        .offset(
                            x: geometry.size.width * (frame.midX - 0.5),
                            y: geometry.size.height * (frame.midY - 0.5)
                        )
                        .onTapGesture {
                            viewModel.selectedImageIndex = index
                        }
                    }
                    
                    // Add Divider Handle for adjustable layouts
                    if let layout = viewModel.selectedLayout, layout.name.contains("Adjustable") {
                        // Example for the '5-L-Big-Grid-Adjustable'
                        if layout.name == "5-L-Big-Grid-Adjustable" {
                            let frame = layout.frames[0] // Divider is at the right edge of the first frame
                            
                            DividerView(layout: layout, parameterName: "h_split", axis: .vertical, viewSize: geometry.size)
                                .offset(x: geometry.size.width * (frame.maxX - 0.5))
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
        }
    }
}

struct DividerView: View {
    @ObservedObject var layout: CollageLayout
    let parameterName: String
    let axis: Axis
    let viewSize: CGSize
    
    @State private var initialValue: CGFloat?

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.4))
            .frame(width: axis == .vertical ? 10 : viewSize.width, height: axis == .horizontal ? 10 : viewSize.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if initialValue == nil {
                            initialValue = layout.parameters[parameterName]?.value
                        }
                        
                        guard let startValue = initialValue, let param = layout.parameters[parameterName] else { return }

                        let dragAmount = axis == .vertical ? gesture.translation.width / viewSize.width : gesture.translation.height / viewSize.height
                        
                        let newValue = startValue + dragAmount
                        
                        // Clamp the value within the allowed range
                        let clampedValue = min(max(newValue, param.range.lowerBound), param.range.upperBound)
                        
                        if clampedValue != param.value {
                             layout.parameters[parameterName]?.value = clampedValue
                        }
                    }
                    .onEnded { _ in
                        initialValue = nil
                    }
            )
    }
} 
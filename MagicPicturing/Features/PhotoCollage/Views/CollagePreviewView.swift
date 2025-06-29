import SwiftUI

struct CollagePreviewView: View {
    @ObservedObject var viewModel: CollageViewModel
    var isForExport: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !isForExport {
                    // MARK: - Background Layer (Live Preview Only)
                    if let gradient = viewModel.backgroundGradient {
                        LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        viewModel.backgroundColor
                            .edgesIgnoringSafeArea(.all)
                    }

                    // MARK: - Material/Blur Layer (Live Preview Only)
                    if viewModel.backgroundMaterialOpacity > 0 {
                        Rectangle()
                            .fill(.regularMaterial)
                            .opacity(viewModel.backgroundMaterialOpacity)
                            .edgesIgnoringSafeArea(.all)
                    }

                    // Background to dismiss selection
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedImageIndex = nil
                        }
                }

                // MARK: - Collage Cells (Always Visible)
                if let layout = viewModel.selectedLayout {
                    ForEach(Array(viewModel.imageStates.enumerated()), id: \.element.id) { index, state in
                        if index < layout.cellStates.count {
                            let cellState = layout.cellStates[index]
                            let spacing = viewModel.borderWidth / 2

                            let absoluteFrame = CGRect(
                                x: cellState.frame.minX * geometry.size.width,
                                y: cellState.frame.minY * geometry.size.height,
                                width: cellState.frame.width * geometry.size.width,
                                height: cellState.frame.height * geometry.size.height
                            )
                            let insetFrame = absoluteFrame.insetBy(dx: spacing, dy: spacing)

                            CollageCellView(
                                state: state,
                                isSelected: viewModel.selectedImageIndex == index,
                                shapeDefinition: cellState.shapeDefinition,
                                layoutRotation: cellState.rotation,
                                cornerRadius: viewModel.cornerRadius
                            )
                            .frame(width: insetFrame.width, height: insetFrame.height)
                            .shadow(color: .black.opacity(viewModel.shadowRadius > 0 ? 0.4 : 0), radius: viewModel.shadowRadius, x: 0, y: viewModel.shadowRadius / 2)
                            .rotationEffect(cellState.rotation)
                            .position(x: insetFrame.midX, y: insetFrame.midY)
                            .onTapGesture {
                                viewModel.selectedImageIndex = index
                            }
                        }
                    }
                    
                    // MARK: - Dynamic Divider Handles
                    if !isForExport, let layout = viewModel.selectedLayout, viewModel.selectedImageIndex != nil {
                        
                        // Special case for complex layouts first
                        if layout.name == "5-L-Big-Grid" {
                            let h_split = layout.parameters["h_split1"]!.value
                            let v1 = layout.parameters["v_split1"]!.value
                            let v2 = layout.parameters["v_split2"]!.value
                            let v3 = layout.parameters["v_split3"]!.value
                            
                            // Vertical Divider
                            DividerView(layout: layout, parameterName: "h_split1", axis: .vertical, viewSize: geometry.size)
                                .position(x: h_split * geometry.size.width, y: geometry.size.height / 2)

                            // Horizontal Dividers (positioned relative to the right column)
                            let rightColumnX = h_split * geometry.size.width
                            let rightColumnWidth = (1 - h_split) * geometry.size.width
                            
                            DividerView(layout: layout, parameterName: "v_split1", axis: .horizontal, viewSize: geometry.size)
                                .position(x: rightColumnX + rightColumnWidth / 2, y: v1 * geometry.size.height)
                            DividerView(layout: layout, parameterName: "v_split2", axis: .horizontal, viewSize: geometry.size)
                                .position(x: rightColumnX + rightColumnWidth / 2, y: v2 * geometry.size.height)
                            DividerView(layout: layout, parameterName: "v_split3", axis: .horizontal, viewSize: geometry.size)
                                .position(x: rightColumnX + rightColumnWidth / 2, y: v3 * geometry.size.height)
                        } else {
                            // Generic logic for simple grids and strips
                            let hSplitParams = layout.parameters.filter { $0.key.starts(with: "h_split") }
                            let vSplitParams = layout.parameters.filter { $0.key.starts(with: "v_split") }

                            ForEach(Array(hSplitParams.keys.sorted()), id: \.self) { key in
                                if let param = hSplitParams[key] {
                                    DividerView(layout: layout, parameterName: key, axis: .vertical, viewSize: geometry.size)
                                        .position(x: param.value * geometry.size.width, y: geometry.size.height / 2)
                                }
                            }
                            
                            ForEach(Array(vSplitParams.keys.sorted()), id: \.self) { key in
                                if let param = vSplitParams[key] {
                                    DividerView(layout: layout, parameterName: key, axis: .horizontal, viewSize: geometry.size)
                                        .position(x: geometry.size.width / 2, y: param.value * geometry.size.height)
                                }
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.selectedImageIndex) { _, newValue in
                if !isForExport, newValue != nil && viewModel.selectedLayout?.parameters.isEmpty == false {
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
            .fill(Color.accentColor.opacity(0.8))
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

private func v_split_fract(_ index: Int, frac: CGFloat, from: CGFloat = 0, in rect: CGRect) -> CGRect {
    let y = rect.minY + from * rect.height
    let h = frac * rect.height
    return CGRect(x: rect.minX, y: y, width: rect.width, height: h)
}

// Horizontal fractional split
private func h_split_fract(_ index: Int, frac: CGFloat, from: CGFloat = 0, in rect: CGRect) -> CGRect {
    let x = rect.minX + from * rect.width
    let w = frac * rect.width
    return CGRect(x: x, y: rect.minY, width: w, height: rect.height)
} 
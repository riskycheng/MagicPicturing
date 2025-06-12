import SwiftUI

struct CollageCellView: View {
    let image: UIImage
    @Binding var state: CollageImageState
    let isSelected: Bool
    
    // States for live gesture tracking
    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    
    var body: some View {
        let magnificationGesture = MagnificationGesture()
            .onChanged { value in
                self.currentScale = value
            }
            .onEnded { value in
                state.scale *= value
                self.currentScale = 1.0
            }
        
        let dragGesture = DragGesture()
            .onChanged { value in
                self.currentOffset = value.translation
            }
            .onEnded { value in
                state.offset.width += value.translation.width
                state.offset.height += value.translation.height
                self.currentOffset = .zero
            }
            
        let combinedGesture = dragGesture.simultaneously(with: magnificationGesture)

        return ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .scaleEffect(state.scale * currentScale)
                .offset(x: state.offset.width + currentOffset.width, y: state.offset.height + currentOffset.height)
                .rotationEffect(state.rotation)
                .scaleEffect(x: state.isFlippedHorizontally ? -1 : 1, y: state.isFlippedVertically ? -1 : 1, anchor: .center)
            
            if isSelected {
                Rectangle()
                    .stroke(Color.green, lineWidth: 4)
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .gesture(isSelected ? combinedGesture : nil)
    }
} 
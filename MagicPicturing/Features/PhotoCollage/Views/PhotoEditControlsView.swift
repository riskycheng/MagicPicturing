import SwiftUI

struct PhotoEditControlsView: View {
    @ObservedObject var viewModel: CollageViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                // Example Button: Rotate
                Button(action: {
                    viewModel.rotateSelectedImage()
                }) {
                    VStack {
                        Image(systemName: "rotate.right.fill")
                            .font(.title2)
                        Text("旋转")
                            .font(.caption)
                    }
                }
                
                // Example Button: Flip Horizontal
                Button(action: {
                    viewModel.flipSelectedImageHorizontally()
                }) {
                    VStack {
                        Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill")
                            .font(.title2)
                        Text("水平翻转")
                            .font(.caption)
                    }
                }
                
                // Example Button: Flip Vertical
                Button(action: {
                    viewModel.flipSelectedImageVertically()
                }) {
                    VStack {
                        Image(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down.fill")
                            .font(.title2)
                        Text("垂直翻转")
                            .font(.caption)
                    }
                }
            }
            .padding()
            .foregroundColor(.white)
        }
        .background(Color.black.opacity(0.75))
        .cornerRadius(15)
        .padding(.horizontal)
    }
} 
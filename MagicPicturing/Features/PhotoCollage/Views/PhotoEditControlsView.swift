import SwiftUI

struct PhotoEditControlsView: View {
    @ObservedObject var viewModel: CollageViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    controlButton(icon: "rotate.right.fill", text: "旋转") {
                        viewModel.rotateSelectedImage()
                    }
                    
                    controlButton(icon: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill", text: "水平翻转") {
                        viewModel.flipSelectedImageHorizontally()
                    }
                    
                    controlButton(icon: "arrow.up.and.down.righttriangle.up.righttriangle.down.fill", text: "垂直翻转") {
                        viewModel.flipSelectedImageVertically()
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1)
                .padding(.vertical, 10)

            Button(action: {
                viewModel.selectedImageIndex = nil
            }) {
                Text("返回")
                    .font(.headline)
                    .padding(.horizontal, 20)
            }
            .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(height: 65)
        .background(.regularMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.bottom, 5)
    }

    @ViewBuilder
    private func controlButton(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(text)
                    .font(.caption)
            }
        }
        .foregroundColor(Color(UIColor.secondaryLabel))
    }
} 
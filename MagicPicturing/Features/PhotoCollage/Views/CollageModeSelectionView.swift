import SwiftUI
import Photos

struct CollageModeSelectionView: View {
    let assets: [PHAsset]
    let images: [UIImage]

    var body: some View {
        VStack(spacing: 40) {
            Text("选择一个模式")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            NavigationLink(destination: CollageWorkspaceView(assets: assets)) {
                ModeOptionView(
                    title: "模板拼图",
                    description: "根据预设的模板快速创建拼图。",
                    iconName: "square.grid.2x2"
                )
            }

            NavigationLink(destination: CollageCanvasWorkspaceView(selectedAssets: assets, images: images)) {
                ModeOptionView(
                    title: "自由拼图",
                    description: "自由拖放、调整大小和旋转图片。",
                    iconName: "wand.and.stars"
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("选择模式")
    }
}

struct ModeOptionView: View {
    let title: String
    let description: String
    let iconName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: iconName)
                    .font(.title)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
            .foregroundColor(.white)

            Text(description)
                .font(.body)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
} 
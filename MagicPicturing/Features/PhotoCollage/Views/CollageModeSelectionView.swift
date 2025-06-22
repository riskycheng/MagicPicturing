import SwiftUI
import Photos

struct CollageModeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let assets: [PHAsset]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("选择你的拼图模式")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            VStack(spacing: 20) {
                NavigationLink(destination: CollageWorkspaceView(assets: assets)) {
                    ModeButton(title: "模板拼图", description: "选择一个预设模板开始", icon: "rectangle.grid.2x2.fill")
                }
                
                NavigationLink(destination: FreeCollageWorkspaceView(initialAssets: assets)) {
                    ModeButton(title: "自由拼图", description: "在画布上自由缩放和旋转", icon: "wand.and.stars")
                }
            }
            
            Spacer()
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
        .environment(\.colorScheme, .light)
        .navigationTitle("选择模式")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
            }
        }
    }
}

private struct ModeButton: View {
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.accentColor)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
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
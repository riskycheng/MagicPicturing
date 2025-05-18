//
//  NFTGalleryView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/15.
//

import SwiftUI
import Combine

struct NFTGalleryView: View {
    @ObservedObject var viewModel: PhotoLibraryViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var currentIndex: Int = 0
    @State private var navigateToDetailView = false
    @State private var showThreeDGridView = false
    @State private var selectedMode: Int = 0
    @State private var isDragging = false
    
    // Constants for the NFT Gallery card stack
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 420
    private let maxVisibleCards = 5
    private let cardSpacing: CGFloat = 40
    private let swipeThreshold: CGFloat = 50
    private let rotationRadius: CGFloat = 600 // 圆柱体半径
    private let angularSpacing: Double = 0.35 // 卡片之间的角度间隔
    
    // Computed property for continuous angle offset based on drag
    private var continuousAngleOffset: Double {
        return Double(dragOffset) / (rotationRadius * 0.5)
    }
    
    // Helper method to get the destination view based on selected mode
    @ViewBuilder
    private func destinationView() -> some View {
        switch selectedMode {
        case 0:
            ThreeDGridView()
        case 1:
            Text("水印边框功能正在开发中...").font(.title)
        case 2:
            Text("滤镜功能正在开发中...").font(.title)
        case 3:
            Text("拼图功能正在开发中...").font(.title)
        case 4:
            Text("AI消除功能正在开发中...").font(.title)
        case 5:
            Text("3D人像功能正在开发中...").font(.title)
        default:
            Text("功能正在开发中...").font(.title)
        }
    }
    
    // Helper method for the title view
    private func titleView() -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text("Magic ")
                .font(.system(size: 45, weight: .bold))
                .foregroundColor(.black)
            
            Text("Picturing")
                .font(.custom("Times New Roman", size: 45))
                .italic()
                .foregroundColor(.black)
        }
        .padding(.bottom, 550) // 将标题放在更高的位置
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // NFT Gallery background
                ZStack {
                    // Navigation link to detail view for modes other than ThreeDGridView
                    NavigationLink(
                        "",
                        destination: destinationView(),
                        isActive: $navigateToDetailView
                    )
                    .opacity(0)
                    
                    // 浅绿色背景
                    Color(red: 0.82, green: 0.84, blue: 0.67)
                    
                    // 标题文本
                    titleView()
                }
                .edgesIgnoringSafeArea(.all)
                
                // Card Stack
                cardStackView()
                    .padding(.top, 80) // 整体往上移动，避免与底部导航栏重叠
                    .padding(.bottom, 120)
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showThreeDGridView) {
            ThreeDGridView()
        }
    }
    
    // 获取环形索引 - 实现环形缓冲区
    private func getRingIndex(baseIndex: Int, offset: Int) -> Int {
        guard !viewModel.filteredPhotos.isEmpty else { return 0 }
        
        let totalCount = viewModel.filteredPhotos.count
        let rawIndex = (baseIndex + offset) % totalCount
        
        // 处理负数索引，确保它们正确环绕
        return rawIndex < 0 ? rawIndex + totalCount : rawIndex
    }
    
    // 计算卡片在圆柱体上的角度 - 更流畅的连续计算
    private func calculateCardAngle(for index: Int) -> Double {
        // 基础角度加上拖动产生的连续角度偏移
        return Double(index) * angularSpacing + continuousAngleOffset
    }
    
    // 计算水平偏移量，实现圆柱体滚动效果
    private func calculateHorizontalOffset(for index: Int) -> CGFloat {
        // 使用三角函数计算水平偏移
        let angle = calculateCardAngle(for: index)
        return sin(angle) * rotationRadius * 0.25
    }
    
    // 计算垂直偏移量，实现圆柱体滚动效果
    private func calculateVerticalOffset(for index: Int) -> CGFloat {
        // 使用三角函数计算垂直偏移
        let angle = calculateCardAngle(for: index)
        return (1 - cos(angle)) * 40
    }
    
    // 计算缩放比例，实现圆柱体滚动效果
    private func calculateScale(for index: Int) -> CGFloat {
        let angle = calculateCardAngle(for: index)
        
        // 基于角度计算缩放比例 - 增强3D效果，使背景卡片更小
        let scale = cos(angle) * 0.4 + 0.6
        
        // 确保中心位置的卡片更大
        if abs(angle) < 0.2 {
            return 1.0
        }
        
        return scale
    }
    
    // 计算旋转角度，实现圆柱体滚动效果
    private func calculateRotation(for index: Int) -> Double {
        // 转换为度数
        return calculateCardAngle(for: index) * 180 / .pi
    }
    
    // 计算Z轴索引，确保正确的堆叠顺序
    private func calculateZIndex(for index: Int) -> Double {
        // 基于余弦值计算Z轴索引
        return cos(calculateCardAngle(for: index)) * 10
    }
    
    // 计算透明度，实现圆柱体滚动效果
    private func calculateOpacity(for index: Int) -> Double {
        let angle = calculateCardAngle(for: index)
        
        // 基于角度计算透明度
        let opacity = cos(angle) * 0.3 + 0.7
        
        // 确保中心位置的卡片完全不透明
        if abs(angle) < 0.2 {
            return 1.0
        }
        
        return opacity
    }
    
    // Helper method to create a single card in the stack
    private func cardView(for index: Int) -> some View {
        let ringIndex = getRingIndex(baseIndex: currentIndex, offset: index)
        let photo = viewModel.filteredPhotos[ringIndex]
        let isFocused = abs(calculateCardAngle(for: index)) < 0.2
        
        // Pre-calculate all transformations
        let scale = calculateScale(for: index)
        let rotation = calculateRotation(for: index)
        let xOffset = calculateHorizontalOffset(for: index)
        let yOffset = calculateVerticalOffset(for: index)
        let opacity = calculateOpacity(for: index)
        let zIndex = calculateZIndex(for: index)
        
        return NFTCardView(
            photo: photo,
            isFocused: isFocused,
            offset: dragOffset,
            index: index,
            totalCount: viewModel.filteredPhotos.count,
            currentIndex: ringIndex,
            onCardTap: {
                // 任何卡片被点击时，立即将其设为中心卡片并导航
                if !isFocused {
                    // 如果点击的不是中心卡片，先将其移到中心
                    currentIndex = ringIndex
                    dragOffset = 0
                    // 立即更新选中模式
                    selectedMode = ringIndex % 6 // 确保在模式范围内
                } else {
                    // 如果点击的是中心卡片，直接导航
                    print("Card tapped: \(ringIndex)")
                    // 如果是3D九宫格模式，使用全屏sheet呈现
                    if ringIndex % 6 == 0 {
                        showThreeDGridView = true
                    } else {
                        navigateToDetailView = true
                    }
                }
            }
        )
        .scaleEffect(scale)
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0.1),
            anchor: .center,
            anchorZ: 0,
            perspective: 0.3
        )
        .offset(x: xOffset, y: yOffset)
        .opacity(opacity)
        .zIndex(zIndex)
    }
    
    private func cardStackView() -> some View {
        GeometryReader { geometry in
            ZStack {
                if !viewModel.filteredPhotos.isEmpty {
                    // 显示更多卡片以实现更丝滑的效果
                    ForEach(-3..<4, id: \.self) { index in
                        cardView(for: index)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        // 直接将拖动位移量应用到偏移量，实现跟手效果
                        isDragging = true
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        isDragging = false
                        let velocity = value.predictedEndLocation.x - value.location.x
                        let finalOffset = value.translation.width + velocity * 0.3
                        
                        // 计算最终应该停留在哪个卡片位置
                        let angleOffset = Double(finalOffset) / (rotationRadius * 0.5)
                        let cardIndexOffset = Int(round(angleOffset / angularSpacing))
                        
                        // 直接更新当前索引，不要动画
                        if abs(cardIndexOffset) > 0 {
                            // 立即更新当前索引，无需动画
                            currentIndex = getRingIndex(baseIndex: currentIndex, offset: -cardIndexOffset)
                            dragOffset = 0 // 直接重置偏移量，不使用动画
                        } else {
                            // 如果偏移不够，直接重置而不使用动画
                            dragOffset = 0
                        }
                        
                        // 如果当前卡片在中心位置，直接更新选中模式
                        let centerCardIndex = getRingIndex(baseIndex: currentIndex, offset: 0)
                        selectedMode = centerCardIndex % 6 // 确保在模式范围内
                    }
            )
        }
    }
}

// MARK: - NFT Card View
struct NFTCardView: View {
    let photo: PhotoItem
    let isFocused: Bool
    let offset: CGFloat
    let index: Int
    let totalCount: Int
    let currentIndex: Int
    let onCardTap: () -> Void
    
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 420
    
    // Calculate height based on focus state - background cards will be shorter
    private var dynamicCardHeight: CGFloat {
        isFocused ? cardHeight : cardHeight * 0.85
    }
    
    // Calculate opacity based on focus state - background cards will be dimmed
    private var cardOpacity: Double {
        isFocused ? 1.0 : 0.7
    }
    
    private var randomNumber: Int {
        let numbers = [4032, 6721, 8901, 1234, 5678]
        return numbers[abs(index) % numbers.count]
    }
    
    // Card titles (names)
    private var cardTitles: [String] {
        ["立体九宫格", "水印边框", "滤镜", "拼图", "AI消除", "3D人像"]
    }
    
    // Card descriptions
    private var cardDescriptions: [String] {
        ["立体人像 九宫格 朋友圈", 
         "生成图片的边框水印，附带照片信息logo等", 
         "给图片进行滤镜调整", 
         "用于将多张照片按照不同的布局方式进行拼接", 
         "采用AI进行物体消除", 
         "通过对比边框，使得人像具有3D效果"]
    }
    
    var body: some View {
        ZStack {
            // Main card - 完全透明风格
            ZStack(alignment: .bottom) {
                // Make the entire card clickable with a transparent overlay
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Card tapped in NFTCardView")
                        onCardTap()
                    }
                    .frame(width: cardWidth, height: dynamicCardHeight)
                    .zIndex(10)
                // 使用真实图片资源
                Image(photo.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: dynamicCardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .opacity(cardOpacity)
                
                // 底部信息区域 - 半透明黑色背景
                VStack(alignment: .leading, spacing: 8) {
                    // Card title (name)
                    Text(cardTitles[currentIndex % cardTitles.count])
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Card description
                    Text(cardDescriptions[currentIndex % cardDescriptions.count])
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(
                    Color.black.opacity(0.6)
                        .blur(radius: 0.5)
                )
                
                // Removed the position indicator pill
            }
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
            
            // Mode tag in corner
            if isFocused {
                VStack {
                    HStack {
                        Text("模式 \(currentIndex + 1)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.7))
                            )
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(15)
                .frame(width: cardWidth, height: cardHeight)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - Preview
struct NFTGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        NFTGalleryView(viewModel: PhotoLibraryViewModel())
    }
}

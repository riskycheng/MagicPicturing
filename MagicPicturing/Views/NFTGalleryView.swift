//
//  NFTGalleryView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/15.
//

import SwiftUI

struct NFTGalleryView: View {
    @ObservedObject var viewModel: PhotoLibraryViewModel
    @GestureState private var dragState = DragState.inactive
    @State private var cardOffset: CGFloat = 0
    @State private var currentIndex: Int = 0
    
    // Constants for the NFT Gallery card stack
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 420
    private let maxVisibleCards = 5
    private let cardSpacing: CGFloat = 40
    private let swipeThreshold: CGFloat = 50
    private let rotationRadius: CGFloat = 600 // 圆柱体半径
    
    // Drag state enum
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }
    
    var body: some View {
        ZStack {
            // NFT Gallery background
            ZStack {
                // 浅绿色背景
                Color(hex: "D1D7AB")
                
                // 标题文本 - 简化为只显示Magic Picturing
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
            .edgesIgnoringSafeArea(.all)
            
            // Card Stack
            cardStackView()
                .padding(.top, 80) // 整体往上移动，避免与底部导航栏重叠
                .padding(.bottom, 120)
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
    
    // 计算水平偏移量，实现圆柱体滚动效果
    private func calculateHorizontalOffset(for index: Int, dragOffset: CGFloat) -> CGFloat {
        // 计算卡片在圆柱体上的角度
        let baseAngle = Double(index) * 0.35
        let dragAngle = Double(dragOffset) / Double(rotationRadius)
        let totalAngle = baseAngle + dragAngle
        
        // 使用三角函数计算水平偏移
        return sin(totalAngle) * rotationRadius * 0.25
    }
    
    // 计算垂直偏移量，实现圆柱体滚动效果
    private func calculateVerticalOffset(for index: Int, dragOffset: CGFloat) -> CGFloat {
        // 计算卡片在圆柱体上的角度
        let baseAngle = Double(index) * 0.35
        let dragAngle = Double(dragOffset) / Double(rotationRadius)
        let totalAngle = baseAngle + dragAngle
        
        // 使用三角函数计算垂直偏移
        return (1 - cos(totalAngle)) * 40
    }
    
    // 计算缩放比例，实现圆柱体滚动效果
    private func calculateScale(for index: Int, dragOffset: CGFloat) -> CGFloat {
        // 计算卡片在圆柱体上的角度
        let baseAngle = Double(index) * 0.35
        let dragAngle = Double(dragOffset) / Double(rotationRadius)
        let totalAngle = baseAngle + dragAngle
        
        // 基于角度计算缩放比例 - 增强3D效果，使背景卡片更小
        let scale = cos(totalAngle) * 0.4 + 0.6
        
        // 确保当前卡片更大，增强中央卡片与背景卡片的对比
        if index == 0 && dragOffset.magnitude < 100 {
            return 1.0
        }
        
        return scale
    }
    
    // 计算旋转角度，实现圆柱体滚动效果
    private func calculateRotation(for index: Int, dragOffset: CGFloat) -> Double {
        // 计算卡片在圆柱体上的角度
        let baseAngle = Double(index) * 0.35
        let dragAngle = Double(dragOffset) / Double(rotationRadius)
        let totalAngle = baseAngle + dragAngle
        
        // 转换为度数
        return totalAngle * 180 / .pi
    }
    
    // 计算Z轴索引，确保正确的堆叠顺序
    private func calculateZIndex(for index: Int, dragOffset: CGFloat) -> Double {
        // 计算卡片在圆柱体上的角度
        let baseAngle = Double(index) * 0.35
        let dragAngle = Double(dragOffset) / Double(rotationRadius)
        let totalAngle = baseAngle + dragAngle
        
        // 基于余弦值计算Z轴索引
        return cos(totalAngle) * 10
    }
    
    // 计算透明度，实现圆柱体滚动效果
    private func calculateOpacity(for index: Int, dragOffset: CGFloat) -> Double {
        // 计算卡片在圆柱体上的角度
        let baseAngle = Double(index) * 0.35
        let dragAngle = Double(dragOffset) / Double(rotationRadius)
        let totalAngle = baseAngle + dragAngle
        
        // 基于角度计算透明度
        let opacity = cos(totalAngle) * 0.3 + 0.7
        
        // 确保当前卡片完全不透明
        if index == 0 && dragOffset.magnitude < 100 {
            return 1.0
        }
        
        return opacity
    }
    
    private func cardStackView() -> some View {
        GeometryReader { geometry in
            ZStack {
                if !viewModel.filteredPhotos.isEmpty {
                    // 显示更多卡片以实现更丝滑的效果
                    ForEach(-2..<3, id: \.self) { index in
                        // 使用环形索引获取正确的卡片
                        let ringIndex = getRingIndex(baseIndex: currentIndex, offset: index)
                        let photo = viewModel.filteredPhotos[ringIndex]
                        let isFocused = index == 0
                        
                        NFTCardView(
                            photo: photo,
                            isFocused: isFocused,
                            offset: dragState.translation.width,
                            index: index,
                            totalCount: viewModel.filteredPhotos.count,
                            currentIndex: ringIndex
                        )
                        .scaleEffect(calculateScale(for: index, dragOffset: dragState.translation.width))
                        .rotation3DEffect(
                            .degrees(calculateRotation(for: index, dragOffset: dragState.translation.width)),
                            axis: (x: 0, y: 1, z: 0.1),
                            anchor: .center,
                            anchorZ: 0,
                            perspective: 0.3
                        )
                        .offset(
                            x: calculateHorizontalOffset(for: index, dragOffset: dragState.translation.width),
                            y: calculateVerticalOffset(for: index, dragOffset: dragState.translation.width)
                        )
                        .opacity(calculateOpacity(for: index, dragOffset: dragState.translation.width))
                        .zIndex(calculateZIndex(for: index, dragOffset: dragState.translation.width))
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($dragState) { value, state, _ in
                        state = .dragging(translation: value.translation)
                    }
                    .onEnded { value in
                        let predictedEndOffset = value.predictedEndTranslation.width
                        let velocity = abs(value.predictedEndTranslation.width - value.translation.width)
                        
                        // 使用速度和方向来决定滑动行为
                        if abs(predictedEndOffset) > swipeThreshold || velocity > 300 {
                            if predictedEndOffset < 0 {
                                // 向左滑动 - 下一张 (显示右边的卡片)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    currentIndex = getRingIndex(baseIndex: currentIndex, offset: 1)
                                    cardOffset = 0
                                }
                            } else {
                                // 向右滑动 - 上一张 (显示左边的卡片)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    currentIndex = getRingIndex(baseIndex: currentIndex, offset: -1)
                                    cardOffset = 0
                                }
                            }
                        } else {
                            // 回到原位
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                cardOffset = 0
                            }
                        }
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
    
    private var collectionNames: [String] {
        ["Shadowverse", "Titans", "Raven", "Legends", "Ethereal"]
    }
    
    private var creatorNames: [String] {
        ["Umbra", "Nexus", "Void", "Stellar", "Prism"]
    }
    
    var body: some View {
        ZStack {
            // Main card - 完全透明风格
            ZStack(alignment: .bottom) {
                // 使用真实图片资源
                Image(photo.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: dynamicCardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .opacity(cardOpacity)
                
                // 底部信息区域 - 半透明黑色背景
                VStack(alignment: .leading, spacing: 8) {
                    // Collection name
                    Text(collectionNames[abs(index) % collectionNames.count])
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Creator info
                    HStack {
                        ForEach(0..<min(2, creatorNames.count), id: \.self) { i in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: photo.gradientStart),
                                            Color(hex: photo.gradientEnd)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                )
                                .offset(x: CGFloat(i * -15))
                                .zIndex(Double(2 - i))
                        }
                        
                        Text(creatorNames[abs(index) % creatorNames.count])
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.leading, 5)
                        
                        if abs(index) % 2 == 0 {
                            Text(creatorNames[(abs(index) + 1) % creatorNames.count])
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.leading, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(
                    Color.black.opacity(0.6)
                        .blur(radius: 0.5)
                )
                
                // Position indicator pill - 放在右上角
                if isFocused {
                    HStack(spacing: 4) {
                        Text("\(currentIndex + 1) of \(totalCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.7)
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(20)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
            
            // ID tag in corner
            if isFocused {
                VStack {
                    HStack {
                        Text("#\(randomNumber)")
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

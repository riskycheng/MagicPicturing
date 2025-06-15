//
//  NFTGalleryView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/15.
//

import SwiftUI
import Combine

struct NFTGalleryView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()

    // --- Unified Scrolling State ---
    // The single source of truth for the carousel's position.
    // Represents a continuous index into the photo array.
    @State private var continuousScrollPosition: CGFloat = 0.0
    
    // State to manage the drag gesture, tracking its start position.
    @State private var gestureStartScrollPosition: CGFloat = 0.0
    
    @State private var navigateToDetailView = false
    @State private var showThreeDGridView = false
    @State private var showCollageFlow = false
    @State private var showThreeDGridEntry = false
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
    private var cancellables = Set<AnyCancellable>() // For managing timers
    
    // Card titles (central source of truth)
    private let cardTitles: [String] = ["立体九宫格", "拼图", "水印边框", "滤镜", "AI消除", "3D人像"]

    // --- Computed Properties from Unified State ---

    // The number of pixels to drag to move by one full index.
    private var pixelsPerIndex: CGFloat {
        return CGFloat(angularSpacing * rotationRadius * 0.5)
    }

    // The discrete, "snapped" index that is closest to the current continuous position.
    private var snappedIndex: Int {
        Int(round(continuousScrollPosition))
    }
    
    // The current "drag offset" in pixels, derived from the fractional part of the continuous position.
    // This allows all existing geometry calculations to work without modification.
    private var fractionalDragOffset: CGFloat {
        let fractionalPart = continuousScrollPosition - CGFloat(snappedIndex)
        return -fractionalPart * pixelsPerIndex
    }

    // The continuous angle offset for the 3D cylinder effect, driven by the fractional offset.
    private var continuousAngleOffset: Double {
        return Double(fractionalDragOffset) / (rotationRadius * 0.5)
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
                    
                    // 白色背景
                    Color.white
                    
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
        .fullScreenCover(isPresented: $showCollageFlow) {
            CollageEntryView()
        }
        .fullScreenCover(isPresented: $showThreeDGridEntry) {
            ThreeDGridEntryView()
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
        // The base for calculating the ring index is now the "snapped" index.
        let ringIndex = getRingIndex(baseIndex: snappedIndex, offset: index)
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
            title: cardTitles[ringIndex % cardTitles.count],
            index: index,
            totalCount: viewModel.filteredPhotos.count,
            currentIndex: ringIndex,
            onCardTap: {
                // Determine the absolute target position in the continuous space.
                let targetPosition = CGFloat(snappedIndex + index)
                
                // If the tapped card is not focused, animate to it.
                if !isFocused {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        continuousScrollPosition = targetPosition
                    }
                } else {
                    // If the focused card is tapped, perform the navigation.
                    let finalIndex = getRingIndex(baseIndex: 0, offset: Int(targetPosition))
                    selectedMode = finalIndex % cardTitles.count

                    switch selectedMode {
                    case 0: // 立体九宫格
                        showThreeDGridEntry = true
                    case 1: // 拼图
                        showCollageFlow = true
                    default:
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
        .id(ringIndex)
        .transition(.opacity)
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
            .highPriorityGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            // Store the starting position of the scroll when the drag begins.
                            gestureStartScrollPosition = continuousScrollPosition
                        }
                        // Calculate the drag distance in terms of indices and update the continuous position.
                        let dragDistanceInPixels = value.translation.width
                        continuousScrollPosition = gestureStartScrollPosition - (dragDistanceInPixels / pixelsPerIndex)
                    }
                    .onEnded { value in
                        isDragging = false

                        // --- Unified Physics-Based Animation on a Single State ---

                        // 1. Calculate velocity in terms of indices-per-second.
                        let velocityInPixels = value.predictedEndLocation.x - value.location.x
                        let velocityInIndices = velocityInPixels / pixelsPerIndex
                        
                        // 2. Project where the scroll would end based on current position and velocity.
                        let projectedPosition = continuousScrollPosition - velocityInIndices * 0.1 // Momentum factor

                        // 3. The animation's target is the nearest whole number index.
                        let targetPosition = round(projectedPosition)

                        // 4. Use a single, robust spring animation on the single source of truth.
                        let springAnimation = Animation.interpolatingSpring(
                            mass: 0.8,
                            stiffness: 100.0,
                            damping: 25.0, // Overdamped to prevent any bouncing/oscillation
                            initialVelocity: -velocityInIndices // Velocity is passed to the animator
                        )
                        
                        withAnimation(springAnimation) {
                            continuousScrollPosition = targetPosition
                        }
                        
                        // 5. Update non-animating state after a delay.
                        // This does not affect the geometry and will not cause a jump.
                        let finalIndex = getRingIndex(baseIndex: 0, offset: Int(targetPosition))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            // Ensure another drag has not started
                            if !isDragging {
                                self.selectedMode = finalIndex % 6
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
    let title: String
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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Card Image
            Image(photo.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cardWidth, height: dynamicCardHeight)
                .opacity(cardOpacity)
            
            // Elegant Gradient Overlay
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [
                        .black.opacity(0.8),
                        .black.opacity(0)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: dynamicCardHeight / 2) // Gradient covers lower half
            }

            // Title Text aligned to bottom-left
            VStack {
                Spacer()
                HStack {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 10)
                    Spacer()
                }
            }
        }
        .frame(width: cardWidth, height: dynamicCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5) // Softer shadow
        .onTapGesture {
            onCardTap()
        }
    }
}

// MARK: - Preview
struct NFTGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a public initializer for the preview to access.
        NFTGalleryView()
    }
}

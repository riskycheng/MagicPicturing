//
//  HomeView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showingEditingInterface = false
    @State private var editingMode: EditingMode = .filter
    @State private var selectedFilter: String? = nil
    @State private var filterIntensity: Double = 0.5
    @State private var cardOffset: CGFloat = 0
    
    // Card constants
    private let cardWidth: CGFloat = 340
    private let cardHeight: CGFloat = 500
    private let maxVisibleCards = 3
    private let cardSpacing: CGFloat = 40
    private let swipeThreshold: CGFloat = 50
    
    var body: some View {
        ZStack {
            // NFT Gallery background
            ZStack {
                // 浅绿色背景
                Color(hex: "D1D7AB")
                
                // 标题文本
                VStack {
                    Text("Explore Your")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.black)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Text("NFT ")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("gallery")
                            .font(.custom("Times New Roman", size: 40))
                            .italic()
                            .foregroundColor(.black)
                        
                        Text(" Now")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.bottom, 300) // 将标题放在顶部区域
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Empty space for the title area
                Spacer()
                    .frame(height: 200)
                
                // Card Stack
                cardStackView()
                    .frame(maxHeight: .infinity)
                
                // Bottom spacer
                Spacer()
                    .frame(height: 50)
            }
            
            // Editing interfaces
            if showingEditingInterface {
                editingInterfaceView()
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
            }
        }
    }
    
    // MARK: - Header View
    private func headerView() -> some View {
        HomeHeaderView(addAction: {
            // Add new photo action
        })
    }
    
    // MARK: - Card Stack View
    private func cardStackView() -> some View {
        GeometryReader { geometry in
            ZStack {
                if !viewModel.filteredPhotos.isEmpty {
                    // Create 3D stacked layout
                    ForEach(0..<min(viewModel.filteredPhotos.count, maxVisibleCards), id: \.self) { index in
                        let adjustedIndex = (viewModel.currentIndex + index) % viewModel.filteredPhotos.count
                        let photo = viewModel.filteredPhotos[adjustedIndex]
                        let isTopCard = index == 0
                        
                        // Calculate offset for each card
                        let xOffset = isTopCard ? dragOffset : 0
                        let baseOffset = CGFloat(index) * cardSpacing
                        
                        CardView(
                            photo: photo,
                            isFocused: isTopCard,
                            offset: xOffset,
                            index: index
                        )
                        .offset(x: baseOffset + (isTopCard ? cardOffset : 0))
                        .zIndex(Double(maxVisibleCards - index))
                        .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: cardOffset)
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onChanged { value in
                                    if isTopCard {
                                        isDragging = true
                                        dragOffset = value.translation.width
                                        
                                        // Add subtle rotation based on drag
                                        withAnimation(.interactiveSpring()) {
                                            cardOffset = value.translation.width * 0.7
                                        }
                                    }
                                }
                                .onEnded { value in
                                    if isTopCard {
                                        isDragging = false
                                        let velocity = CGFloat(value.predictedEndLocation.x - value.location.x)
                                        
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if dragOffset > swipeThreshold || velocity > 200 {
                                                // Swipe right
                                                cardOffset = geometry.size.width
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                    viewModel.previousPhoto()
                                                    cardOffset = 0
                                                    dragOffset = 0
                                                }
                                            } else if dragOffset < -swipeThreshold || velocity < -200 {
                                                // Swipe left
                                                cardOffset = -geometry.size.width
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                    viewModel.nextPhoto()
                                                    cardOffset = 0
                                                    dragOffset = 0
                                                }
                                            } else {
                                                // Reset position
                                                cardOffset = 0
                                                dragOffset = 0
                                            }
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            if isTopCard {
                                withAnimation {
                                    showingEditingInterface = true
                                    editingMode = .filter
                                }
                            }
                        }
                    }
                } else {
                    EmptyStateView(
                        title: "没有照片",
                        message: "点击 + 按钮添加新照片开始创作",
                        icon: "photo.on.rectangle.angled"
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Bottom Controls View
    private func bottomControlsView() -> some View {
        VStack(spacing: 0) {
            // Category selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(PhotoCategory.allCases, id: \.self) { category in
                        HomeCategoryButton(
                            category: category,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            withAnimation {
                                viewModel.changeCategory(to: category)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Tab bar
            HStack {
                HomeTabBarItem(
                    icon: "house.fill",
                    title: "首页",
                    isSelected: true
                ) {
                    // Already on home
                }
                
                HomeTabBarItem(
                    icon: "photo.stack",
                    title: "作品",
                    isSelected: false
                ) {
                    // Navigate to works
                }
                
                HomeTabBarItem(
                    icon: "person",
                    title: "我的",
                    isSelected: false
                ) {
                    // Navigate to profile
                }
            }
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground).opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )
        }
        .background(Color.black)
    }
    
    // MARK: - Editing Interface View
    private func editingInterfaceView() -> some View {
        VStack(spacing: 0) {
            // Edit header
            HStack {
                Button(action: {
                    withAnimation {
                        showingEditingInterface = false
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(editingMode.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    // Apply edit action
                    withAnimation {
                        showingEditingInterface = false
                    }
                }) {
                    Text("完成")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.black)
            
            // Edit content
            ScrollView {
                VStack(spacing: 20) {
                    if let currentPhoto = viewModel.currentPhoto {
                        Image(systemName: currentPhoto.symbolName)
                            .font(.system(size: 100))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Edit options based on mode
                    editOptionsView()
                }
                .padding(.bottom, 30)
            }
            
            // Bottom edit tools
            editingToolsBar()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    // MARK: - Helper Methods
    
    // Edit options view based on current mode
    private func editOptionsView() -> some View {
        Group {
            switch editingMode {
            case .filter:
                filterOptionsView()
            case .aiRemove:
                aiRemoveOptionsView()
            case .template:
                templateOptionsView()
            case .adjust:
                adjustOptionsView()
            }
        }
    }
    
    // MARK: - Editing Tools Bar
    private func editingToolsBar() -> some View {
        HStack(spacing: 25) {
            ForEach(EditingMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation {
                        editingMode = mode
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 24))
                            .foregroundColor(editingMode == mode ? .blue : .gray)
                        
                        Text(mode.title)
                            .font(.system(size: 12))
                            .foregroundColor(editingMode == mode ? .blue : .gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.black)
    }
    
    // MARK: - Filter Options View
    private func filterOptionsView() -> some View {
        FilterOptionsView(
            selectedFilter: $selectedFilter,
            filterIntensity: $filterIntensity
        )
    }
    
    // MARK: - AI Remove Options View
    private func aiRemoveOptionsView() -> some View {
        VStack(alignment: .leading) {
            Text("AI消除")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Text("智能去除照片中不需要的元素")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(["人物", "物体", "文字", "瑕疵"], id: \.self) { item in
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: item == "人物" ? "person.crop.circle.badge.xmark" :
                                            item == "物体" ? "cube.transparent.fill" :
                                            item == "文字" ? "text.badge.xmark" : "bandage")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                )
                            
                            Text(item)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Template Options View
    private func templateOptionsView() -> some View {
        VStack(alignment: .leading) {
            Text("模版构图")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Text("使用专业模板优化照片构图")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(0..<6) { index in
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 160)
                                .overlay(
                                    Text("模版\(index + 1)")
                                        .foregroundColor(.white)
                                )
                            
                            Text("风格\(index + 1)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Adjust Options View
    private func adjustOptionsView() -> some View {
        VStack(alignment: .leading) {
            Text("调整参数")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 20) {
                ForEach(["亮度", "对比度", "饱和度", "锐度", "色温"], id: \.self) { adjustment in
                    VStack(alignment: .leading) {
                        Text(adjustment)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("-")
                                .foregroundColor(.gray)
                            
                            Slider(value: .constant(0.5))
                                .accentColor(.blue)
                            
                            Text("+")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}



// MARK: - Editing Mode Enum
enum EditingMode: String, CaseIterable {
    case filter
    case aiRemove
    case template
    case adjust
    
    var title: String {
        switch self {
        case .filter: return "滤镜"
        case .aiRemove: return "AI消除"
        case .template: return "模版构图"
        case .adjust: return "调整"
        }
    }
    
    var iconName: String {
        switch self {
        case .filter: return "camera.filters"
        case .aiRemove: return "wand.and.stars"
        case .template: return "rectangle.3.group"
        case .adjust: return "slider.horizontal.3"
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

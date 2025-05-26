// 这是修复版本的ThreeDGridView.swift
// 请将此文件内容替换到原文件中

import SwiftUI

#if canImport(UIKit)
import UIKit
import PhotosUI
import UniformTypeIdentifiers
#elseif canImport(AppKit)
import AppKit
import UniformTypeIdentifiers
#endif

// 导入所需类型
import Foundation

// 从PersonSegmentationService导入错误类型
extension PersonSegmentationService.PersonSegmentationError {
    // 添加一个fileProviderError类型以匹配ThreeDGridView.swift中的使用
    static func fileProviderError(message: String) -> Self {
        // 这里返回一个合适的错误类型
        return .invalidImage
    }
}

// Custom modifier to handle rotation animation that properly stops when isAnimating is false
struct RotationAnimationModifier: ViewModifier {
    let isAnimating: Bool
    
    @State private var angle: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: angle))
            .onAppear {
                // Reset angle when not animating
                if !isAnimating {
                    angle = 0
                }
            }
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    // Start continuous rotation
                    withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                        angle = 360
                    }
                } else {
                    // Stop at current position and then reset to 0 with a short animation
                    withAnimation(Animation.linear(duration: 0.3)) {
                        angle = 0
                    }
                }
            }
    }
}

// View model to handle the 3D grid effect logic - moved outside the View struct to avoid ViewBuilder issues
class ThreeDGridViewModel: ObservableObject {
    @Published var gridPhotos: [PlatformImage?] = Array(repeating: nil, count: 9)
    
    // Position for the draggable person image
    @Published var personOffsetX: CGFloat = 0
    @Published var personOffsetY: CGFloat = 0
    @Published var personScale: CGFloat = 1.0
    @Published var lastScaleValue: CGFloat = 1.0 // For tracking pinch gesture
    @Published var showGridActionSheet: Bool = false
    
    @Published var mainSubjectPhoto: PlatformImage? = nil {
        didSet {
            if mainSubjectPhoto != nil {
                // Automatically start segmentation when a main subject photo is selected
                Task {
                    await segmentPerson()
                }
            } else {
                // Reset segmentation state if photo is removed
                segmentedPersonImage = nil
                segmentationState = .idle
                segmentationError = nil
            }
        }
    }
    @Published var segmentedPersonImage: PlatformImage? = nil
    // 使用简单枚举表示分割状态
    enum SegmentationStateSimple {
        case idle
        case loading
        case success
        case failure
    }
    @Published var segmentationState: SegmentationStateSimple = .idle
    @Published var segmentationError: String? = nil
    @Published var resultImage: PlatformImage? = nil
    @Published var showingResult = false
    @Published var isGenerating = false
    @Published var currentGridIndex = 0
    @Published var isProcessingSegmentation = false
    
    private let segmentationService: PersonSegmentationServiceProtocol
    
    init(segmentationService: PersonSegmentationServiceProtocol = PersonSegmentationService()) {
        self.segmentationService = segmentationService
    }
    
    var isReadyToGenerate: Bool {
        // Check if we have at least one grid photo and a main subject photo
        return gridPhotos.contains(where: { $0 != nil }) && mainSubjectPhoto != nil
    }
    
    // Add properties to store layout values
    var horizontalPadding: CGFloat = 25
    var gridSpacing: CGFloat = 4
    
    // Generate the grid image only (no person mask) for interactive adjustment
    func generateGridOnlyResult() {
        guard isReadyToGenerate else { return }
        self.isGenerating = true
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            #if canImport(UIKit)
            // Get background images from the grid
            var backgroundImages: [UIImage] = []
            for image in self.gridPhotos {
                if let img = image {
                    backgroundImages.append(img)
                }
            }
            if !backgroundImages.isEmpty {
                // Create a collage WITHOUT the person mask
                self.resultImage = self.createCollageImage(
                    backgroundImages: backgroundImages,
                    personImage: nil,
                    horizontalPadding: self.horizontalPadding,
                    gridSpacing: self.gridSpacing,
                    personOffsetX: self.personOffsetX,
                    personOffsetY: self.personOffsetY,
                    personScale: self.personScale
                )
            } else {
                self.resultImage = nil
            }
            #elseif canImport(AppKit)
            self.resultImage = self.mainSubjectPhoto
            #endif
            self.isGenerating = false
            self.showingResult = false // Don't show the result yet, wait for the final generation
        }
    }

    // Generate the grid image without the person mask for preview
    func generateThreeDGrid() {
        guard isReadyToGenerate else { return }
        self.isGenerating = true
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            #if canImport(UIKit)
            // Get background images from the grid
            var backgroundImages: [UIImage] = []
            for image in self.gridPhotos {
                if let img = image {
                    backgroundImages.append(img)
                }
            }
            
            if !backgroundImages.isEmpty {
                // For the preview, we only show the grid without the person mask
                // The person mask will be shown as an overlay for interaction
                self.resultImage = self.createCollageImage(
                    backgroundImages: backgroundImages,
                    personImage: nil, // Don't include the person mask in the background image
                    horizontalPadding: self.horizontalPadding,
                    gridSpacing: self.gridSpacing,
                    personOffsetX: self.personOffsetX,
                    personOffsetY: self.personOffsetY,
                    personScale: self.personScale
                )
            } else {
                self.resultImage = self.mainSubjectPhoto
            }
            #elseif canImport(AppKit)
            self.resultImage = self.mainSubjectPhoto
            #endif
            self.isGenerating = false
            self.showingResult = true
        }
    }
    
    #if canImport(UIKit)
    // Create a 3D collage with the segmented person overlaid on the original grid view
    private func createCollageImage(backgroundImages: [UIImage], personImage: UIImage?, horizontalPadding: CGFloat, gridSpacing: CGFloat, personOffsetX: CGFloat, personOffsetY: CGFloat, personScale: CGFloat) -> UIImage {
        // Use screen dimensions for the final image
        let screenWidth = UIScreen.main.bounds.width
        // Adjust height to match content exactly as requested
        let contentGridHeight = screenWidth // Grid is square
        let textHeight: CGFloat = 40 // Height for the text at the bottom
        let screenHeight = contentGridHeight + textHeight // Exact height to match content
        
        // Create a context to draw the collage
        UIGraphicsBeginImageContextWithOptions(CGSize(width: screenWidth, height: screenHeight), false, 0)
        
        // Fill background with a gradient
        let context = UIGraphicsGetCurrentContext()!
        let colors = [UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0).cgColor, UIColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 1.0).cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: screenWidth, y: screenHeight), options: [])
        
        // Make the grid larger to match the previous page layout
        let gridWidth = screenWidth * 0.9 // Make grid 90% of screen width to match previous page
        let gridViewHeight = gridWidth // Keep it square
        
        // Center the grid in the view
        let gridView = UIView(frame: CGRect(x: (screenWidth - gridWidth) / 2, 
                                           y: (screenHeight - gridViewHeight) / 2,
                                           width: gridWidth, height: gridViewHeight))
        gridView.backgroundColor = UIColor.clear
        
        // Add an elegant dark gradient background for the entire result view
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        
        // Create a gradient layer with elegant dark colors
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = backgroundView.bounds
        gradientLayer.colors = [
            UIColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1.0).cgColor,  // Dark navy blue
            UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0).cgColor   // Slightly lighter navy blue
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        // Render the gradient to the context
        UIGraphicsBeginImageContextWithOptions(backgroundView.bounds.size, false, 0)
        if let gradientContext = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: gradientContext)
            let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // Draw the gradient image to the main context
            gradientImage?.draw(in: backgroundView.bounds)
        }
        
        // Calculate grid dimensions - WITH spacing between cells
        let totalSpacing = gridSpacing * 2 // Two spacings horizontally and vertically
        let cellSize = (gridWidth - totalSpacing) / 3 // Calculate size of each cell content
        
        // Add all grid images to the view
        for i in 0..<min(backgroundImages.count, 9) {
            let row = CGFloat(i / 3)
            let col = CGFloat(i % 3)
            
            // Position relative to the grid view's origin - with spacing between cells
            let x = col * (cellSize + gridSpacing)
            let y = row * (cellSize + gridSpacing)
            
            let imageView = UIImageView(frame: CGRect(x: x, y: y, width: cellSize, height: cellSize))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true // Ensure image is clipped to the frame
            imageView.image = backgroundImages[i % backgroundImages.count]
            
            // No text overlay on each cell as requested
            
            // No text labels as requested by the user
            
            gridView.addSubview(imageView)
        }
        
        // Render the grid view to an image
        let renderer = UIGraphicsImageRenderer(bounds: gridView.bounds)
        let gridImage = renderer.image { _ in
            gridView.drawHierarchy(in: gridView.bounds, afterScreenUpdates: true)
        }
        
        // Draw the grid image in the context - centered with margins
        let gridDrawRect = CGRect(x: (screenWidth - gridWidth) / 2, 
                                 y: (screenHeight - gridViewHeight) / 2,
                                 width: gridWidth, height: gridViewHeight)
        gridImage.draw(in: gridDrawRect)
        
        // Calculate the position for the segmented person
        // Size the person to occupy approximately 4 cells in the top right
        let personWidth = cellSize * 2.0 * personScale  // Width of 2 cells
        let personHeight = cellSize * 2.0 * personScale // Height of 2 cells
        
        // Position the person based on adjusted grid layout and person offset
        let personRect = CGRect(
            x: gridDrawRect.minX + gridDrawRect.width / 2 + personOffsetX - personWidth / 2,
            y: gridDrawRect.minY + gridDrawRect.height / 2 + personOffsetY - personHeight / 2,
            width: personWidth, height: personHeight
        )

        // Draw the person image (segmented mask) if present
        if let personImage = personImage {
            // Main person image
            personImage.draw(in: personRect, blendMode: .normal, alpha: 1.0)

            // First draw a subtle outer glow/shadow
            context.saveGState()
            context.setShadow(offset: CGSize.zero, blur: 12, color: UIColor.white.withAlphaComponent(0.3).cgColor)
            personImage.draw(in: personRect, blendMode: .normal, alpha: 1.0)
            context.restoreGState()

            // Then draw a sharper shadow for depth
            context.saveGState()
            context.setShadow(offset: CGSize(width: 2, height: 2), blur: 6, color: UIColor.black.withAlphaComponent(0.5).cgColor)
            personImage.draw(in: personRect, blendMode: .normal, alpha: 1.0)
            context.restoreGState()
        }

        // No text at the bottom as requested
        
        // Get the final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    #endif
    
    func resetView() {
        showingResult = false
        resultImage = nil
    }
    
    func saveToAlbum() {
        #if canImport(UIKit)
        // Generate the final image with the person mask blended onto the background
        var backgroundImages: [UIImage] = []
        for image in self.gridPhotos {
            if let img = image {
                backgroundImages.append(img)
            }
        }
        
        if !backgroundImages.isEmpty && self.segmentedPersonImage != nil {
            // Create the final image WITH the person mask
            let finalImage = self.createCollageImage(
                backgroundImages: backgroundImages,
                personImage: self.segmentedPersonImage, // Include the person mask in the final image
                horizontalPadding: self.horizontalPadding,
                gridSpacing: self.gridSpacing,
                personOffsetX: self.personOffsetX,
                personOffsetY: self.personOffsetY,
                personScale: self.personScale
            )
            
            // Save the final image to the photo album
            UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
        } else if let image = self.resultImage {
            // Fallback to saving the current result image if no person mask is available
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        #endif
    }
    
    func segmentPerson() async {
        guard let mainSubjectPhoto = mainSubjectPhoto else {
            return
        }
        
        // Update UI state to show we're processing
        DispatchQueue.main.async {
            self.segmentationState = .loading
            self.isProcessingSegmentation = true
            self.segmentationError = nil
        }
        
        do {
            // Call the segmentation service
            let segmentedImage = try await segmentationService.segmentPerson(from: mainSubjectPhoto)
            
            // Update UI with the result
            DispatchQueue.main.async {
                self.segmentedPersonImage = segmentedImage
                self.segmentationState = .success
                self.isProcessingSegmentation = false
            }
        } catch {
            // Handle all segmentation errors
            DispatchQueue.main.async {
                self.segmentationState = .failure
                self.isProcessingSegmentation = false
                
                // Set error message based on error description
                let errorDescription = error.localizedDescription
                if !errorDescription.isEmpty {
                    self.segmentationError = "处理失败: \(errorDescription)"
                } else {
                    self.segmentationError = "未知错误，请重试"
                }
                
                // Log error for debugging
                print("Segmentation error: \(error)")
            }
        }
    }
    
    // 错误处理已移至通用catch块
}

// SegmentationState已在Services/SegmentationState.swift中定义

// Overlay for the person mask that tracks drag start and follows the finger
struct PersonMaskOverlay: View {
    let personMask: UIImage
    @ObservedObject var viewModel: ThreeDGridViewModel
    @State private var dragStartOffset: CGSize = .zero

var body: some View {
    Image(uiImage: personMask)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: UIScreen.main.bounds.width - 2 * 20)
        .scaleEffect(viewModel.personScale)
        .offset(x: viewModel.personOffsetX, y: viewModel.personOffsetY)
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    viewModel.personOffsetX = dragStartOffset.width + value.translation.width
                    viewModel.personOffsetY = dragStartOffset.height + value.translation.height
                }
                .onEnded { value in
                    dragStartOffset = CGSize(width: viewModel.personOffsetX, height: viewModel.personOffsetY)
                }
                .onChanged { value in
                    if value.startLocation == value.location {
                        dragStartOffset = CGSize(width: viewModel.personOffsetX, height: viewModel.personOffsetY)
                    }
                }
        )
        .gesture(
            MagnificationGesture(minimumScaleDelta: 0.01)
                .onChanged { value in
                    let delta = value / viewModel.lastScaleValue
                    viewModel.lastScaleValue = value
                    viewModel.personScale = min(max(viewModel.personScale * delta, 0.5), 3.0)
                }
                .onEnded { _ in
                    viewModel.lastScaleValue = 1.0
                }
        )
}
}

enum ActiveSheet: Identifiable {
    case gridPicker
    case mainSubjectPicker
    case mainSubjectPhotoPicker
    var id: Int { hashValue }
}

struct ThreeDGridView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ThreeDGridViewModel()
    @State private var activeSheet: ActiveSheet?
    @State private var draggedItem: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var previewImage: PlatformImage? = nil
    @State private var previewIndex: Int? = nil
    @State private var selectedGridIndex: Int? = nil
    
    // 固定的图片容器尺寸和边距
    #if canImport(UIKit)
    private let horizontalPadding: CGFloat = 16 // Reduced horizontal padding
    private let gridSpacing: CGFloat = 4
    private let imageWidth: CGFloat = UIScreen.main.bounds.width * 0.38 // Smaller grid images
    private let imageHeight: CGFloat = UIScreen.main.bounds.width * 0.38 / 0.7
    private let personImageWidth: CGFloat = UIScreen.main.bounds.width * 0.36 // Smaller person images
    private let personImageHeight: CGFloat = UIScreen.main.bounds.width * 0.36 / 0.7
    private let verticalSpacing: CGFloat = 20 // Reduced vertical spacing
    #elseif canImport(AppKit)
    private let horizontalPadding: CGFloat = 25
    private let gridSpacing: CGFloat = 4
    private let imageWidth: CGFloat = 140
    private let imageHeight: CGFloat = 140 / 0.7
    private let personImageWidth: CGFloat = 130
    private let personImageHeight: CGFloat = 130 / 0.7
    private let verticalSpacing: CGFloat = 20
    #endif
    
    private var navBarHeight: CGFloat { 60 } // 你自定义的导航栏高度
    private var buttonHeight: CGFloat { 70 } // 按钮高度+间距
    
    init(segmentationService: PersonSegmentationServiceProtocol = PersonSegmentationService()) {
        _viewModel = StateObject(wrappedValue: ThreeDGridViewModel(segmentationService: segmentationService))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Custom navigation bar
                HStack {
                    // Back button
                    Button(action: {
                        if viewModel.showingResult {
                            viewModel.resetView()
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("返回")
                                .font(.system(size: 16, weight: .regular))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                    }
                    
                    Spacer()
                    
                    // Title
                    Text("立体九宫格")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Text("")
                        .frame(width: 70)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                if viewModel.showingResult, let resultImage = viewModel.resultImage {
                    // 结果卡片区域，固定显示，不滚动
                    VStack(spacing: 15) {
                        #if canImport(UIKit)
                        ZStack {
                            Image(uiImage: resultImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: UIScreen.main.bounds.width - 2 * 20)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                                .padding(.top, 16)
                            if let personMask = viewModel.segmentedPersonImage {
                                PersonMaskOverlay(personMask: personMask, viewModel: viewModel)
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        #elseif canImport(AppKit)
                        Image(nsImage: resultImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        #endif
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, horizontalPadding)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.08, green: 0.08, blue: 0.15),
                                Color(red: 0.15, green: 0.15, blue: 0.25)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                    Spacer(minLength: 0)
                } else {
                    // 其余内容可滚动，ScrollView高度精确限定
                    ScrollView {
                        VStack(spacing: 20) {
                            // 3x3 Grid with improved drag-to-reorder functionality
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 3), spacing: gridSpacing) {
                                ForEach(0..<9, id: \.self) { index in
                                    GridCellView(
                                        image: viewModel.gridPhotos[index],
                                        index: index,
                                        isDragging: draggedItem == index,
                                        dragOffset: dragOffset,
                                        onTap: {
                                            if let img = viewModel.gridPhotos[index] {
                                                previewImage = img
                                                previewIndex = index
                                            } else {
                                                let emptyCount = viewModel.gridPhotos.filter { $0 == nil }.count
                                                if emptyCount > 1 && selectedGridIndex == nil {
                                                    // 有多个空位，允许多选
                                                    activeSheet = .gridPicker
                                                } else {
                                                    // 只允许单选，插入到指定位置
                                                    selectedGridIndex = index
                                                    activeSheet = .mainSubjectPicker
                                                }
                                            }
                                        },
                                        onLongPress: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                draggedItem = index
                                                isDragging = true
                                            }
                                        },
                                        onDragEnd: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                draggedItem = nil
                                                dragOffset = .zero
                                                isDragging = false
                                            }
                                        },
                                        onDragChanged: { value in
                                            dragOffset = value
                                            let targetIndex = calculateTargetIndex(from: index, with: value)
                                            if targetIndex != index {
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                                    viewModel.gridPhotos.swapAt(index, targetIndex)
                                                    draggedItem = targetIndex
                                                    dragOffset = .zero
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, verticalSpacing)
                            
                            // Side-by-side layout for main subject photo and result preview
                            HStack(spacing: 10) {
                                // Left side: Main subject photo selection (portrait orientation)
                                ZStack {
                                    // 固定尺寸的占位符 - consistent container size
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: personImageWidth, height: personImageHeight)
                                        .cornerRadius(12)
                                    
                                    if let image = viewModel.mainSubjectPhoto {
                                        #if canImport(UIKit)
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: personImageWidth, height: personImageHeight)
                                            .clipped() // 确保图片严格裁剪在占位符边界内
                                            .cornerRadius(12)
                                        #elseif canImport(AppKit)
                                        Image(nsImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: personImageWidth, height: personImageHeight)
                                            .clipped() // 确保图片严格裁剪在占位符边界内
                                            .cornerRadius(12)
                                        #endif
                                    } else {
                                        VStack(spacing: 10) {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                            Text("点击选择主体照片")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .onTapGesture {
                                    activeSheet = .mainSubjectPhotoPicker
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Middle: Improved arrow with better visibility
                                ZStack {
                                    // White background circle for better contrast
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                                    
                                    // Colored circle with smaller size
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 32, height: 32)
                                    
                                    if viewModel.isProcessingSegmentation {
                                        // Show processing indicator
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.0)
                                    } else {
                                        // White arrow for better visibility
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(width: 42)
                                
                                // Right side: Result preview area (portrait orientation)
                                ZStack {
                                    // 固定尺寸的占位符 - consistent container size
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: personImageWidth, height: personImageHeight)
                                        .cornerRadius(12)
                                    
                                    if viewModel.isProcessingSegmentation {
                                        // Show loading state
                                        VStack(spacing: 10) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                            Text("正在处理...")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                    } else if let resultImage = viewModel.segmentedPersonImage {
                                        // Show segmented person image when ready
                                        #if canImport(UIKit)
                                        Image(uiImage: resultImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: personImageWidth, height: personImageHeight)
                                            .clipped() // 确保图片严格裁剪在占位符边界内
                                            .cornerRadius(12)
                                            .overlay(
                                                Text("人物分割完成")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.black.opacity(0.6))
                                                    .cornerRadius(8)
                                                    .padding(8),
                                                alignment: .bottom
                                            )
                                        #elseif canImport(AppKit)
                                        Image(nsImage: resultImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: personImageWidth, height: personImageHeight)
                                            .clipped() // 确保图片严格裁剪在占位符边界内
                                            .cornerRadius(12)
                                            .overlay(
                                                Text("人物分割完成")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.black.opacity(0.6))
                                                    .cornerRadius(8)
                                                    .padding(8),
                                                alignment: .bottom
                                            )
                                        #endif
                                    } else if let errorMessage = viewModel.segmentationError {
                                        // Show error state
                                        VStack(spacing: 10) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                            Text(errorMessage)
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .frame(maxWidth: .infinity)
                                                .padding(.horizontal, 8)
                                        }
                                    } else {
                                        // Initial empty state
                                        VStack(spacing: 10) {
                                            Image(systemName: "photo.on.rectangle")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                            Text("生成结果图片")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, horizontalPadding)
                            
                            // Spacer to push content up against the button
                            Spacer()
                                .frame(minHeight: 50)
                        }
                    }
                    .padding(.bottom, 20) // 只留少量padding
                    .frame(minHeight: geometry.size.height - navBarHeight - buttonHeight - geometry.safeAreaInsets.bottom)
                }
                
                // 底部按钮，始终固定
                Button(action: {
                    if viewModel.showingResult {
                        viewModel.saveToAlbum()
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    } else {
                        viewModel.generateThreeDGrid()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(viewModel.isReadyToGenerate ? Color.blue : Color.gray)
                            .frame(height: 50)
                        if viewModel.isGenerating {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("生成中...")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text(viewModel.showingResult ? "保存到相册" : "生成立体九宫格")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
                .disabled((!viewModel.isReadyToGenerate && !viewModel.showingResult) || viewModel.isGenerating)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 10)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            #if canImport(UIKit)
            // Set status bar style to light
            UIApplication.shared.statusBarStyle = .lightContent
            #endif
            
            // Pass layout values to view model
            viewModel.horizontalPadding = self.horizontalPadding
            viewModel.gridSpacing = self.gridSpacing
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .gridPicker:
                MultiplePhotoPicker(gridPhotos: $viewModel.gridPhotos)
            case .mainSubjectPicker:
                // 九宫格单图补图
                PhotoPicker(selectedImage: Binding<PlatformImage?>(
                    get: { nil },
                    set: { newImage in
                        if let idx = selectedGridIndex, let img = newImage as? UIImage {
                            viewModel.gridPhotos[idx] = img.croppedToSquare() ?? img
                        } else if let idx = selectedGridIndex, let img = newImage {
                            viewModel.gridPhotos[idx] = img
                        }
                        selectedGridIndex = nil
                    }
                ))
            case .mainSubjectPhotoPicker:
                // 主体照片选择，直接绑定viewModel.mainSubjectPhoto
                PhotoPicker(selectedImage: $viewModel.mainSubjectPhoto)
            }
        }
        .fullScreenCover(isPresented: Binding<Bool>(
            get: { previewImage != nil },
            set: { if !$0 { previewImage = nil; previewIndex = nil } }
        )) {
            if let img = previewImage, let idx = previewIndex {
                ZStack(alignment: .topTrailing) {
                    Color.black.edgesIgnoringSafeArea(.all)
                    VStack {
                        Spacer()
                        #if canImport(UIKit)
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #elseif canImport(AppKit)
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #endif
                        Spacer()
                    }
                    // 右上角删除按钮
                    Button(action: {
                        if let idx = previewIndex {
                            viewModel.gridPhotos[idx] = nil
                        }
                        previewImage = nil
                        previewIndex = nil
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
                    }
                    .padding(.top, 48)
                    .padding(.trailing, 24)
                    // 右上角关闭按钮
                    Button(action: {
                        previewImage = nil
                        previewIndex = nil
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.top, 52)
                    .padding(.trailing, 80)
                }
            }
        }
    }
    
    private func calculateTargetIndex(from sourceIndex: Int, with offset: CGSize) -> Int {
        let cellSize = (UIScreen.main.bounds.width - 2 * horizontalPadding - 2 * gridSpacing) / 3
        let row = sourceIndex / 3
        let col = sourceIndex % 3
        
        let targetRow = row + Int(round(offset.height / cellSize))
        let targetCol = col + Int(round(offset.width / cellSize))
        
        let newRow = max(0, min(2, targetRow))
        let newCol = max(0, min(2, targetCol))
        
        return newRow * 3 + newCol
    }
}

struct GridCellView: View {
    let image: PlatformImage?
    let index: Int
    let isDragging: Bool
    let dragOffset: CGSize
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDragEnd: () -> Void
    let onDragChanged: (CGSize) -> Void

    @GestureState private var isDetectingLongPress = false
    @State private var dragEnabled = false

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill) // 保证正方形裁剪
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "plus")
                            .foregroundColor(.gray)
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .offset(isDragging ? dragOffset : .zero)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .shadow(radius: isDragging ? 10 : 0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onTap()
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.3)
                .updating($isDetectingLongPress) { currentState, gestureState, _ in
                    gestureState = currentState
                }
                .onEnded { _ in
                    onLongPress()
                    dragEnabled = true
                }
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if isDragging {
                        onDragChanged(value.translation)
                    }
                }
                .onEnded { _ in
                    if isDragging {
                        onDragEnd()
                    }
                }
        )
    }
}

// Cross-platform photo picker for single image selection
#if canImport(UIKit)
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: PlatformImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

// Photo picker that supports selecting multiple images at once
struct MultiplePhotoPicker: UIViewControllerRepresentable {
    @Binding var gridPhotos: [PlatformImage?]
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 9 // Allow selecting up to 9 images at once
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiplePhotoPicker
        
        init(_ parent: MultiplePhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard !results.isEmpty else { return }
            
            // Create a dispatch group to wait for all images to load
            let group = DispatchGroup()
            var loadedImages: [UIImage] = []
            
            // Load each selected image
            for result in results {
                let itemProvider = result.itemProvider
                guard itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                
                group.enter()
                itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let image = image as? UIImage {
                        // 新增：裁剪为正方形
                        loadedImages.append(image.croppedToSquare() ?? image)
                    }
                    group.leave()
                }
            }
            
            // When all images are loaded, update the grid
            group.notify(queue: .main) {
                // Fill the grid photos array with the loaded images
                var updatedGridPhotos = self.parent.gridPhotos
                for (index, image) in loadedImages.enumerated() {
                    if index < updatedGridPhotos.count {
                        updatedGridPhotos[index] = image
                    }
                }
                self.parent.gridPhotos = updatedGridPhotos
            }
        }
    }
}
#endif

// UIImage 居中裁剪为正方形扩展
extension UIImage {
    func croppedToSquare() -> UIImage? {
        let originalWidth  = self.size.width
        let originalHeight = self.size.height
        let edge = min(originalWidth, originalHeight)
        let posX = (originalWidth  - edge) / 2.0
        let posY = (originalHeight - edge) / 2.0
        let cropSquare = CGRect(x: posX, y: posY, width: edge, height: edge)
        if let cgImage = self.cgImage?.cropping(to: cropSquare) {
            return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
        }
        return nil
    }
}

// 这是修复版本的ThreeDGridView.swift
// 请将此文件内容替换到原文件中

import SwiftUI

#if canImport(UIKit)
import UIKit
import PhotosUI
#elseif canImport(AppKit)
import AppKit
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
    
    func generateThreeDGrid() {
        guard isReadyToGenerate else { return }
        
        // Set generating state
        self.isGenerating = true
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Create a mock result image (in a real app, this would be the actual generated image)
            #if canImport(UIKit)
            self.resultImage = self.mainSubjectPhoto
            #elseif canImport(AppKit)
            self.resultImage = self.mainSubjectPhoto
            #endif
            
            self.isGenerating = false
            self.showingResult = true
        }
    }
    
    func resetView() {
        showingResult = false
        resultImage = nil
    }
    
    func saveToAlbum() {
        // Simulate saving to album
        #if canImport(UIKit)
        if let image = self.resultImage {
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

struct ThreeDGridView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ThreeDGridViewModel()
    @State private var isShowingGridPicker = false
    @State private var isShowingMainSubjectPicker = false
    
    // 固定的图片容器尺寸和边距
    #if canImport(UIKit)
    private let horizontalPadding: CGFloat = 25 // Increased horizontal padding
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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
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
                    
                    ZStack(alignment: .bottom) {
                        ScrollView {
                            VStack(spacing: 20) {
                                if viewModel.showingResult, let resultImage = viewModel.resultImage {
                                    // Display result
                                    VStack(spacing: 15) {
                                        #if canImport(UIKit)
                                        Image(uiImage: resultImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(15)
                                            .shadow(color: Color.purple.opacity(0.5), radius: 10, x: 0, y: 5)
                                        #elseif canImport(AppKit)
                                        Image(nsImage: resultImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(15)
                                            .shadow(color: Color.purple.opacity(0.5), radius: 10, x: 0, y: 5)
                                        #endif
                                        
                                        Button(action: {
                                            viewModel.saveToAlbum()
                                        }) {
                                            HStack {
                                                Image(systemName: "square.and.arrow.down")
                                                Text("保存到相册")
                                            }
                                            .foregroundColor(.white)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, horizontalPadding)
                                            .background(Color.blue)
                                            .cornerRadius(25)
                                        }
                                    }
                                    .padding()
                                } else {
                                    // 3x3 Grid
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 3), spacing: gridSpacing) {
                                        ForEach(0..<9, id: \.self) { index in
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .aspectRatio(1, contentMode: .fit)
                                                    .cornerRadius(8)
                                                
                                                if let image = viewModel.gridPhotos[index] {
                                                    #if canImport(UIKit)
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                                        .cornerRadius(8)
                                                    #elseif canImport(AppKit)
                                                    Image(nsImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                                        .cornerRadius(8)
                                                    #endif
                                                } else {
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 30))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .onTapGesture {
                                                viewModel.currentGridIndex = index
                                                isShowingGridPicker = true
                                            }
                                        }
                                    }
                                    .padding(.horizontal, horizontalPadding)
                                    .padding(.bottom, verticalSpacing) // Reduced vertical spacing between grid and person images
                                    
                                    // Side-by-side layout for main subject photo and result preview
                                    HStack(spacing: 10) {
                                        // Left side: Main subject photo selection (portrait orientation)
                                        ZStack {
                                            // 固定尺寸的占位符
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: imageWidth, height: imageHeight)
                                                .clipped()
                                                .cornerRadius(12)
                                            
                                            if let image = viewModel.mainSubjectPhoto {
                                                #if canImport(UIKit)
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: personImageWidth, height: personImageHeight)
                                                    .clipped()
                                                    .cornerRadius(12)
                                                #elseif canImport(AppKit)
                                                Image(nsImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: personImageWidth, height: personImageHeight)
                                                    .clipped()
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
                                            isShowingMainSubjectPicker = true
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
                                            // 固定尺寸的占位符
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: imageWidth, height: imageHeight)
                                                .clipped()
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
                                                    .clipped()
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
                                                    .clipped()
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
                            .padding(.bottom, 70) // Space for the button
                        }
                        
                        // Generate button at the bottom
                        Button(action: {
                            viewModel.generateThreeDGrid()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(viewModel.isReadyToGenerate ? Color.blue : Color.gray)
                                    .frame(height: 50)
                                
                                if viewModel.isGenerating {
                                    // Show loading indicator
                                    HStack(spacing: 10) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text("生成中...")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    Text("生成立体九宫格")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                        }
                        .disabled(!viewModel.isReadyToGenerate || viewModel.isGenerating)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                #if canImport(UIKit)
                // Set status bar style to light
                UIApplication.shared.statusBarStyle = .lightContent
                #endif
            }
        }
        .sheet(isPresented: $isShowingGridPicker) {
            PhotoPicker(selectedImage: $viewModel.gridPhotos[viewModel.currentGridIndex])
        }
        .sheet(isPresented: $isShowingMainSubjectPicker) {
            PhotoPicker(selectedImage: $viewModel.mainSubjectPhoto)
        }
    }
    

}

// Cross-platform photo picker
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
#endif

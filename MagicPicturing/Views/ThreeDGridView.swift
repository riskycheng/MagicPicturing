//
//  ThreeDGridView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/16.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
import PhotosUI
#elseif canImport(AppKit)
import AppKit
#endif

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
            if mainSubjectPhoto != nil && oldValue == nil {
                // Automatically start person segmentation when a main subject photo is selected
                processPersonSegmentation()
            }
        }
    }
    @Published var resultImage: PlatformImage? = nil
    @Published var segmentedPersonImage: PlatformImage? = nil
    @Published var isGenerating = false
    @Published var isProcessingSegmentation = false
    @Published var showingResult = false
    @Published var showSaveSuccess = false
    @Published var currentGridIndex: Int = 0
    @Published var segmentationError: String? = nil
    
    // Dependencies
    private let segmentationService: PersonSegmentationServiceProtocol
    
    init(segmentationService: PersonSegmentationServiceProtocol = PersonSegmentationService()) {
        self.segmentationService = segmentationService
    }
    
    var isReadyToGenerate: Bool {
        let hasAllGridPhotos = !gridPhotos.contains(where: { $0 == nil })
        return hasAllGridPhotos && segmentedPersonImage != nil
    }
    
    // Process person segmentation when main subject photo is selected
    func processPersonSegmentation() {
        guard let mainPhoto = mainSubjectPhoto else { return }
        
        print("[ThreeDGridViewModel] Starting person segmentation for image: \(mainPhoto.size.width) x \(mainPhoto.size.height)")
        isProcessingSegmentation = true
        segmentationError = nil
        
        Task {
            do {
                print("[ThreeDGridViewModel] Calling segmentation service")
                // Use the actual person segmentation service
                let segmentedImage = try await segmentationService.segmentPerson(from: mainPhoto)
                print("[ThreeDGridViewModel] Segmentation completed successfully")
                
                await MainActor.run {
                    print("[ThreeDGridViewModel] Updating UI with segmented image")
                    self.segmentedPersonImage = segmentedImage
                    self.isProcessingSegmentation = false
                }
            } catch {
                print("[ThreeDGridViewModel] ERROR: Segmentation failed: \(error.localizedDescription)")
                print("[ThreeDGridViewModel] Error details: \(String(describing: error))")
                
                // Check specifically for FileProvider error
                let errorDescription = error.localizedDescription
                if errorDescription.contains("FileProvider") || errorDescription.contains("bookmark") {
                    print("[ThreeDGridViewModel] Detected FileProvider error, using alternative approach")
                    // Try a simpler approach without Vision framework
                    await handleFileProviderError(mainPhoto)
                } else {
                    await MainActor.run {
                        self.segmentationError = error.localizedDescription
                        self.isProcessingSegmentation = false
                        
                        // Fallback to using the original image if segmentation fails
                        print("[ThreeDGridViewModel] Falling back to original image")
                        self.segmentedPersonImage = mainPhoto
                    }
                }
            }
        }
    }
    
    // Handle FileProvider error with a fallback approach
    private func handleFileProviderError(_ image: PlatformImage) async {
        print("[ThreeDGridViewModel] Using fallback segmentation method")
        
        // Simple fallback: just use the original image for now
        // In a real implementation, you could implement a simpler segmentation approach here
        // that doesn't rely on the Vision framework
        
        await MainActor.run {
            self.segmentationError = "使用备用方法处理图像"
            self.segmentedPersonImage = image
            self.isProcessingSegmentation = false
            print("[ThreeDGridViewModel] Fallback segmentation completed")
        }
    }
    
    func generateThreeDGrid() {
        self.isGenerating = true
        
        // Simulate processing time for blending segmented person with 9-grid
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self = self else { return }
            // In a real app, this would combine the segmented person with the 9-grid photos
            // For now, we'll just use the segmented person image as the result
            self.resultImage = self.segmentedPersonImage
            self.isGenerating = false
            self.showingResult = true
        }
    }
    
    func saveToAlbum() {
        // Simulate saving to album
        #if canImport(UIKit)
        if let image = self.resultImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            self.showSaveSuccess = true
        }
        #endif
    }
}

struct ThreeDGridView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ThreeDGridViewModel()
    @State private var isShowingGridPicker = false
    @State private var isShowingMainSubjectPicker = false
    
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
                            dismiss()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("返回")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Title
                        Text("立体九宫格")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Save button when showing result
                        Group {
                            if viewModel.showingResult {
                                Button(action: {
                                    viewModel.saveToAlbum()
                                }) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                            } else {
                                // Empty view for balance
                                Text("")
                                    .frame(width: 50)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10) 
                    .padding(.bottom, 10)
                    .background(Color.black)
                    
                    // Content area
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
                                            .cornerRadius(12)
                                            .padding()
                                        #elseif canImport(AppKit)
                                        Image(nsImage: resultImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(12)
                                            .padding()
                                        #endif
                                        
                                        // Save to album button
                                        Button(action: {
                                            viewModel.saveToAlbum()
                                        }) {
                                            HStack {
                                                Image(systemName: "photo")
                                                Text("保存到相册")
                                            }
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(height: 50)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue)
                                            .cornerRadius(25)
                                        }
                                        .padding(.horizontal, 40)
                                    }
                                } else {
                                    // 3x3 Grid
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
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
                                                        .frame(width: PlatformConstants.screenWidth / 3.5, height: PlatformConstants.screenWidth / 3.5)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    #elseif canImport(AppKit)
                                                    Image(nsImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: PlatformConstants.screenWidth / 3.5, height: PlatformConstants.screenWidth / 3.5)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                                    .padding(.horizontal)
                                    .padding(.bottom, 30) // Add more space between grid and result section
                                    
                                    // Side-by-side layout for main subject photo and result preview
                                    HStack(spacing: 5) {
                                        // Left side: Main subject photo selection (portrait orientation)
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .aspectRatio(0.7, contentMode: .fit) // Portrait aspect ratio (taller than wide)
                                                .cornerRadius(12)
                                            
                                            if let image = viewModel.mainSubjectPhoto {
                                                #if canImport(UIKit)
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .cornerRadius(12)
                                                #elseif canImport(AppKit)
                                                Image(nsImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
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
                                        
                                        // Middle: Animated arrow with processing indicator
                                        ZStack {
                                            // Outer glow
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            .frame(width: 48, height: 48)
                                            .blur(radius: 8)
                                            .opacity(0.6)
                                            
                                            // Glass-like background with colorful border
                                            Circle()
                                                .fill(Color.black.opacity(0.3))
                                                .frame(width: 42, height: 42)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: [Color.blue, Color.purple, Color.pink]),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: 2.5
                                                        )
                                                )
                                                .shadow(color: Color.purple.opacity(0.4), radius: 5, x: 0, y: 2)
                                                .modifier(RotationAnimationModifier(isAnimating: viewModel.isProcessingSegmentation))
                                            
                                            if viewModel.isProcessingSegmentation {
                                                // Show processing indicator
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.7)
                                            } else {
                                                // Thicker, colorful arrow
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                                .mask(
                                                    Image(systemName: "arrow.right")
                                                        .font(.system(size: 18, weight: .bold))
                                                )
                                                .frame(width: 22, height: 22)
                                            }
                                        }
                                        .frame(width: 42)
                                        
                                        // Right side: Result preview area (portrait orientation)
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .aspectRatio(0.7, contentMode: .fit) // Portrait aspect ratio (taller than wide)
                                                .cornerRadius(12)
                                            
                                            if let resultImage = viewModel.resultImage {
                                                // Final blended result after clicking "生成立体九宫格"
                                                #if canImport(UIKit)
                                                Image(uiImage: resultImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .cornerRadius(12)
                                                #elseif canImport(AppKit)
                                                Image(nsImage: resultImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .cornerRadius(12)
                                                #endif
                                            } else if let segmentedImage = viewModel.segmentedPersonImage {
                                                // Show segmented person mask when ready
                                                #if canImport(UIKit)
                                                Image(uiImage: segmentedImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
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
                                                Image(nsImage: segmentedImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
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
                                            } else if viewModel.isProcessingSegmentation {
                                                // Show processing state
                                                VStack(spacing: 10) {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle())
                                                        .scaleEffect(1.2)
                                                    Text("处理中...")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.gray)
                                                }
                                            } else if let errorMessage = viewModel.segmentationError {
                                                // Show error state
                                                VStack(spacing: 10) {
                                                    Image(systemName: "exclamationmark.triangle")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.orange)
                                                    Text("分割失败")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.orange)
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
                                    .padding(.horizontal)
                                    
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
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("生成立体九宫格")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(!viewModel.isReadyToGenerate || viewModel.isGenerating)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                #if canImport(UIKit)
                UITabBar.appearance().isHidden = true
                #endif
            }
            .onDisappear {
                #if canImport(UIKit)
                UITabBar.appearance().isHidden = false
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
    @Environment(\.presentationMode) var presentationMode
    
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
#elseif canImport(AppKit)
struct PhotoPicker: View {
    @Binding var selectedImage: PlatformImage?
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingFileChooser = false
    
    var body: some View {
        VStack {
            Text("Select an image")
                .font(.headline)
                .padding()
            
            Button("Choose from file") {
                isShowingFileChooser = true
            }
            .padding()
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .frame(width: 300, height: 200)
        .onAppear {
            // Initialize file chooser when needed
            if isShowingFileChooser {
                chooseFile()
            }
        }
        .onChange(of: isShowingFileChooser) { newValue in
            if newValue {
                chooseFile()
            }
        }
    }
    
    func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let image = NSImage(contentsOf: url) {
                    selectedImage = image
                    presentationMode.wrappedValue.dismiss()
                }
            }
            isShowingFileChooser = false
        }
    }
}
#endif

struct ThreeDGridView_Previews: PreviewProvider {
    static var previews: some View {
        ThreeDGridView()
    }
}

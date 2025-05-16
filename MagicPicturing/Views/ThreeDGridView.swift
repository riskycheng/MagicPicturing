//
//  ThreeDGridView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/16.
//

import SwiftUI

#if canImport(UIKit)
import PhotosUI
#elseif canImport(AppKit)
import AppKit
#endif

struct ThreeDGridView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var gridPhotos: [PlatformImage?] = Array(repeating: nil, count: 9)
    @State private var mainSubjectPhoto: PlatformImage? = nil
    @State private var isShowingGridPicker = false
    @State private var isShowingMainSubjectPicker = false
    @State private var currentGridIndex: Int = 0
    @State private var resultImage: PlatformImage? = nil
    @State private var isGenerating = false
    @State private var showingResult = false
    @State private var showSaveSuccess = false
    
    // Helper computed property to determine if ready to generate
    private var isReadyToGenerate: Bool {
        let hasAllGridPhotos = !gridPhotos.contains(where: { $0 == nil })
        return hasAllGridPhotos && mainSubjectPhoto != nil
    }
    
    var body: some View {
        // Use NavigationView with navigationBarHidden to avoid duplicate back buttons
        NavigationView {
            ZStack {
                // Background
                Color("D1D7AB")
                    .edgesIgnoringSafeArea(.all)
                
                // Make the content scrollable
                ScrollView {
                    VStack(spacing: 20) {
                        // Only show title when not showing result
                        if !showingResult {
                            Text("立体九宫格")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.top, 10)
                        }
                        
                        if showingResult, let resultImage = resultImage {
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
                                    saveToAlbum()
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
                                        
                                        if let image = gridPhotos[index] {
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
                                        currentGridIndex = index
                                        isShowingGridPicker = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        
                            // Main subject photo selection
                            VStack(spacing: 12) {
                                
                                ZStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 150)
                                        .cornerRadius(12)
                                    
                                    if let image = mainSubjectPhoto {
                                        #if canImport(UIKit)
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 150)
                                            .cornerRadius(12)
                                        #elseif canImport(AppKit)
                                        Image(nsImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 150)
                                            .cornerRadius(12)
                                        #endif
                                    } else {
                                        VStack {
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
                                .padding(.horizontal)
                            }
                            
                            // Generate button - moved inside the ScrollView for accessibility
                            Button(action: {
                                generateThreeDGrid()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(isReadyToGenerate ? Color.blue : Color.gray)
                                        .frame(height: 50)
                                    
                                    if isGenerating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("生成立体九宫格")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .disabled(!isReadyToGenerate || isGenerating)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 30) // Add more padding for better spacing
                        }
                    }
                    .padding(.bottom, 20) // Add padding at the bottom for better scrolling
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true) // Hide the default navigation bar
            .navigationBarBackButtonHidden(true) // Hide the default back button
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // Add save button to toolbar when showing result
                ToolbarItem(placement: .navigationBarTrailing) {
                    if showingResult {
                        Button(action: {
                            saveToAlbum()
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
            // Hide the tab bar
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
            // Show save success alert
            .alert(isPresented: $showSaveSuccess) {
                Alert(
                    title: Text("保存成功"),
                    message: Text("图片已保存到相册"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $isShowingGridPicker) {
            PhotoPicker(selectedImage: $gridPhotos[currentGridIndex])
        }
        .sheet(isPresented: $isShowingMainSubjectPicker) {
            PhotoPicker(selectedImage: $mainSubjectPhoto)
        }
    }
    
    // Function to generate the 3D grid effect
    func generateThreeDGrid() {
        isGenerating = true
        
        // Simulate processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // In a real app, this would combine the photos and apply the 3D effect
            // For now, we'll just use the main subject photo as the result
            self.resultImage = self.mainSubjectPhoto
            self.isGenerating = false
            self.showingResult = true
        }
    }
    
    // Function to save the generated image to photo album
    func saveToAlbum() {
        // Simulate saving to album
        #if canImport(UIKit)
        if let image = resultImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            showSaveSuccess = true
        }
        #endif
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
    
    var body: some View {
        VStack {
            Text("Select an image")
                .font(.headline)
                .padding()
            
            Button("Choose from file") {
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
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .padding()
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .frame(width: 300, height: 200)
    }
}
#endif

struct ThreeDGridView_Previews: PreviewProvider {
    static var previews: some View {
        ThreeDGridView()
    }
}

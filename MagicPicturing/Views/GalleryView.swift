//
//  GalleryView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI
import PhotosUI

struct GalleryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = GalleryViewModel()
    @State private var selectedItems = [PhotosPickerItem]()
    
    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Photo grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(viewModel.photos) { photo in
                                GalleryItemView(photo: photo, isSelected: viewModel.isSelected(photo))
                                    .aspectRatio(1, contentMode: .fill)
                                    .onTapGesture {
                                        viewModel.toggleSelection(photo)
                                    }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    
                    // Bottom controls
                    VStack(spacing: 10) {
                        // Photo picker button
                        PhotosPicker(
                            selection: $selectedItems,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("从相册选择")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .onChange(of: selectedItems) { newItems in
                            Task {
                                await viewModel.loadPhotos(from: newItems)
                                selectedItems = []
                            }
                        }
                        
                        // Selection count and confirm button
                        HStack {
                            Text("已选择 \(viewModel.selectedPhotos.count) 张照片")
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                // Confirm selection and dismiss
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("确认")
                                    .fontWeight(.semibold)
                                    .foregroundColor(viewModel.selectedPhotos.isEmpty ? .gray : .blue)
                            }
                            .disabled(viewModel.selectedPhotos.isEmpty)
                        }
                    }
                    .padding()
                    .background(Color.black)
                }
                
                // Loading indicator
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.5))
                }
            }
            .navigationTitle("选择照片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct GalleryItemView: View {
    let photo: GalleryPhoto
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo image
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
            
            // Selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.black.opacity(0.5))
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(6)
        }
    }
}

// ViewModel for the gallery
class GalleryViewModel: ObservableObject {
    @Published var photos: [GalleryPhoto] = []
    @Published var selectedPhotos: [GalleryPhoto] = []
    @Published var isLoading: Bool = false
    
    func isSelected(_ photo: GalleryPhoto) -> Bool {
        return selectedPhotos.contains { $0.id == photo.id }
    }
    
    func toggleSelection(_ photo: GalleryPhoto) {
        if isSelected(photo) {
            selectedPhotos.removeAll { $0.id == photo.id }
        } else {
            selectedPhotos.append(photo)
        }
    }
    
    func loadPhotos(from pickerItems: [PhotosPickerItem]) async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        var newPhotos: [GalleryPhoto] = []
        
        for item in pickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                let photo = GalleryPhoto(image: uiImage)
                newPhotos.append(photo)
            }
        }
        
        DispatchQueue.main.async {
            self.photos.append(contentsOf: newPhotos)
            self.isLoading = false
        }
    }
}

// Model for gallery photos
struct GalleryPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

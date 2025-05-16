//
//  PhotoLibraryViewModel.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import Foundation
import SwiftUI
import Combine

class PhotoLibraryViewModel: ObservableObject {
    @Published var photoItems: [PhotoItem] = PhotoItem.sampleItems
    @Published var selectedCategory: PhotoCategory = .all
    @Published var currentIndex: Int = 0
    
    // Filtered photos based on the selected category
    var filteredPhotos: [PhotoItem] {
        if selectedCategory == .all {
            return photoItems
        } else {
            return photoItems.filter { $0.category == selectedCategory }
        }
    }
    
    // Current photo based on index
    var currentPhoto: PhotoItem? {
        guard !filteredPhotos.isEmpty else { return nil }
        return filteredPhotos[safe: currentIndex] ?? filteredPhotos.first
    }
    
    // Move to next photo
    func nextPhoto() {
        guard !filteredPhotos.isEmpty else { return }
        currentIndex = (currentIndex + 1) % filteredPhotos.count
    }
    
    // Move to previous photo
    func previousPhoto() {
        guard !filteredPhotos.isEmpty else { return }
        currentIndex = (currentIndex - 1 + filteredPhotos.count) % filteredPhotos.count
    }
    
    // Change category
    func changeCategory(to category: PhotoCategory) {
        selectedCategory = category
        currentIndex = 0
    }
    
    // Add new photo
    func addPhoto(title: String, imageName: String, category: PhotoCategory, symbolName: String = "photo") {
        let newPhoto = PhotoItem(title: title, date: Date(), imageName: imageName, category: category, symbolName: symbolName)
        photoItems.insert(newPhoto, at: 0)
        currentIndex = 0
    }
}

// Safe array access extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

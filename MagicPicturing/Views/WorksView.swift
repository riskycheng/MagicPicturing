//
//  WorksView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

struct WorksView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    @State private var selectedCategory: PhotoCategory = .all
    
    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("我的作品")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        // Add new photo action
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(PhotoCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Photo grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(viewModel.photoItems.filter { selectedCategory == .all || $0.category == selectedCategory }) { photo in
                            WorkItemView(photo: photo)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .padding()
                }
                
                // Tab bar
                HStack {
                    TabBarItem(
                        icon: "house",
                        title: "首页",
                        isSelected: false
                    ) {
                        // Navigate to home
                    }
                    
                    TabBarItem(
                        icon: "photo.stack.fill",
                        title: "作品",
                        isSelected: true
                    ) {
                        // Already on works
                    }
                    
                    TabBarItem(
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
        }
    }
}

// WorkItemView is now defined in WorksViewComponents.swift

struct WorksView_Previews: PreviewProvider {
    static var previews: some View {
        WorksView()
    }
}

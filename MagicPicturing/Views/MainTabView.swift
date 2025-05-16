//
//  MainTabView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var photoLibraryViewModel: PhotoLibraryViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NFTGalleryView(viewModel: photoLibraryViewModel)
                    .tag(0)
                
                WorksView()
                    .tag(1)
                
                ProfileView()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .edgesIgnoringSafeArea(.all)
            
            // Custom Tab Bar
            HStack {
                TabBarButton(
                    icon: "house",
                    iconSelected: "house.fill",
                    title: "首页",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                TabBarButton(
                    icon: "photo.stack",
                    iconSelected: "photo.stack.fill",
                    title: "作品",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                TabBarButton(
                    icon: "person",
                    iconSelected: "person.fill",
                    title: "我的",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
            }
            .padding(.vertical, 8)
            .background(
                Color.black
                    .opacity(0.9)
                    .edgesIgnoringSafeArea(.bottom)
            )
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )
        }
        .preferredColorScheme(.dark)
    }
}

struct TabBarButton: View {
    let icon: String
    let iconSelected: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? iconSelected : icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

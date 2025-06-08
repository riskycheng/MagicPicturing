//
//  MainTabView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Custom tab content without swipe gestures
            ZStack {
                // Only show the selected view
                if selectedTab == 0 {
                    NFTGalleryView()
                        .transition(.opacity)
                } else if selectedTab == 1 {
                    WorksView()
                        .transition(.opacity)
                } else if selectedTab == 2 {
                    ProfileView()
                        .transition(.opacity)
                }
            }
            .animation(.default, value: selectedTab)
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
                Color.white
                    .opacity(0.95)
                    .edgesIgnoringSafeArea(.bottom)
            )
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .top
            )
        }
        .preferredColorScheme(.light)
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

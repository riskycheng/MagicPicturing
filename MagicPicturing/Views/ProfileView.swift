//
//  ProfileView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

struct ProfileView: View {
    @State private var isDarkMode = true
    @State private var language = "简体中文"
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("设置")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                
                // Settings List
                ScrollView {
                    VStack(spacing: 0) {
                        // Personalization section
                        sectionHeader(title: "个性化")
                        
                        settingsRow(
                            icon: "paintpalette",
                            title: "主题色彩",
                            detail: "黑色模式",
                            hasDisclosure: true
                        )
                        
                        settingsRow(
                            icon: "globe",
                            title: "语言",
                            detail: language,
                            hasDisclosure: true
                        )
                        
                        settingsRow(
                            icon: "bell",
                            title: "通知设置",
                            detail: "",
                            hasDisclosure: true
                        )
                        
                        // Storage section
                        sectionHeader(title: "存储与数据")
                        
                        settingsRow(
                            icon: "externaldrive",
                            title: "数据管理",
                            detail: "1.2 GB 已用",
                            hasDisclosure: true
                        )
                        
                        settingsRow(
                            icon: "icloud",
                            title: "缓存设置",
                            detail: "256 MB",
                            hasDisclosure: true
                        )
                        
                        // Privacy section
                        sectionHeader(title: "隐私与安全")
                        
                        settingsRow(
                            icon: "lock.shield",
                            title: "隐私设置",
                            detail: "",
                            hasDisclosure: true
                        )
                    }
                    .background(Color(UIColor.systemBackground).opacity(0.1))
                    .cornerRadius(10)
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
                        icon: "photo.stack",
                        title: "作品",
                        isSelected: false
                    ) {
                        // Navigate to works
                    }
                    
                    TabBarItem(
                        icon: "person.fill",
                        title: "我的",
                        isSelected: true
                    ) {
                        // Already on profile
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
    
    // Section header
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Spacer()
        }
        .background(Color.black)
    }
    
    // Settings row
    private func settingsRow(icon: String, title: String, detail: String, hasDisclosure: Bool) -> some View {
        Button(action: {
            // Handle tap on settings row
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !detail.isEmpty {
                    Text(detail)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                if hasDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.black)
        }
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

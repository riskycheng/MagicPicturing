//
//  WorksViewComponents.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

// MARK: - Work Item View
struct WorkItemView: View {
    let photo: PhotoItem
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(12)
            
            // Symbol image
            Image(systemName: photo.symbolName)
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 60, height: 60)
                .position(x: PlatformConstants.screenWidth / 4, y: PlatformConstants.screenWidth / 4 - 30)
            
            // Photo info overlay
            WorkItemInfoOverlay(title: photo.title, date: photo.formattedDate)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Work Item Info Overlay
struct WorkItemInfoOverlay: View {
    let title: String
    let date: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(date)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
    }
}

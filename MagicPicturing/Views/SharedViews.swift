//
//  SharedViews.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

// Primary action button used throughout the app
struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

// Share button component
struct ShareButton: View {
    let item: Any
    
    var body: some View {
        #if canImport(UIKit)
        Button(action: {
            let activityVC = UIActivityViewController(activityItems: [item], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true, completion: nil)
            }
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .padding(8)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Circle())
        }
        #else
        Button(action: {
            // macOS sharing implementation would go here
            print("Share action on macOS")
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .padding(8)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Circle())
        }
        #endif
    }
}

// Tab bar item view
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
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

// Category button for filtering photos
struct CategoryButton: View {
    let category: PhotoCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(category.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                if isSelected {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 2)
                        .cornerRadius(1)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 20, height: 2)
                }
            }
            .padding(.horizontal, 12)
        }
    }
}

// Empty state view
struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

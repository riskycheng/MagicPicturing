//
//  HomeViewComponents.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - NFT Gallery Card View
struct CardView: View {
    let photo: PhotoItem
    let isFocused: Bool
    let offset: CGFloat
    let index: Int
    
    private let cardWidth: CGFloat = 340
    private let cardHeight: CGFloat = 500
    
    // Animation properties
    private var scale: CGFloat {
        isFocused ? 1.0 : 0.8
    }
    
    private var rotation: Double {
        if isFocused {
            return offset * 0.05
        } else {
            // 非焦点卡片向左旋转
            return -Double(index) * 8
        }
    }
    
    private var xOffset: CGFloat {
        if isFocused {
            return 0
        } else {
            // 非焦点卡片向左堆叠
            return -CGFloat(index) * 60
        }
    }
    
    private var yOffset: CGFloat {
        if isFocused {
            return 0
        } else {
            // 非焦点卡片稍微向上堆叠
            return CGFloat(index) * 5
        }
    }
    
    private var opacity: Double {
        isFocused ? 1.0 : 0.7
    }
    
    private var randomNumber: Int {
        let numbers = [4032, 6721, 8901, 1234, 5678]
        return numbers[index % numbers.count]
    }
    
    private var collectionNames: [String] {
        ["Shadowverse", "Titans", "Raven", "Legends", "Ethereal"]
    }
    
    private var creatorNames: [String] {
        ["Umbra", "Nexus", "Void", "Stellar", "Prism"]
    }
    
    var body: some View {
        ZStack {
            // Main card
            VStack(spacing: 0) {
                // Image area
                ZStack(alignment: .bottomLeading) {
                    // Background image with gradient overlay
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: photo.gradientStart),
                                    Color(hex: photo.gradientEnd)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Main image/icon
                    Image(systemName: photo.symbolName)
                        .font(.system(size: 120, weight: .light))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                    
                    // Position indicator pill
                    if isFocused {
                        HStack(spacing: 4) {
                            Text("\(index + 1) of 5")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.7)
                                )
                        }
                        .padding(20)
                    }
                }
                .frame(height: cardHeight * 0.75)
                
                // Info area
                VStack(alignment: .leading, spacing: 8) {
                    // Collection name
                    Text(collectionNames[index % collectionNames.count])
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Creator info
                    HStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: photo.gradientEnd),
                                        Color(hex: photo.gradientStart)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                        
                        Text(creatorNames[index % creatorNames.count])
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(
                    Color.black.opacity(0.7)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            
            // ID tag in corner
            if isFocused {
                VStack {
                    HStack {
                        Text("#\(randomNumber)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.7))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(15)
                .frame(width: cardWidth, height: cardHeight)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        // Apply 3D transformations
        .scaleEffect(scale)
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .offset(x: xOffset, y: yOffset)
        .opacity(opacity)
        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Card Info Overlay
struct CardInfoOverlay: View {
    let title: String
    let date: Date
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2)
            
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.3), radius: 2)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .opacity(0.2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Home Header View
struct HomeHeaderView: View {
    let addAction: () -> Void
    
    var body: some View {
        HStack {
            Text("Magic Pictures")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 2)
            
            Spacer()
            
            Button(action: addAction) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "2E90FA"), Color(hex: "1570EF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: "1570EF").opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

// MARK: - Home Category Button
struct HomeCategoryButton: View {
    let category: PhotoCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color(hex: "2E90FA"), Color(hex: "1570EF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.black.opacity(0.3)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: isSelected ? Color(hex: "1570EF").opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Home Tab Bar Item
struct HomeTabBarItem: View {
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
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Filter Options View
struct FilterOptionsView: View {
    @Binding var selectedFilter: String?
    @Binding var filterIntensity: Double
    
    private let filterOptions = ["Mono", "Noir", "Fade", "Chrome", "Process", "Transfer", "Instant"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("滤镜")
                .font(.headline)
                .foregroundColor(.white)
            
            // Filter options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(filterOptions, id: \.self) { filter in
                        let isSelected = selectedFilter == filter
                        FilterOptionButton(
                            filter: filter, 
                            isSelected: isSelected
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            
            // Intensity slider
            if selectedFilter != nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text("强度")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("0")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Slider(value: $filterIntensity, in: 0...1)
                            .accentColor(.blue)
                        
                        Text("100")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(15)
    }
}

// MARK: - Filter Option Button
struct FilterOptionButton: View {
    let filter: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(filter)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                )
        }
    }
}

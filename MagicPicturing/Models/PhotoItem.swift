//
//  PhotoItem.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import Foundation
import SwiftUI

struct PhotoItem: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let imageName: String
    let category: PhotoCategory
    let symbolName: String
    
    var gradientStart: String {
        switch imageName {
        case "beach": return "1E90FF"    // 蓝色
        case "city": return "FF8C00"     // 橙色
        case "concert": return "9400D3"  // 紫色
        case "mountain": return "228B22" // 绿色
        case "band": return "FF1493"     // 粉色
        case "cartoon": return "FFD700"  // 金色
        default: return "4169E1"         // 默认蓝色
        }
    }
    
    var gradientEnd: String {
        switch imageName {
        case "beach": return "00BFFF"    // 浅蓝色
        case "city": return "FFA500"     // 橙黄色
        case "concert": return "8A2BE2"  // 紫蓝色
        case "mountain": return "32CD32" // 浅绿色
        case "band": return "FF69B4"     // 粉红色
        case "cartoon": return "FFA07A"  // 浅橙色
        default: return "1E90FF"         // 默认蓝色
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今天 HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "昨天 HH:mm"
        } else {
            formatter.dateFormat = "M月d日"
        }
        
        return formatter.string(from: date)
    }
}

enum PhotoCategory: String, CaseIterable {
    case all = "全部"
    case filter = "滤镜"
    case ai = "AI修图"
    case template = "模版"
    
    var iconName: String {
        switch self {
        case .all: return "photo"
        case .filter: return "camera.filters"
        case .ai: return "wand.and.stars"
        case .template: return "rectangle.3.group"
        }
    }
}

// Placeholder for empty state
extension PhotoItem {
    static var placeholder: PhotoItem {
        return PhotoItem(
            title: "示例相册",
            date: Date(),
            imageName: "beach",
            category: .all,
            symbolName: "photo"
        )
    }
}

// Sample data
extension PhotoItem {
    static var sampleItems: [PhotoItem] = [
        PhotoItem(title: "夏日海滩", date: Date().addingTimeInterval(-3600), imageName: "beach", category: .filter, symbolName: "sun.max.fill"),
        PhotoItem(title: "城市夜景", date: Date().addingTimeInterval(-86400), imageName: "city", category: .template, symbolName: "building.2.fill"),
        PhotoItem(title: "音乐会", date: Date().addingTimeInterval(-172800), imageName: "concert", category: .template, symbolName: "music.note.list"),
        PhotoItem(title: "山间日出", date: Date().addingTimeInterval(-259200), imageName: "mountain", category: .all, symbolName: "mountain.2.fill"),
        PhotoItem(title: "乐队表演", date: Date().addingTimeInterval(-345600), imageName: "band", category: .ai, symbolName: "music.mic"),
        PhotoItem(title: "动漫人物", date: Date().addingTimeInterval(-432000), imageName: "cartoon", category: .ai, symbolName: "person.fill")
    ]
}

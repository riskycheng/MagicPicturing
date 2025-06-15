//
//  PlatformTypes.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
typealias PlatformColor = NSColor
#endif

// Platform constants
struct PlatformConstants {
    #if canImport(UIKit)
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    static var safeAreaInsets: EdgeInsets {
        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        let safeAreaInsets = keyWindow?.safeAreaInsets ?? .zero
        return EdgeInsets(
            top: safeAreaInsets.top,
            leading: safeAreaInsets.left,
            bottom: safeAreaInsets.bottom,
            trailing: safeAreaInsets.right
        )
    }
    #elseif canImport(AppKit)
    static var screenWidth: CGFloat {
        NSScreen.main?.frame.width ?? 1024
    }
    
    static var screenHeight: CGFloat {
        NSScreen.main?.frame.height ?? 768
    }
    
    static var safeAreaInsets: EdgeInsets {
        return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    #endif
}

// CGRectCorner enum for macOS compatibility
#if canImport(AppKit)
enum CGRectCorner {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case allCorners
}
#endif

// RoundedCorner shape for both platforms
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// View extension for cornerRadius with platform-specific implementations
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

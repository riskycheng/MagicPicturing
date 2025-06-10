import SwiftUI

struct CollageLayoutProvider {
    
    static func getLayouts(for imageCount: Int) -> [CollageLayout] {
        switch imageCount {
        case 2:
            return [
                CollageLayout(name: "2-H", aspectRatio: 4/3, frames: [h_split(0, of: 2), h_split(1, of: 2)]),
                CollageLayout(name: "2-V", aspectRatio: 3/4, frames: [v_split(0, of: 2), v_split(1, of: 2)])
            ]
        case 3:
            return [
                CollageLayout(name: "3-V", aspectRatio: 3/4, frames: (0..<3).map { v_split($0, of: 3) }),
                CollageLayout(name: "3-H", aspectRatio: 4/3, frames: (0..<3).map { h_split($0, of: 3) }),
                CollageLayout(name: "3-T-Big", aspectRatio: 1, frames: [v_split_fract(0, frac: 2/3), h_split(0, of: 2, in: v_split_fract(1, frac: 1/3, from: 2/3)), h_split(1, of: 2, in: v_split_fract(1, frac: 1/3, from: 2/3))]),
                CollageLayout(name: "3-B-Big", aspectRatio: 1, frames: [h_split(0, of: 2, in: v_split_fract(0, frac: 1/3)), h_split(1, of: 2, in: v_split_fract(0, frac: 1/3)), v_split_fract(1, frac: 2/3, from: 1/3)]),
                CollageLayout(name: "3-L-Big", aspectRatio: 1, frames: [h_split_fract(0, frac: 2/3), v_split(0, of: 2, in: h_split_fract(1, frac: 1/3, from: 2/3)), v_split(1, of: 2, in: h_split_fract(1, frac: 1/3, from: 2/3))]),
                CollageLayout(name: "3-R-Big", aspectRatio: 1, frames: [v_split(0, of: 2, in: h_split_fract(0, frac: 1/3)), v_split(1, of: 2, in: h_split_fract(0, frac: 1/3)), h_split_fract(1, frac: 2/3, from: 1/3)])
            ]
        case 4:
            return [
                CollageLayout(name: "4-Grid", aspectRatio: 1, frames: (0..<4).map { grid($0, cols: 2, rows: 2) }),
                CollageLayout(name: "4-V-Strip", aspectRatio: 9/16, frames: (0..<4).map { v_split($0, of: 4) }),
                CollageLayout(name: "4-H-Strip", aspectRatio: 16/9, frames: (0..<4).map { h_split($0, of: 4) }),
                CollageLayout(name: "4-T-Big", aspectRatio: 4/3, frames: [v_split_fract(0, frac: 2/3), h_split(0, of: 3, in: v_split_fract(1, frac: 1/3, from: 2/3)), h_split(1, of: 3, in: v_split_fract(1, frac: 1/3, from: 2/3)), h_split(2, of: 3, in: v_split_fract(1, frac: 1/3, from: 2/3))]),
                CollageLayout(name: "4-L-Big", aspectRatio: 3/4, frames: [h_split_fract(0, frac: 2/3), v_split(0, of: 3, in: h_split_fract(1, frac: 1/3, from: 2/3)), v_split(1, of: 3, in: h_split_fract(1, frac: 1/3, from: 2/3)), v_split(2, of: 3, in: h_split_fract(1, frac: 1/3, from: 2/3))])
            ]
        case 5:
             return [
                CollageLayout(name: "5-L-Big-Grid", aspectRatio: 1, frames: [h_split_fract(0, frac: 2/3), grid(0, cols: 1, rows: 4, in: h_split_fract(1, frac: 1/3, from: 2/3)), grid(1, cols: 1, rows: 4, in: h_split_fract(1, frac: 1/3, from: 2/3)), grid(2, cols: 1, rows: 4, in: h_split_fract(1, frac: 1/3, from: 2/3)), grid(3, cols: 1, rows: 4, in: h_split_fract(1, frac: 1/3, from: 2/3))]),
                CollageLayout(name: "5-T-Big-Grid", aspectRatio: 1, frames: [v_split_fract(0, frac: 2/3), grid(0, cols: 4, rows: 1, in: v_split_fract(1, frac: 1/3, from: 2/3)), grid(1, cols: 4, rows: 1, in: v_split_fract(1, frac: 1/3, from: 2/3)), grid(2, cols: 4, rows: 1, in: v_split_fract(1, frac: 1/3, from: 2/3)), grid(3, cols: 4, rows: 1, in: v_split_fract(1, frac: 1/3, from: 2/3))]),
                CollageLayout(name: "5-Center-Hero", aspectRatio: 4/3, frames: [v_split(0,of:2, in: h_split_fract(0, frac: 1/4)), v_split(1,of:2, in: h_split_fract(0, frac: 1/4)), h_split_fract(1, frac: 2/4, from: 1/4), v_split(0,of:2, in: h_split_fract(2, frac: 1/4, from: 3/4)), v_split(1,of:2, in: h_split_fract(2, frac: 1/4, from: 3/4))]),
                CollageLayout(name: "5-V-Stripe-Grid", aspectRatio: 3/4, frames: [v_split_fract(0, frac: 1/2), grid(0, cols: 2, rows: 2, in: v_split_fract(1, frac: 1/2, from: 1/2)), grid(1, cols: 2, rows: 2, in: v_split_fract(1, frac: 1/2, from: 1/2)), grid(2, cols: 2, rows: 2, in: v_split_fract(1, frac: 1/2, from: 1/2)), grid(3, cols: 2, rows: 2, in: v_split_fract(1, frac: 1/2, from: 1/2))]),
                CollageLayout(name: "5-H-Stripe-Grid", aspectRatio: 4/3, frames: [h_split_fract(0, frac: 1/2), grid(0, cols: 2, rows: 2, in: h_split_fract(1, frac: 1/2, from: 1/2)), grid(1, cols: 2, rows: 2, in: h_split_fract(1, frac: 1/2, from: 1/2)), grid(2, cols: 2, rows: 2, in: h_split_fract(1, frac: 1/2, from: 1/2)), grid(3, cols: 2, rows: 2, in: h_split_fract(1, frac: 1/2, from: 1/2))])
            ]
        case 6:
            return [
                CollageLayout(name: "6-Grid-2x3", aspectRatio: 2/3, frames: (0..<6).map { grid($0, cols: 2, rows: 3) }),
                CollageLayout(name: "6-Grid-3x2", aspectRatio: 3/2, frames: (0..<6).map { grid($0, cols: 3, rows: 2) }),
                CollageLayout(name: "6-T-Hero", aspectRatio: 4/3, frames: [v_split_fract(0, frac: 2/3), h_split(0,of:5, in: v_split_fract(1, frac: 1/3, from: 2/3)), h_split(1,of:5, in: v_split_fract(1, frac: 1/3, from: 2/3)), h_split(2,of:5, in: v_split_fract(1, frac: 1/3, from: 2/3)), h_split(3,of:5, in: v_split_fract(1, frac: 1/3, from: 2/3)), h_split(4,of:5, in: v_split_fract(1, frac: 1/3, from: 2/3))]),
                CollageLayout(name: "6-L-Hero", aspectRatio: 3/4, frames: [h_split_fract(0, frac: 2/3), v_split(0,of:5, in: h_split_fract(1, frac: 1/3, from: 2/3)), v_split(1,of:5, in: h_split_fract(1, frac: 1/3, from: 2/3)), v_split(2,of:5, in: h_split_fract(1, frac: 1/3, from: 2/3)), v_split(3,of:5, in: h_split_fract(1, frac: 1/3, from: 2/3)), v_split(4,of:5, in: h_split_fract(1, frac: 1/3, from: 2/3))])
            ]
        case 7:
             return [
                CollageLayout(name: "7-Center-Hero", aspectRatio: 1, frames: [grid(0, cols: 3, rows: 3), grid(1, cols: 3, rows: 3), grid(2, cols: 3, rows: 3), grid(3, cols: 3, rows: 3), grid(4, cols: 3, rows: 3), grid(5, cols: 3, rows: 3), grid(6, cols: 3, rows: 3), grid(7, cols: 3, rows: 3), grid(8, cols: 3, rows: 3)].enumerated().filter{ $0.offset != 4 }.map{ $0.element }), // 3x3 grid with center missing
                CollageLayout(name: "7-T-Grid", aspectRatio: 4/5, frames: [v_split_fract(0, frac: 1/3), grid(0, cols: 3, rows: 2, in: v_split_fract(1, frac: 2/3, from: 1/3)), grid(1, cols: 3, rows: 2, in: v_split_fract(1, frac: 2/3, from: 1/3)), grid(2, cols: 3, rows: 2, in: v_split_fract(1, frac: 2/3, from: 1/3)), grid(3, cols: 3, rows: 2, in: v_split_fract(1, frac: 2/3, from: 1/3)), grid(4, cols: 3, rows: 2, in: v_split_fract(1, frac: 2/3, from: 1/3)), grid(5, cols: 3, rows: 2, in: v_split_fract(1, frac: 2/3, from: 1/3))]),
                CollageLayout(name: "7-H-Stripes", aspectRatio: 16/9, frames: (0..<7).map { h_split($0, of: 7) })
             ]
        case 8:
            return [
                CollageLayout(name: "8-Grid-4x2", aspectRatio: 2, frames: (0..<8).map { grid($0, cols: 4, rows: 2) }),
                CollageLayout(name: "8-Grid-2x4", aspectRatio: 1/2, frames: (0..<8).map { grid($0, cols: 2, rows: 4) }),
                CollageLayout(name: "8-L-Hero", aspectRatio: 1, frames: [h_split_fract(0, frac: 3/4), v_split(0,of:7, in: h_split_fract(1, frac: 1/4, from: 3/4)), v_split(1,of:7, in: h_split_fract(1, frac: 1/4, from: 3/4)), v_split(2,of:7, in: h_split_fract(1, frac: 1/4, from: 3/4)), v_split(3,of:7, in: h_split_fract(1, frac: 1/4, from: 3/4)), v_split(4,of:7, in: h_split_fract(1, frac: 1/4, from: 3/4)), v_split(5,of:7, in: h_split_fract(1, frac: 1/4, from: 3/4)), v_split(6,of:7, in: h_split_fract(1, frac: 1/4, from: 3/4))])
            ]
        case 9:
            return [
                CollageLayout(name: "9-Grid", aspectRatio: 1, frames: (0..<9).map { grid($0, cols: 3, rows: 3) }),
                CollageLayout(name: "9-H-Stripes", aspectRatio: 16/9, frames: (0..<9).map { h_split($0, of: 9) }),
                CollageLayout(name: "9-V-Stripes", aspectRatio: 9/16, frames: (0..<9).map { v_split($0, of: 9) })
            ]
        default:
             if imageCount > 0 {
                let frames = (0..<imageCount).map { v_split($0, of: imageCount) }
                return [CollageLayout(name: "\(imageCount)-V-Fallback", aspectRatio: 3/4, frames: frames)]
            }
            return []
        }
    }
}

// MARK: - Layout Helper Functions
private extension CollageLayoutProvider {
    
    // Vertical split
    static func v_split(_ index: Int, of total: Int, in rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> CGRect {
        let height = rect.height / CGFloat(total)
        return CGRect(x: rect.minX, y: rect.minY + CGFloat(index) * height, width: rect.width, height: height)
    }

    // Horizontal split
    static func h_split(_ index: Int, of total: Int, in rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> CGRect {
        let width = rect.width / CGFloat(total)
        return CGRect(x: rect.minX + CGFloat(index) * width, y: rect.minY, width: width, height: rect.height)
    }
    
    // Vertical fractional split
    static func v_split_fract(_ index: Int, frac: CGFloat, from: CGFloat = 0, in rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> CGRect {
        let y = rect.minY + from * rect.height
        let h = frac * rect.height
        return CGRect(x: rect.minX, y: y, width: rect.width, height: h)
    }

    // Horizontal fractional split
    static func h_split_fract(_ index: Int, frac: CGFloat, from: CGFloat = 0, in rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> CGRect {
        let x = rect.minX + from * rect.width
        let w = frac * rect.width
        return CGRect(x: x, y: rect.minY, width: w, height: rect.height)
    }

    // Grid layout
    static func grid(_ index: Int, cols: Int, rows: Int, in rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> CGRect {
        let width = rect.width / CGFloat(cols)
        let height = rect.height / CGFloat(rows)
        let rowIndex = index / cols
        let colIndex = index % cols
        return CGRect(x: rect.minX + CGFloat(colIndex) * width, y: rect.minY + CGFloat(rowIndex) * height, width: width, height: height)
    }
} 
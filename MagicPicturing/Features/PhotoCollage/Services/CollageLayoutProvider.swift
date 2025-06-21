import SwiftUI

struct CollageLayoutProvider {
    
    static func getLayouts(for imageCount: Int) -> [CollageLayout] {
        switch imageCount {
        case 2:
            return [
                adjustableLayout(name: "2-H-Adjustable", aspectRatio: 4/3, hSplits: [0.5]),
                adjustableLayout(name: "2-V-Adjustable", aspectRatio: 3/4, vSplits: [0.5])
            ]
        case 3:
            return [
                adjustableLayout(name: "3-V-Strip", aspectRatio: 3/4, vSplits: [1/3, 2/3]),
                adjustableLayout(name: "3-H-Strip", aspectRatio: 4/3, hSplits: [1/3, 2/3]),
                // Other more complex layouts can be added here if needed
            ]
        case 4:
            return [
                adjustableLayout(name: "4-Grid", aspectRatio: 1, hSplits: [0.5], vSplits: [0.5]),
                adjustableLayout(name: "4-V-Strip", aspectRatio: 9/16, vSplits: [0.25, 0.5, 0.75]),
                adjustableLayout(name: "4-H-Strip", aspectRatio: 16/9, hSplits: [0.25, 0.5, 0.75])
            ]
        case 5:
             return [
                adjustableLayout(name: "5-L-Big-Grid", aspectRatio: 1, hSplits: [2/3], vSplits: [0.25, 0.5, 0.75]),
                // Fallback for other 5-image layouts to simple strips
                adjustableLayout(name: "5-V-Strip", aspectRatio: 3/4, vSplits: [0.2, 0.4, 0.6, 0.8]),
                adjustableLayout(name: "5-H-Strip", aspectRatio: 4/3, hSplits: [0.2, 0.4, 0.6, 0.8])
            ]
        case 6:
            return [
                adjustableLayout(name: "6-Grid-2x3", aspectRatio: 2/3, hSplits: [0.5], vSplits: [1/3, 2/3]),
                adjustableLayout(name: "6-Grid-3x2", aspectRatio: 3/2, hSplits: [1/3, 2/3], vSplits: [0.5])
            ]
        case 7:
            return [
                adjustableLayout(name: "7-V-Strip", aspectRatio: 9/16, vSplits: [1/7, 2/7, 3/7, 4/7, 5/7, 6/7]),
                adjustableLayout(name: "7-H-Strip", aspectRatio: 16/9, hSplits: [1/7, 2/7, 3/7, 4/7, 5/7, 6/7])
            ]
        case 8:
            return [
                adjustableLayout(name: "8-Grid-2x4", aspectRatio: 1/2, hSplits: [0.5], vSplits: [0.25, 0.5, 0.75]),
                adjustableLayout(name: "8-Grid-4x2", aspectRatio: 2, hSplits: [0.25, 0.5, 0.75], vSplits: [0.5])
            ]
        case 9:
            return [
                 adjustableLayout(name: "9-Grid-3x3", aspectRatio: 1, hSplits: [1/3, 2/3], vSplits: [1/3, 2/3]),
                 adjustableLayout(name: "9-V-Strip", aspectRatio: 9/16, vSplits: [1/9, 2/9, 3/9, 4/9, 5/9, 6/9, 7/9, 8/9]),
                 adjustableLayout(name: "9-H-Strip", aspectRatio: 16/9, hSplits: [1/9, 2/9, 3/9, 4/9, 5/9, 6/9, 7/9, 8/9])
            ]
        default:
             if imageCount > 0, imageCount <= 10 { // Cap at 10 for sanity
                return [adjustableLayout(name: "\(imageCount)-V-Fallback", aspectRatio: 3/4, vSplits: (1..<imageCount).map { CGFloat($0) / CGFloat(imageCount) })]
            }
            return []
        }
    }
}

// MARK: - Layout Generation Helpers

private func adjustableLayout(name: String, aspectRatio: CGFloat, hSplits: [CGFloat] = [], vSplits: [CGFloat] = []) -> CollageLayout {
    var parameters: [String: CollageLayout.Parameter] = [:]
    
    for (i, v) in hSplits.enumerated() {
        parameters["h_split\(i + 1)"] = .init(value: v, range: 0.1...0.9)
    }
    for (i, v) in vSplits.enumerated() {
        parameters["v_split\(i + 1)"] = .init(value: v, range: 0.1...0.9)
    }

    let frameGenerator: ([String: CollageLayout.Parameter]) -> [CGRect] = { params in
        let hValues = hSplits.isEmpty ? [] : (1...hSplits.count).map { params["h_split\($0)"]!.value }
        let vValues = vSplits.isEmpty ? [] : (1...vSplits.count).map { params["v_split\($0)"]!.value }
        
        let hSegments = ([0] + hValues + [1]).windows(ofCount: 2).map { $0.last! - $0.first! }
        let vSegments = ([0] + vValues + [1]).windows(ofCount: 2).map { $0.last! - $0.first! }
        
        var frames: [CGRect] = []
        var y: CGFloat = 0
        for vSegment in vSegments {
            var x: CGFloat = 0
            for hSegment in hSegments {
                frames.append(CGRect(x: x, y: y, width: hSegment, height: vSegment))
                x += hSegment
            }
            y += vSegment
        }
        
        // This generic generator creates a simple grid.
        // More complex logic is needed for non-grid layouts like "5-L-Big-Grid".
        // For now, we are simplifying to ensure all layouts are adjustable.
        // The specific logic for "5-L-Big-Grid" can be re-added if necessary.
        if name == "5-L-Big-Grid" {
             let h_split_val = params["h_split1"]!.value
             let v1 = params["v_split1"]!.value
             let v2 = params["v_split2"]!.value
             let v3 = params["v_split3"]!.value
            
             let leftFrame = CGRect(x: 0, y: 0, width: h_split_val, height: 1)
             let rightColumnRect = CGRect(x: h_split_val, y: 0, width: 1 - h_split_val, height: 1)

             let rightFrames = [
                 v_split_fract(0, frac: v1, in: rightColumnRect),
                 v_split_fract(1, frac: v2 - v1, from: v1, in: rightColumnRect),
                 v_split_fract(2, frac: v3 - v2, from: v2, in: rightColumnRect),
                 v_split_fract(3, frac: 1.0 - v3, from: v3, in: rightColumnRect)
             ]
             return [leftFrame] + rightFrames
        }

        return frames
    }
    
    return CollageLayout(name: name, aspectRatio: aspectRatio, parameters: parameters, frameGenerator: frameGenerator)
}

// MARK: - CGRect Helpers (can be moved to a separate file)
private func v_split_fract(_ index: Int, frac: CGFloat, from: CGFloat = 0, in rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> CGRect {
    let y = rect.minY + from * rect.height
    let h = frac * rect.height
    return CGRect(x: rect.minX, y: y, width: rect.width, height: h)
}

extension Array {
    func windows(ofCount count: Int) -> [[Element]] {
        var result: [[Element]] = []
        guard self.count >= count else { return [] }
        for i in 0...(self.count - count) {
            result.append(Array(self[i..<(i + count)]))
        }
        return result
    }
} 
import SwiftUI

struct Polygon: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard let firstPoint = points.first else { return path }

        let denormalizedPoints = points.map {
            CGPoint(x: $0.x * rect.width, y: $0.y * rect.height)
        }
        
        path.move(to: denormalizedPoints[0])
        
        for i in 1..<denormalizedPoints.count {
            path.addLine(to: denormalizedPoints[i])
        }
        
        path.closeSubpath()

        return path
    }
} 
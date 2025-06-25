import SwiftUI

struct ShapeFactory {
    @ViewBuilder
    static func shape(for definition: CollageLayoutTemplate.ShapeDefinition?) -> some View {
        let shape = createShape(from: definition)
        shape
    }

    static func createShape(from definition: CollageLayoutTemplate.ShapeDefinition?) -> AnyShape {
        guard let definition = definition else {
            return AnyShape(Rectangle())
        }

        switch definition.type {
        case "rectangle":
            if let cornerRadiusStr = definition.parameters?["cornerRadius"],
               let cornerRadius = Double(cornerRadiusStr) {
                 // Using a custom shape to handle corner radius on a specific type
                 return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            return AnyShape(Rectangle())
        case "circle":
            return AnyShape(Circle())
        case "ellipse":
            return AnyShape(Ellipse())
        case "capsule":
            return AnyShape(Capsule())
        case "polygon":
            guard let pointsArray = definition.parameters?["points"],
                  let points = parsePoints(from: pointsArray) else {
                return AnyShape(Rectangle()) // Fallback to rectangle if points are invalid
            }
            return AnyShape(Polygon(points: points))
        default:
            return AnyShape(Rectangle())
        }
    }
    
    private static func parsePoints(from string: String) -> [CGPoint]? {
        // Expected format: "[0,0; 0,1; 1,1; 1,0]"
        let pointStrings = string.replacingOccurrences(of: "[", with: "")
                                 .replacingOccurrences(of: "]", with: "")
                                 .split(separator: ";")
        
        var points: [CGPoint] = []
        for pointString in pointStrings {
            let coords = pointString.split(separator: ",")
            if coords.count == 2,
               let x = Double(coords[0].trimmingCharacters(in: .whitespaces)),
               let y = Double(coords[1].trimmingCharacters(in: .whitespaces)) {
                points.append(CGPoint(x: x, y: y))
            } else {
                return nil // Invalid format
            }
        }
        return points
    }
}

// A helper shape to use RoundedRectangle with 'any Shape' type
struct RoundedRectangle: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = Path(roundedRect: rect, cornerRadius: cornerRadius)
        return path
    }
} 
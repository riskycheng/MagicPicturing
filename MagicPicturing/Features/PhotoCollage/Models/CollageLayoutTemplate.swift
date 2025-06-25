import Foundation
import CoreGraphics

struct CollageLayoutTemplate: Decodable, Identifiable {
    var id: String { name }
    let name: String
    let imageCount: Int
    let aspectRatio: CGFloat
    let parameters: [String: InitialParameter]?
    let frameDefinitions: [FrameDefinition]

    struct InitialParameter: Decodable {
        let initial: CGFloat
        let range: [CGFloat]
    }

    struct FrameDefinition: Decodable {
        let x: String
        let y: String
        let width: String
        let height: String
        let rotation: String?
        let shape: ShapeDefinition?
    }
    
    struct ShapeDefinition: Decodable {
        // e.g., "rectangle", "circle", "ellipse", "capsule", "diamond"
        let type: String
        // e.g., for a rounded rectangle, we might have { "cornerRadius": "0.1" }
        let parameters: [String: String]?
    }
} 
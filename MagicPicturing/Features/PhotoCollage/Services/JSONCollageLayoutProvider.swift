import Foundation
import SwiftUI
import CoreGraphics

class JSONCollageLayoutProvider {
    func loadTemplates(for imageCount: Int? = nil) -> [CollageLayout] {
        guard let count = imageCount else {
            // If no image count is provided, we don't know which folder to search.
            return []
        }
        
        // Construct the subdirectory path based on the image count.
        let subdirectory = "CollageTemplates/\(count)_images"
        
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: subdirectory) else {
            print("Could not find any JSON template files in directory: \(subdirectory)")
            return []
        }

        return urls.compactMap { url in
            do {
                let data = try Data(contentsOf: url)
                let template = try JSONDecoder().decode(CollageLayoutTemplate.self, from: data)
                return templateToLayout(template)
            } catch {
                print("Error loading or decoding template from \(url): \(error)")
                return nil
            }
        }
    }
    
    private func templateToLayout(_ template: CollageLayoutTemplate) -> CollageLayout {
        let parameters: [String: CollageLayout.Parameter] = (template.parameters ?? [:]).mapValues { param in
            let range = (param.range.count == 2) ? (param.range[0]...param.range[1]) : (0.0...1.0)
            return CollageLayout.Parameter(value: param.initial, range: ClosedRange(uncheckedBounds: (lower: range.lowerBound, upper: range.upperBound)))
        }
        
        let frameGenerator: ([String: CollageLayout.Parameter]) -> [CellState] = { params in
            return template.frameDefinitions.map { frameDef in
                let x = self.evaluate(frameDef.x, with: params)
                let y = self.evaluate(frameDef.y, with: params)
                let width = self.evaluate(frameDef.width, with: params)
                let height = self.evaluate(frameDef.height, with: params)
                let rect = CGRect(x: x, y: y, width: width, height: height)

                let rotationDegrees = self.evaluate(frameDef.rotation ?? "0", with: params)
                let rotation = Angle(degrees: Double(rotationDegrees))

                return CellState(frame: rect, rotation: rotation, shapeDefinition: frameDef.shape)
            }
        }
        
        return CollageLayout(
            name: template.name,
            aspectRatio: template.aspectRatio,
            parameters: parameters,
            frameGenerator: frameGenerator
        )
    }
    
    private func evaluate(_ expression: String, with params: [String: CollageLayout.Parameter]) -> CGFloat {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        
        // Simple constant
        if let number = Double(trimmed) {
            return CGFloat(number)
        }
        
        // Simple parameter access e.g. "params.h_split1"
        let paramPrefix = "params."
        if trimmed.starts(with: paramPrefix) {
            let paramKey = String(trimmed.dropFirst(paramPrefix.count))
            if let param = params[paramKey] {
                return param.value
            } else {
                print("Warning: Unknown parameter \(paramKey) in expression '\(expression)'")
                return 0
            }
        }
        
        // Simple arithmetic e.g. "1 - params.h_split1"
        let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if components.count == 3 {
            let lhs = evaluate(components[0], with: params)
            let op = components[1]
            let rhs = evaluate(components[2], with: params)
            
            switch op {
            case "+": return lhs + rhs
            case "-": return lhs - rhs
            case "*": return lhs * rhs
            case "/": return rhs != 0 ? lhs / rhs : 0
            default:
                break
            }
        }
        
        print("Warning: Could not evaluate expression: \(expression)")
        return 0
    }
} 
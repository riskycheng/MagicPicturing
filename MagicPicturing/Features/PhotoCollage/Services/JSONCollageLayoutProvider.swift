import Foundation
import SwiftUI
import CoreGraphics

class JSONCollageLayoutProvider {
    func loadTemplates(for imageCount: Int? = nil) -> [CollageLayout] {
        // We look for JSON files in the main bundle directory, not a subdirectory.
        // This change adapts to the project setting where individual JSON files are copied
        // to the bundle root instead of the containing folder.
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            print("Could not find any JSON template files in the main bundle.")
            return []
        }
        
        // We only want to load layouts that are specifically for collages.
        // This is a simple way to filter them, assuming they are named appropriately.
        let collageTemplateURLs = urls.filter { $0.lastPathComponent.contains("image") }

        let templates: [CollageLayoutTemplate] = collageTemplateURLs.compactMap { url in
            do {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(CollageLayoutTemplate.self, from: data)
            } catch {
                print("Error loading or decoding template from \(url): \(error)")
                return nil
            }
        }
        
        let filteredTemplates: [CollageLayoutTemplate]
        if let count = imageCount {
            filteredTemplates = templates.filter { $0.imageCount == count }
        } else {
            // If no image count is specified, return all templates.
            filteredTemplates = templates
        }

        return filteredTemplates.map { templateToLayout($0) }
    }
    
    private func templateToLayout(_ template: CollageLayoutTemplate) -> CollageLayout {
        let parameters: [String: CollageLayout.Parameter] = (template.parameters ?? [:]).mapValues { param in
            let range = (param.range.count == 2) ? (param.range[0]...param.range[1]) : (0.0...1.0)
            return CollageLayout.Parameter(value: param.initial, range: ClosedRange(uncheckedBounds: (lower: range.lowerBound, upper: range.upperBound)))
        }
        
        let frameGenerator: ([String: CollageLayout.Parameter]) -> [CGRect] = { params in
            return template.frameDefinitions.map { frameDef in
                let x = self.evaluate(frameDef.x, with: params)
                let y = self.evaluate(frameDef.y, with: params)
                let width = self.evaluate(frameDef.width, with: params)
                let height = self.evaluate(frameDef.height, with: params)
                return CGRect(x: x, y: y, width: width, height: height)
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
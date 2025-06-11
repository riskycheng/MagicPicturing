import SwiftUI

/// Defines the structure for a single collage layout.
class CollageLayout: Identifiable, ObservableObject, Equatable {
    let id = UUID()
    let name: String
    let aspectRatio: CGFloat
    
    struct Parameter {
        var value: CGFloat
        let range: ClosedRange<CGFloat>
    }
    
    @Published var parameters: [String: Parameter]
    
    private var frameGenerator: ([String: Parameter]) -> [CGRect]
    
    var frames: [CGRect] {
        return frameGenerator(parameters)
    }
    
    init(name: String, aspectRatio: CGFloat, parameters: [String: Parameter] = [:], frameGenerator: @escaping ([String: Parameter]) -> [CGRect]) {
        self.name = name
        self.aspectRatio = aspectRatio
        self.parameters = parameters
        self.frameGenerator = frameGenerator
    }
    
    static func == (lhs: CollageLayout, rhs: CollageLayout) -> Bool {
        lhs.id == rhs.id
    }
    
    func updateParameter(_ name: String, value: CGFloat) {
        objectWillChange.send()
        
        guard var param = self.parameters[name] else { return }

        var finalValue = value
        
        // Custom logic for the adjustable layout to prevent dividers from crossing
        if self.name == "5-L-Big-Grid-Adjustable" && name.starts(with: "v_split") {
            let v1 = parameters["v_split1"]!.value
            let v2 = parameters["v_split2"]!.value
            let v3 = parameters["v_split3"]!.value
            
            let minSpacing: CGFloat = 0.05 // 5% minimum height for a cell

            if name == "v_split1" {
                // Dragging the first divider. It can't go past the second divider.
                finalValue = min(finalValue, v2 - minSpacing)
            } else if name == "v_split2" {
                // Dragging the second divider. It must stay between the first and third.
                finalValue = min(max(finalValue, v1 + minSpacing), v3 - minSpacing)
            } else if name == "v_split3" {
                // Dragging the third divider. It can't go before the second.
                finalValue = max(finalValue, v2 + minSpacing)
            }
        }
        
        // Clamp to the parameter's originally defined range
        let clampedValue = min(max(finalValue, param.range.lowerBound), param.range.upperBound)
        
        if self.parameters[name]?.value != clampedValue {
            self.parameters[name]?.value = clampedValue
            print("LOG: Layout Parameter Updated: \(name) = \(clampedValue)")
        }
    }
    
    var preview: AnyView {
        AnyView(
            ZStack {
                ForEach(frames, id: \.self) { frame in
                    Rectangle()
                        .stroke(Color.white, lineWidth: 1)
                        .frame(width: frame.width * 50, height: frame.height * 50)
                        .offset(x: frame.midX * 50 - 25, y: frame.midY * 50 - 25)
                }
            }
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
        )
    }
}

// Conforming to Hashable to be used in ForEach with id: \.self
extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin.x)
        hasher.combine(origin.y)
        hasher.combine(size.width)
        hasher.combine(size.height)
    }
} 
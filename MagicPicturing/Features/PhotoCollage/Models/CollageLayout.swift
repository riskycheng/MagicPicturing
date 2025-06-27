import SwiftUI

struct CellState: Hashable {
    let frame: CGRect
    let rotation: Angle
    let shapeDefinition: CollageLayoutTemplate.ShapeDefinition?
    
    // Make ShapeDefinition hashable so CellState can be hashable
    static func == (lhs: CellState, rhs: CellState) -> Bool {
        lhs.frame == rhs.frame && lhs.rotation == rhs.rotation && lhs.shapeDefinition?.type == rhs.shapeDefinition?.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(frame)
        hasher.combine(rotation)
        hasher.combine(shapeDefinition?.type)
        // Note: This is a simplified hash. If shapes have parameters, we might need a better hash.
    }
}

extension CollageLayoutTemplate.ShapeDefinition: Hashable {
    static func == (lhs: CollageLayoutTemplate.ShapeDefinition, rhs: CollageLayoutTemplate.ShapeDefinition) -> Bool {
        lhs.type == rhs.type && lhs.parameters == rhs.parameters
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        if let params = parameters {
            hasher.combine(params)
        }
    }
}

/// A helper class to throttle the execution of a block of code.
/// This is used to limit the rate of UI updates during rapid events like dragging.
private class Throttler {
    private var workItem: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = .distantPast
    private let queue: DispatchQueue
    private let minimumDelay: TimeInterval

    init(minimumDelay: TimeInterval, queue: DispatchQueue = .main) {
        self.minimumDelay = minimumDelay
        self.queue = queue
    }

    func throttle(_ block: @escaping () -> Void) {
        // Cancel any existing work item
        workItem.cancel()

        // Create a new work item
        workItem = DispatchWorkItem { [weak self] in
            self?.previousRun = Date()
            block()
        }

        // Delay execution
        let delay = previousRun.timeIntervalSinceNow > minimumDelay ? 0 : minimumDelay
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}

/// Defines the structure for a single collage layout.
class CollageLayout: Identifiable, ObservableObject, Equatable {
    let id = UUID()
    let name: String
    let aspectRatio: CGFloat
    
    // Throttler to limit UI updates during fast dragging.
    // 30fps is a good target for smooth animations.
    private lazy var throttler = Throttler(minimumDelay: 1/30)
    
    struct Parameter {
        var value: CGFloat
        let range: ClosedRange<CGFloat>
    }
    
    @Published var parameters: [String: Parameter]
    
    private var frameGenerator: ([String: Parameter]) -> [CellState]
    
    var cellStates: [CellState] {
        return frameGenerator(parameters)
    }
    
    init(name: String, aspectRatio: CGFloat, parameters: [String: Parameter] = [:], frameGenerator: @escaping ([String: Parameter]) -> [CellState]) {
        self.name = name
        self.aspectRatio = aspectRatio
        self.parameters = parameters
        self.frameGenerator = frameGenerator
    }
    
    static func == (lhs: CollageLayout, rhs: CollageLayout) -> Bool {
        lhs.id == rhs.id
    }
    
    func updateParameter(_ name: String, value: CGFloat) {
        // Use the throttler to publish changes, preventing view updates from firing too rapidly.
        throttler.throttle { [weak self] in
            self?.objectWillChange.send()
        }
        
        guard var param = self.parameters[name] else { return }

        var finalValue = value
        
        let minSpacing: CGFloat = 0.05 // 5% minimum cell size

        // Generic logic for vertical multi-split
        if name.starts(with: "v_split") {
            if let numberString = name.components(separatedBy: "v_split").last, let number = Int(numberString) {
                // Check against previous divider
                if let prevParam = parameters["v_split\(number - 1)"] {
                    finalValue = max(finalValue, prevParam.value + minSpacing)
                }
                
                // Check against next divider
                if let nextParam = parameters["v_split\(number + 1)"] {
                    finalValue = min(finalValue, nextParam.value - minSpacing)
                }
            }
        }
        
        // Generic logic for horizontal multi-split
        if name.starts(with: "h_split") {
            if let numberString = name.components(separatedBy: "h_split").last, let number = Int(numberString) {
                // Check against previous divider
                if let prevParam = parameters["h_split\(number - 1)"] {
                    finalValue = max(finalValue, prevParam.value + minSpacing)
                }
                
                // Check against next divider
                if let nextParam = parameters["h_split\(number + 1)"] {
                    finalValue = min(finalValue, nextParam.value - minSpacing)
                }
            }
        }
        
        // Clamp to the parameter's originally defined range
        let clampedValue = min(max(finalValue, param.range.lowerBound), param.range.upperBound)
        
        if self.parameters[name]?.value != clampedValue {
            self.parameters[name]?.value = clampedValue
        }
    }
    
    var preview: AnyView {
        AnyView(
            GeometryReader { geometry in
                let size = geometry.size
                let strokeStyle = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)

                ZStack {
                    // Draw all the paths for the cells
                    Path { path in
                        for cell in self.cellStates {
                            let rect = CGRect(
                                x: cell.frame.origin.x * size.width,
                                y: cell.frame.origin.y * size.height,
                                width: cell.frame.width * size.width,
                                height: cell.frame.height * size.height
                            )
                            
                            let shapePath = ShapeFactory.createShape(from: cell.shapeDefinition)
                                .path(in: rect)
                            
                            let transform: CGAffineTransform
                            if cell.rotation.radians != 0 {
                                let toOrigin = CGAffineTransform(translationX: -rect.midX, y: -rect.midY)
                                let rotation = CGAffineTransform(rotationAngle: cell.rotation.radians)
                                let fromOrigin = CGAffineTransform(translationX: rect.midX, y: rect.midY)
                                transform = toOrigin.concatenating(rotation).concatenating(fromOrigin)
                            } else {
                                transform = .identity
                            }

                            path.addPath(shapePath, transform: transform)
                        }
                    }
                    .stroke(Color.white, style: strokeStyle)

                    // Add a bounding box to ensure the view has a defined frame
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, style: strokeStyle)
                }
            }
            .background(Color.black.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .aspectRatio(1, contentMode: .fit)
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
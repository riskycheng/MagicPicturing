import SwiftUI

extension View {
    @MainActor
    func snapshot() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        return renderer.uiImage
    }
}

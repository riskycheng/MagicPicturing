import SwiftUI

extension View {
    // Captures the entire screen containing the view.
    func snapshotScreen(in windowScene: UIWindowScene?) -> UIImage? {
        guard let window = windowScene?.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
        return renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }
} 
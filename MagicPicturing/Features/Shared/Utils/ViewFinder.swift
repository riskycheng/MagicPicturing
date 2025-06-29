import SwiftUI

// A helper to find the frame of a specific view in the global coordinate space.
class ViewFinder {
    // A simple, identifiable view that we can insert into our hierarchy.
    private struct ViewFinderView: UIViewRepresentable {
        let id: String

        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            view.accessibilityIdentifier = id
            print("[ViewFinder] MAKE: Created UIView with id: \(id)")
            return view
        }

        func updateUIView(_ uiView: UIView, context: Context) {}
    }

    // Finds a UIView with a specific accessibility identifier within the key window.
    private static func findView(withId id: String) -> UIView? {
        print("[ViewFinder] SEARCH: Starting search for view with id: '\(id)'")
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            print("[ViewFinder] SEARCH ERROR: Could not find key window.")
            return nil
        }
        print("[ViewFinder] SEARCH: Found key window: \(window)")

        // Traverse the view hierarchy to find the view with the matching identifier.
        func search(in view: UIView) -> UIView? {
            if view.accessibilityIdentifier == id {
                print("[ViewFinder] SEARCH SUCCESS: Found view with id '\(id)': \(view)")
                return view
            }
            for subview in view.subviews {
                if let found = search(in: subview) {
                    return found
                }
            }
            return nil
        }
        
        let foundView = search(in: window)
        if foundView == nil {
            print("[ViewFinder] SEARCH FAILED: Traversed entire hierarchy but did not find view with id '\(id)'.")
        }
        return foundView
    }

    // Returns a view that can be added to the background to act as a reference point.
    static func view(withId id: String) -> some View {
        return ViewFinderView(id: id)
    }

    // Returns the frame of the reference view in the global coordinate space.
    static func getFrame(for id: String) -> CGRect? {
        print("[ViewFinder] GET FRAME: Attempting to get frame for id: \(id)")
        guard let view = findView(withId: id) else {
            print("[ViewFinder] GET FRAME ERROR: findView returned nil for id: '\(id)'")
            return nil
        }
        guard let superview = view.superview else {
            print("[ViewFinder] GET FRAME ERROR: Found view has no superview.")
            return nil
        }
        let frame = superview.convert(view.frame, to: nil)
        print("[ViewFinder] GET FRAME SUCCESS: Found frame for id '\(id)': \(frame)")
        return frame
    }
} 
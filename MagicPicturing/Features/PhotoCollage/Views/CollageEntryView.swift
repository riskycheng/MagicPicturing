import SwiftUI

/// The main entry point for the photo collage feature.
/// This view wraps the entire flow in a NavigationView and handles dismissal.
struct CollageEntryView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            CollageImageSelectionView(onCancel: {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .preferredColorScheme(.dark)
    }
} 
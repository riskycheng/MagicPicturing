import SwiftUI

struct ImageEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    var body: some View {
        if let initialImage = image {
            ImageEditorView(
                image: $image,
                onDone: { editedImage in
                    image = editedImage
                    dismiss()
                },
                onCancel: {
                    dismiss()
                }
            )
        } else {
            VStack {
                Text("No Image to Edit")
                Button("Close") { dismiss() }.padding()
            }
        }
    }
}

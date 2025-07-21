import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - ImageFilter Enum
enum ImageFilter: String, CaseIterable, Identifiable {
    case original = "Original"
    case sepia = "Sepia"
    case noir = "Noir"
    case vintage = "Vintage"
    case vivid = "Vivid"

    var id: String { self.rawValue }

    func apply(to image: UIImage) -> UIImage {
        guard self != .original else { return image }
        let context = CIContext()
        let ciImage = CIImage(image: image)

        let filter: CIFilter
        switch self {
        case .sepia:
            filter = CIFilter.sepiaTone()
            filter.setValue(1.0, forKey: kCIInputIntensityKey)
        case .noir:
            filter = CIFilter.photoEffectNoir()
        case .vintage:
            filter = CIFilter.photoEffectProcess()
        case .vivid:
            filter = CIFilter.photoEffectInstant()
        default:
            return image
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage, let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - ImageEditorView
struct ImageEditorView: View {
    @Binding var image: UIImage?
    var onDone: (UIImage) -> Void
    var onCancel: () -> Void

    @State private var displayImage: UIImage
    @State private var selectedFilter: ImageFilter = .original

    init(image: Binding<UIImage?>, onDone: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self._image = image
        self.onDone = onDone
        self.onCancel = onCancel
        self._displayImage = State(initialValue: image.wrappedValue ?? UIImage())
    }

    var body: some View {
        NavigationView {
            VStack {
                if let img = image {
                    Image(uiImage: displayImage)
                        .resizable()
                        .scaledToFit()
                        .padding()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(ImageFilter.allCases) { filter in
                                Button(action: { 
                                    selectedFilter = filter
                                    displayImage = filter.apply(to: image ?? UIImage())
                                }) {
                                    VStack {
                                        Image(uiImage: filter.apply(to: img).resized(to: CGSize(width: 80, height: 80)))
                                            .resizable()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedFilter == filter ? Color.blue : Color.clear, lineWidth: 3)
                                            )
                                        Text(filter.rawValue)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { 
                        onDone(displayImage)
                    }
                }
            }
        }
    }
}

// MARK: - UIImage Extension for resizing
extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}

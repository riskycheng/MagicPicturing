import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import TOCropViewController

// MARK: - UIImage Extension
extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}

// MARK: - ImageFilter Enum
enum ImageFilter: String, CaseIterable, Identifiable {
    case original = "Original", sepia = "Sepia", noir = "Noir", vintage = "Vintage",
         vivid = "Vivid", dramatic = "Dramatic", mono = "Mono", fade = "Fade"
    var id: String { self.rawValue }
}

// MARK: - Editing State
private struct EditingState: Equatable {
    var selectedFilter: ImageFilter = .original
    var brightness: Double = 0
    var contrast: Double = 1
    var saturation: Double = 1
}

// MARK: - ImageEditorView
struct ImageEditorView: View {
    @Binding var image: UIImage?
    var onDone: (UIImage) -> Void
    var onCancel: () -> Void

    private let originalImage: UIImage
    @State private var displayImage: UIImage
    @State private var editingState = EditingState()
    @State private var activeTool: EditorTool = .filters
    @State private var showCropView = false
    private let thumbnail: UIImage

    fileprivate enum EditorTool: String, CaseIterable, Identifiable {
        case adjust = "Adjust", filters = "Filters", brightness = "Brightness",
             contrast = "Contrast", saturation = "Saturation"
        var id: String { self.rawValue }
        var systemImageName: String {
            switch self {
            case .adjust: return "crop.rotate"
            case .filters: return "wand.and.stars"
            case .brightness: return "sun.max.fill"
            case .contrast: return "circle.lefthalf.filled"
            case .saturation: return "drop.fill"
            }
        }
    }

    init(image: Binding<UIImage?>, onDone: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self._image = image
        self.onDone = onDone
        self.onCancel = onCancel
        let initialImage = image.wrappedValue ?? UIImage()
        self.originalImage = initialImage
        self._displayImage = State(initialValue: initialImage)
        self.thumbnail = initialImage.resized(to: CGSize(width: 80, height: 80))
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                imageDisplayArea
                controlsArea
            }
        }
        .onChange(of: editingState) { _ in applyChanges() }
        .sheet(isPresented: $showCropView) {
            CropViewWrapper(image: displayImage, croppedImage: $displayImage)
        }
    }

    private var imageDisplayArea: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: displayImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var controlsArea: some View {
        VStack(spacing: 0) {
            toolSelectionBar
                .padding(.vertical)

            EditorControlsView(activeTool: $activeTool, editingState: $editingState, thumbnail: thumbnail, showCropView: $showCropView)
                .frame(height: 80)
                .padding(.bottom)

            bottomNavBar
                .padding()
                .background(Color.black)
        }
    }

    private var toolSelectionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(EditorTool.allCases) { tool in
                    Button(action: { activeTool = tool }) {
                        VStack {
                            Image(systemName: tool.systemImageName)
                                .font(.title2)
                            Text(tool.rawValue).font(.caption)
                        }.foregroundColor(activeTool == tool ? .pink : .white)
                    }
                }
            }.padding(.horizontal)
        }
    }

    private var bottomNavBar: some View {
        HStack {
            Button(action: onCancel) { Image(systemName: "xmark").font(.title) }
            Spacer()
            Button(action: resetAdjustments) { Text("Reset").font(.title2).bold() }
            Spacer()
            Button(action: { onDone(displayImage) }) { Image(systemName: "checkmark").font(.title) }
        }.foregroundColor(.white)
    }

    private func applyChanges() {
        let context = CIContext()
        guard let ciImage = CIImage(image: originalImage) else { return }
        var currentCIImage = ciImage

        if editingState.selectedFilter != .original {
            let filter = Self.createFilter(for: editingState.selectedFilter)
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            currentCIImage = filter.outputImage ?? currentCIImage
        }

        let adjustmentFilter = CIFilter.colorControls()
        adjustmentFilter.inputImage = currentCIImage
        adjustmentFilter.brightness = Float(editingState.brightness)
        adjustmentFilter.contrast = Float(editingState.contrast)
        adjustmentFilter.saturation = Float(editingState.saturation)
        currentCIImage = adjustmentFilter.outputImage ?? currentCIImage

        if let outputCGImage = context.createCGImage(currentCIImage, from: currentCIImage.extent) {
            displayImage = UIImage(cgImage: outputCGImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        }
    }

    private func resetAdjustments() { editingState = EditingState() }

    static func createFilter(for filterType: ImageFilter) -> CIFilter {
        switch filterType {
        case .original: return CIFilter.colorControls()
        case .sepia: return CIFilter.sepiaTone()
        case .noir: return CIFilter.photoEffectNoir()
        case .vintage: return CIFilter.photoEffectProcess()
        case .vivid: return CIFilter.photoEffectInstant()
        case .dramatic: return CIFilter.photoEffectTonal()
        case .mono: return CIFilter.photoEffectMono()
        case .fade: return CIFilter.photoEffectFade()
        }
    }
}

fileprivate struct EditorControlsView: View {
    @Binding var activeTool: ImageEditorView.EditorTool
    @Binding var editingState: EditingState
    let thumbnail: UIImage
    @Binding var showCropView: Bool

    var body: some View {
        VStack {
            if activeTool == .adjust {
                Spacer()
                .onAppear { showCropView = true }
                .onDisappear { if activeTool == .adjust { activeTool = .filters } }
            } else if activeTool == .filters {
                FilterSelectionView(selectedFilter: $editingState.selectedFilter, thumbnail: thumbnail)
            } else {
                VStack {
                    if activeTool == .brightness { SliderControl(value: $editingState.brightness, range: -0.5...0.5, showsValue: true) }
                    else if activeTool == .contrast { SliderControl(value: $editingState.contrast, range: 0.5...1.5, showsValue: true) }
                    else if activeTool == .saturation { SliderControl(value: $editingState.saturation, range: 0...2, showsValue: true) }
                }.padding(.horizontal)
            }
        }
    }
}

fileprivate struct FilterSelectionView: View {
    @Binding var selectedFilter: ImageFilter
    let thumbnail: UIImage

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(ImageFilter.allCases) { filter in
                    VStack {
                        Image(uiImage: generateThumbnail(for: filter))
                            .resizable().frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedFilter == filter ? Color.pink : Color.clear, lineWidth: 2))
                        Text(filter.rawValue).font(.caption).foregroundColor(.white)
                    }.onTapGesture { 
                        selectedFilter = filter
                        HapticFeedback.generate(style: .light)
                    }
                }
            }.padding(.horizontal)
        }
    }

    private func generateThumbnail(for filter: ImageFilter) -> UIImage {
        guard filter != .original else { return thumbnail }
        let ciImage = CIImage(image: thumbnail)
        let ciFilter = ImageEditorView.createFilter(for: filter)
        ciFilter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let outputImage = ciFilter.outputImage else { return thumbnail }
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return thumbnail }
        return UIImage(cgImage: cgImage)
    }
}

fileprivate struct SliderControl: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var showsValue: Bool = false

    @State private var sliderWidth: CGFloat = 0

    private var percentage: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    private var thumbOffset: CGFloat {
        return CGFloat(percentage) * (sliderWidth - 28) // Adjust for thumb width
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 6)

                // Filled track
                Capsule()
                    .fill(Color.pink)
                    .frame(width: thumbOffset + 14, height: 6) // Center the fill

                // Thumb with value inside
                ZStack {
                    Circle()
                        .fill(Color.pink)
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    
                    if showsValue {
                        Text(String(format: "%.0f", percentage * 100))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: thumbOffset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gestureValue in
                            let newPercentage = min(max(0, gestureValue.location.x / geometry.size.width), 1)
                            self.value = range.lowerBound + newPercentage * (range.upperBound - range.lowerBound)
                            HapticFeedback.generate()
                        }
                )
            }
            .frame(height: 30) // Ensure enough vertical space for the thumb
            .onAppear {
                self.sliderWidth = geometry.size.width
            }
        }
        .frame(height: 30) // Set a fixed height for the whole control
    }
}

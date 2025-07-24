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
    @State private var isComparing = false
    @State private var history: [EditingState] = [EditingState()]
    @State private var historyIndex: Int = 0
    @State private var showCropView = false
    private let thumbnail: UIImage

    fileprivate enum EditorTool: String, CaseIterable, Identifiable {
        case crop = "Adjust", filters = "Filters", brightness = "Brightness",
             contrast = "Contrast", saturation = "Saturation"
        var id: String { self.rawValue }
        var systemImageName: String {
            switch self {
            case .crop: return "crop.rotate"
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
        .onChange(of: editingState) { addHistory($0); applyChanges() }
        .sheet(isPresented: $showCropView) {
            CropViewWrapper(image: displayImage, croppedImage: $displayImage)
        }
    }

    private var imageDisplayArea: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: isComparing ? originalImage : displayImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var controlsArea: some View {
        VStack(spacing: 0) {
            Spacer()
            EditorControlsView(activeTool: $activeTool, editingState: $editingState, thumbnail: thumbnail, showCropView: $showCropView)
                .frame(height: 120)
            
            HStack(spacing: 40) {
                Button(action: undo) { Image(systemName: "arrow.uturn.backward") }.disabled(!canUndo)
                Button(action: redo) { Image(systemName: "arrow.uturn.forward") }.disabled(!canRedo)
                Button(action: { isComparing = true }) { Image(systemName: "eye") }
                    .simultaneousGesture(DragGesture(minimumDistance: 0).onEnded { _ in isComparing = false })
            }
            .font(.title).foregroundColor(.white).padding(.vertical)

            toolSelectionBar.padding(.vertical).background(Color.black.opacity(0.5))
            bottomNavBar.padding().background(Color.black)
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
            filter.setValue(currentCIImage, forKey: kCIInputImageKey)
            currentCIImage = filter.outputImage ?? currentCIImage
        }

        currentCIImage = currentCIImage.applyingFilter("CIColorControls", parameters: [
            kCIInputBrightnessKey: editingState.brightness,
            kCIInputContrastKey: editingState.contrast,
            kCIInputSaturationKey: editingState.saturation
        ])

        if let outputCGImage = context.createCGImage(currentCIImage, from: currentCIImage.extent) {
            displayImage = UIImage(cgImage: outputCGImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        }
    }

    private func resetAdjustments() { editingState = EditingState() }
    private var canUndo: Bool { historyIndex > 0 }
    private var canRedo: Bool { historyIndex < history.count - 1 }
    private func addHistory(_ state: EditingState) {
        history.removeSubrange(historyIndex + 1 ..< history.count)
        history.append(state)
        historyIndex = history.count - 1
    }
    private func undo() { if canUndo { historyIndex -= 1; editingState = history[historyIndex] } }
    private func redo() { if canRedo { historyIndex += 1; editingState = history[historyIndex] } }

    static func createFilter(for filterType: ImageFilter) -> CIFilter {
        switch filterType {
        case .original: return CIFilter()
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
            if activeTool == .crop {
                // This view is now just a placeholder that triggers the sheet.
                // We show it when crop is the active tool.
                Spacer()

                Spacer()
                // Automatically trigger the sheet when this tool is selected.
                .onAppear { showCropView = true }
                .onDisappear { if activeTool == .crop { activeTool = .filters } }
            } else if activeTool == .filters {
                FilterSelectionView(selectedFilter: $editingState.selectedFilter, thumbnail: thumbnail)
            } else {
                VStack {
                    if activeTool == .brightness { SliderControl(label: "Brightness", value: $editingState.brightness, range: -0.5...0.5, showsValue: true) }
                    else if activeTool == .contrast { SliderControl(label: "Contrast", value: $editingState.contrast, range: 0.5...1.5, showsValue: true) }
                    else if activeTool == .saturation { SliderControl(label: "Saturation", value: $editingState.saturation, range: 0...2, showsValue: true) }
                }
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
                    }.onTapGesture { selectedFilter = filter }
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
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var showsValue: Bool = false

    var body: some View {
        VStack {
            HStack {
                Text(label).foregroundColor(.white)
                if showsValue {
                    Spacer()
                    Text(String(format: "%.0f", (value - range.lowerBound) * 100 / (range.upperBound - range.lowerBound)))
                        .padding(.horizontal, 8).padding(.vertical, 2).background(Color.pink).cornerRadius(8)
                }
            }
            Slider(value: $value, in: range).accentColor(.pink)
        }
    }
}

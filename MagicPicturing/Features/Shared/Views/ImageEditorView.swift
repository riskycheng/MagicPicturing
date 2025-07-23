import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import AVFoundation

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
    var cropRect: CGRect? = nil
    var selectedFilter: ImageFilter = .original
    var brightness: Double = 0
    var contrast: Double = 1
    var saturation: Double = 1
    var rotation: Double = 0
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
    @State private var imageDisplayAreaSize: CGSize = .zero
    private let thumbnail: UIImage

    fileprivate enum EditorTool: String, CaseIterable, Identifiable {
        case crop = "Crop", filters = "Filters", brightness = "Brightness",
             contrast = "Contrast", saturation = "Saturation", rotation = "Rotation"
        var id: String { self.rawValue }
        var systemImageName: String {
            switch self {
            case .crop: return "crop"
            case .filters: return "wand.and.stars"
            case .brightness: return "sun.max.fill"
            case .contrast: return "circle.lefthalf.filled"
            case .saturation: return "drop.fill"
            case .rotation: return "crop.rotate"
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
    }

    private var imageDisplayArea: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    Image(uiImage: isComparing ? originalImage : displayImage)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }.frame(maxWidth: .infinity, maxHeight: .infinity)

                if self.activeTool == .crop {
                    CropView(cropRect: self.$editingState.cropRect, viewSize: geometry.size)
                }
            }
            .onAppear { self.imageDisplayAreaSize = geometry.size }
            .onChange(of: geometry.size) { self.imageDisplayAreaSize = $0 }
        }
    }

    private var controlsArea: some View {
        VStack(spacing: 0) {
            Spacer()
            EditorControlsView(activeTool: $activeTool, editingState: $editingState, thumbnail: thumbnail)
                .frame(height: 120)
            
            HStack(spacing: 40) {
                Button(action: undo) { Image(systemName: "arrow.uturn.backward") }.disabled(!canUndo)
                Button(action: redo) { Image(systemName: "arrow.uturn.forward") }.disabled(!canRedo)
                Image(systemName: "square.on.square")
                    .gesture(DragGesture(minimumDistance: 0).onChanged { _ in isComparing = true }.onEnded { _ in isComparing = false })
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
                            Image(systemName: tool.systemImageName).font(.title2)
                            Text(tool.rawValue).font(.caption)
                        }.foregroundColor(activeTool == tool ? .pink : .white)
                    }
                }
            }.padding(.horizontal, 20)
        }
    }

    private var bottomNavBar: some View {
        HStack {
            Button(action: onCancel) { Image(systemName: "xmark").font(.title) }
            Spacer()
            Button(action: resetAdjustments) { Text("Reset").font(.title2).bold() }
            Spacer()
            Button(action: applyCropAndFinish) { Image(systemName: "checkmark").font(.title) }
        }.foregroundColor(.white)
    }

    private func applyChanges() {
        let context = CIContext()
        guard let ciImage = CIImage(image: originalImage) else { return }
        var currentCIImage = ciImage
        if editingState.selectedFilter != .original {
            let filter = Self.createFilter(for: editingState.selectedFilter)
            filter.setValue(currentCIImage, forKey: kCIInputImageKey)
            if let output = filter.outputImage { currentCIImage = output }
        }
        let adjustmentFilter = CIFilter.colorControls()
        adjustmentFilter.setValue(currentCIImage, forKey: kCIInputImageKey)
        adjustmentFilter.brightness = Float(editingState.brightness)
        adjustmentFilter.contrast = Float(editingState.contrast)
        adjustmentFilter.saturation = Float(editingState.saturation)
        if let output = adjustmentFilter.outputImage { currentCIImage = output }
        if editingState.rotation != 0 {
            let transform = CGAffineTransform(rotationAngle: CGFloat(editingState.rotation * .pi / 180))
            currentCIImage = currentCIImage.transformed(by: transform)
        }
        if let outputCGImage = context.createCGImage(currentCIImage, from: currentCIImage.extent) {
            displayImage = UIImage(cgImage: outputCGImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        }
    }

    private func resetAdjustments() { editingState = EditingState() }
    private var canUndo: Bool { historyIndex > 0 }
    private var canRedo: Bool { historyIndex < history.count - 1 }
    private func addHistory(_ state: EditingState) {
        if historyIndex < history.count - 1 { history.removeLast(history.count - 1 - historyIndex) }
        history.append(state)
        historyIndex = history.count - 1
    }
    private func undo() { if canUndo { historyIndex -= 1; editingState = history[historyIndex] } }
    private func redo() { if canRedo { historyIndex += 1; editingState = history[historyIndex] } }

    private func applyCropAndFinish() {
        let finalImage = displayImage
        guard let cropRect = editingState.cropRect, activeTool == .crop else {
            onDone(finalImage)
            return
        }

        // Ensure the view size has been measured.
        guard imageDisplayAreaSize != .zero else {
            onDone(finalImage) // Fallback if size is not available
            return
        }

        // Calculate the actual frame of the scaled image within the view.
        // This accounts for .scaledToFit() and the .padding().
        let imageFrameInView = AVMakeRect(aspectRatio: finalImage.size, insideRect: CGRect(origin: .zero, size: imageDisplayAreaSize).insetBy(dx: 16, dy: 16))

        // Calculate the scale factor between the view-rendered image and the actual pixel dimensions.
        let scale = finalImage.size.width / imageFrameInView.width

        // Convert the on-screen crop rectangle to the image's own coordinate space.
        let imageCropRect = CGRect(
            x: (cropRect.origin.x - imageFrameInView.origin.x) * scale,
            y: (cropRect.origin.y - imageFrameInView.origin.y) * scale,
            width: cropRect.width * scale,
            height: cropRect.height * scale
        )

        // Perform the crop using Core Graphics.
        if let cgImage = finalImage.cgImage?.cropping(to: imageCropRect) {
            let croppedImage = UIImage(cgImage: cgImage, scale: finalImage.scale, orientation: finalImage.imageOrientation)
            onDone(croppedImage)
        } else {
            onDone(finalImage) // Fallback if cropping fails
        }
    }

    static func createFilter(for filterType: ImageFilter) -> CIFilter {
        switch filterType {
        case .original: return CIFilter()
        case .sepia: let f = CIFilter.sepiaTone(); f.intensity = 1.0; return f
        case .noir: return CIFilter.photoEffectNoir()
        case .vintage: return CIFilter.photoEffectProcess()
        case .vivid: return CIFilter.photoEffectInstant()
        case .dramatic: return CIFilter.photoEffectTonal()
        case .mono: return CIFilter.photoEffectMono()
        case .fade: return CIFilter.photoEffectFade()
        }
    }
}
fileprivate struct CropView: View {
    @Binding var cropRect: CGRect?
    let viewSize: CGSize

    @State private var internalCropRect: CGRect
    @GestureState private var dragOffset: CGSize = .zero
    @State private var activeCorner: Int? = nil

    init(cropRect: Binding<CGRect?>, viewSize: CGSize) {
        self._cropRect = cropRect
        self.viewSize = viewSize
        self._internalCropRect = State(initialValue: cropRect.wrappedValue ?? CGRect(origin: .zero, size: viewSize))
    }

    var body: some View {
        let current = internalCropRect
        let new = calculateRect(for: current, corner: activeCorner, translation: dragOffset)

        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.4))
                .mask(HoleShape(rect: new).fill(style: FillStyle(eoFill: true)))

            Rectangle()
                .stroke(Color.white, lineWidth: 1)
                .frame(width: new.width, height: new.height)
                .position(x: new.midX, y: new.midY)

            ForEach(0..<4) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .position(cornerPosition(for: i, in: new))
                    .gesture(cornerDragGesture(for: i))
            }
        }
        .onAppear {
            if cropRect == nil {
                cropRect = viewSize.asRect
            }
            internalCropRect = cropRect ?? viewSize.asRect
        }
    }

    private func cornerDragGesture(for index: Int) -> some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onChanged { _ in
                self.activeCorner = index
            }
            .onEnded { value in
                self.activeCorner = nil
                let newRect = calculateRect(for: internalCropRect, corner: index, translation: value.translation)
                self.internalCropRect = newRect
                self.cropRect = newRect
            }
    }

    private func calculateRect(for rect: CGRect, corner: Int?, translation: CGSize) -> CGRect {
        guard let corner = corner else { return rect }
        var newRect = rect
        
        switch corner {
        case 0: // Top-Left
            newRect.origin.x += translation.width
            newRect.origin.y += translation.height
            newRect.size.width -= translation.width
            newRect.size.height -= translation.height
        case 1: // Top-Right
            newRect.origin.y += translation.height
            newRect.size.width += translation.width
            newRect.size.height -= translation.height
        case 2: // Bottom-Left
            newRect.origin.x += translation.width
            newRect.size.width -= translation.width
            newRect.size.height += translation.height
        case 3: // Bottom-Right
            newRect.size.width += translation.width
            newRect.size.height += translation.height
        default: break
        }
        
        if newRect.width < 20 { newRect.size.width = 20 }
        if newRect.height < 20 { newRect.size.height = 20 }
        
        return newRect.standardized
    }

    private func cornerPosition(for i: Int, in r: CGRect) -> CGPoint {
        switch i {
        case 0: return .init(x: r.minX, y: r.minY)
        case 1: return .init(x: r.maxX, y: r.minY)
        case 2: return .init(x: r.minX, y: r.maxY)
        case 3: return .init(x: r.maxX, y: r.maxY)
        default: return .zero
        }
    }
}

fileprivate struct HoleShape: Shape {
    let rect: CGRect
    func path(in rect: CGRect) -> Path { var path = Rectangle().path(in: rect); path.addRect(self.rect); return path }
}

fileprivate extension CGSize {
    var asRect: CGRect {
        CGRect(origin: .zero, size: self)
    }
}

fileprivate struct EditorControlsView: View {
    @Binding var activeTool: ImageEditorView.EditorTool
    @Binding var editingState: EditingState
    let thumbnail: UIImage

    var body: some View {
        VStack {
            if activeTool == .crop {
                Text("Drag corners to resize crop area").font(.caption).foregroundColor(.white)
            } else if activeTool == .filters {
                FilterSelectionView(selectedFilter: $editingState.selectedFilter, thumbnail: thumbnail)
            } else if activeTool == .rotation {
                HStack(spacing: 40) {
                    Button(action: { editingState.rotation -= 90 }) { Image(systemName: "rotate.left.fill").font(.largeTitle) }
                    Button(action: { editingState.rotation += 90 }) { Image(systemName: "rotate.right.fill").font(.largeTitle) }
                }.foregroundColor(.white)
            } else {
                VStack {
                    if activeTool == .brightness { SliderControl(label: "Brightness", value: $editingState.brightness, range: -0.5...0.5, showsValue: true) }
                    else if activeTool == .contrast { SliderControl(label: "Contrast", value: $editingState.contrast, range: 0.5...1.5, showsValue: true) }
                    else if activeTool == .saturation { SliderControl(label: "Saturation", value: $editingState.saturation, range: 0...2, showsValue: true) }
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

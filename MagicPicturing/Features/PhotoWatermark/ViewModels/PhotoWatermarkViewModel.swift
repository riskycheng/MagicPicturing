import SwiftUI
import Combine

class PhotoWatermarkViewModel: ObservableObject {
    
    // Input
    @Published var sourceImage: UIImage?
    @Published var selectedTemplate: WatermarkTemplate = .classic
    
    // Output
    @Published var processedImage: UIImage?
    @Published var watermarkInfo: WatermarkInfo?
    @Published var templates: [WatermarkTemplate] = WatermarkTemplate.allCases
    
    private var cancellables = Set<AnyCancellable>()
    private let exifService = EXIFService()
    
    init() {
        // Combine the publishers for the source image and the selected template.
        // This ensures that whenever either one changes, we re-render the image.
        Publishers.CombineLatest($sourceImage, $selectedTemplate)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .flatMap { optionalImage, template -> Future<(UIImage?, WatermarkInfo?), Never> in
                Future { promise in
                    guard let image = optionalImage else {
                        promise(.success((nil, nil)))
                        return
                    }

                    let info = self.exifService.extractWatermarkInfo(from: image)
                    
                    Task { @MainActor in
                        let watermarkView = template.makeView(image: image, watermarkInfo: info)
                        
                        // Define a reasonable render size.
                        let imageSize = image.size
                        let renderWidth: CGFloat = 1080
                        let aspectRatio = imageSize.height > 0 && imageSize.width > 0 ? imageSize.height / imageSize.width : 1.0
                        let watermarkBarHeight: CGFloat = 80 // Rough approximation
                        let renderSize = CGSize(width: renderWidth, height: renderWidth * aspectRatio + watermarkBarHeight)

                        let finalImage = self.renderViewToImage(view: watermarkView, size: renderSize)
                        promise(.success((finalImage, info)))
                    }
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (image, info) in
                self?.processedImage = image
                if info != nil {
                    self?.watermarkInfo = info
                }
            }
            .store(in: &cancellables)
    }
    
    /// Renders a SwiftUI view to a `UIImage`.
    @MainActor
    private func renderViewToImage<T: View>(view: T, size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(size)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
} 
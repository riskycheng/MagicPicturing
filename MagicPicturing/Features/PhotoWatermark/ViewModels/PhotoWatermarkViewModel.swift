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
    @Published var templatePreviews: [WatermarkTemplate: UIImage] = [:]
    
    var sourceImageAspectRatio: CGFloat {
        guard let size = sourceImage?.size, size.width > 0, size.height > 0 else {
            // Return a default portrait aspect ratio if no image is selected
            return 4.0 / 3.0
        }
        return size.height / size.width
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let exifService = EXIFService()
    
    init() {
        // Main rendering pipeline for the selected image
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
                        let watermarkView = template.makeView(image: image, watermarkInfo: info, isPreview: false)
                        let imageSize = image.size
                        let renderWidth: CGFloat = 1080
                        let aspectRatio = imageSize.height > 0 && imageSize.width > 0 ? imageSize.height / imageSize.width : 1.0
                        let watermarkBarHeight: CGFloat = 80
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
            
        // Pre-rendering pipeline for the template previews
        $sourceImage
            .compactMap { $0 }
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] image in
                self?.preRenderAllTemplates(with: image)
            }
            .store(in: &cancellables)
    }
    
    private func preRenderAllTemplates(with image: UIImage) {
        let previewInfo = exifService.extractWatermarkInfo(from: image)
        var newPreviews: [WatermarkTemplate: UIImage] = [:]
        
        for template in templates {
            Task { @MainActor in
                let previewView = template.makeView(image: image, watermarkInfo: previewInfo, isPreview: true)
                let previewSize = CGSize(width: 120, height: 120 * self.sourceImageAspectRatio)
                if let previewImage = self.renderViewToImage(view: previewView, size: previewSize) {
                    newPreviews[template] = previewImage
                    // Update the main dictionary on the main thread once all previews are potentially ready
                    DispatchQueue.main.async {
                        self.templatePreviews = newPreviews
                    }
                }
            }
        }
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
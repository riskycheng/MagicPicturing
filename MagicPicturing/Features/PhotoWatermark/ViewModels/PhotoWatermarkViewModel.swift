import SwiftUI
import Combine

class PhotoWatermarkViewModel: ObservableObject {
    
    // MARK: - Input
    @Published var sourceImage: UIImage? {
        didSet { processSourceImageUpdate() }
    }
    @Published var sourceImageData: Data? {
        didSet { processSourceImageUpdate() }
    }
    @Published var selectedTemplate: WatermarkTemplate = .classic
    
    // MARK: - Output
    @Published var watermarkInfo: WatermarkInfo?
    @Published var templates: [WatermarkTemplate] = WatermarkTemplate.allCases
    @Published var templatePreviews: [WatermarkTemplate: UIImage] = [:]

    var sourceImageAspectRatio: CGFloat {
        guard let size = sourceImage?.size, size.width > 0, size.height > 0 else {
            return 4.0 / 3.0
        }
        return size.width / size.height
    }

    // MARK: - Services
    private let exifService = EXIFService()
    
    // MARK: - Public Methods
    func export() async -> UIImage? {
        guard let sourceImage, let watermarkInfo else { return nil }
        
        let renderWidth: CGFloat = sourceImage.size.width
        let watermarkBar = selectedTemplate.makeView(watermarkInfo: watermarkInfo, width: renderWidth)
        
        let finalRenderView = VStack(spacing: 0) {
            Image(uiImage: sourceImage)
                .resizable()
                .scaledToFit()
            watermarkBar
        }
        
        return await renderViewToImage(view: finalRenderView, size: sourceImage.size)
    }
    
    // MARK: - Private Methods
    private func processSourceImageUpdate() {
        guard let data = sourceImageData, sourceImage != nil else { return }
        watermarkInfo = exifService.extractWatermarkInfo(from: data)
        generateAllTemplatePreviews()
    }

    private func generateAllTemplatePreviews() {
        guard let sourceImage, let watermarkInfo else { return }
        
        Task.detached(priority: .userInitiated) {
            var newPreviews: [WatermarkTemplate: UIImage] = [:]
            let previewSize = CGSize(width: 120, height: 120)

            for template in self.templates {
                let watermarkBar = template.makeView(watermarkInfo: watermarkInfo, width: previewSize.width)
                let previewView = Image(uiImage: sourceImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: previewSize.width, height: previewSize.height)
                    .clipped()
                    .overlay(
                        VStack {
                            Spacer()
                            watermarkBar
                        }
                    )
                
                if let previewImage = await self.renderViewToImage(view: previewView, size: previewSize) {
                    newPreviews[template] = previewImage
                }
            }
            
            await MainActor.run {
                self.templatePreviews = newPreviews
            }
        }
    }
    
    @MainActor
    private func renderViewToImage<T: View>(view: T, size: CGSize) async -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = ProposedViewSize(size)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
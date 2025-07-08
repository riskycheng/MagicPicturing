import SwiftUI
import Combine

class PhotoWatermarkViewModel: ObservableObject {
    
    // Input
    @Published var sourceImage: UIImage? {
        didSet {
            updateSourceImageDerivedData()
            generateAllTemplatePreviews()
        }
    }
    @Published var selectedTemplate: WatermarkTemplate = .classic
    
    // Output
    func export() async -> UIImage? {
        guard let sourceImage, let watermarkInfo else { return nil }
        let renderWidth: CGFloat = 1080
        let watermarkView = selectedTemplate.makeView(image: sourceImage, watermarkInfo: watermarkInfo, isPreview: false, width: renderWidth)
        return await renderViewToImage(view: watermarkView, proposedSize: .unspecified)
    }
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
    
    private let exifService = EXIFService()
    
    private func updateSourceImageDerivedData() {
        guard let sourceImage else { return }
        watermarkInfo = exifService.extractWatermarkInfo(from: sourceImage)
    }

    private func generateAllTemplatePreviews() {
        guard let sourceImage, let watermarkInfo else { return }
        
        Task.detached(priority: .userInitiated) {
            var newPreviews: [WatermarkTemplate: UIImage] = [:]
            let previewSize = ProposedViewSize.unspecified

            for template in self.templates {
                let previewView = template.makeView(image: sourceImage, watermarkInfo: watermarkInfo, isPreview: true, width: 120)
                if let previewImage = await self.renderViewToImage(view: previewView, proposedSize: previewSize) {
                    newPreviews[template] = previewImage
                }
            }
            
            await MainActor.run {
                self.templatePreviews = newPreviews
            }
        }
    }
    
    /// Renders a SwiftUI view to a `UIImage`.
    @MainActor
    private func renderViewToImage<T: View>(view: T, size: CGSize) async -> UIImage? {
        await renderViewToImage(view: view, proposedSize: ProposedViewSize(size))
    }

    @MainActor
    private func renderViewToImage<T: View>(view: T, proposedSize: ProposedViewSize) async -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.proposedSize = proposedSize
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
} 
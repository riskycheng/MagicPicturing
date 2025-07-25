import SwiftUI
import Photos
import Combine
import CoreLocation

class PhotoWatermarkViewModel: ObservableObject {
    
    // MARK: - Input
    @Published var sourceImage: UIImage?
    @Published var sourceImageData: Data?
    @Published var selectedTemplate: WatermarkTemplate = .classic
    
    // MARK: - Output
    @Published var watermarkInfo: WatermarkInfo?
    @Published var templates: [WatermarkTemplate] = [.classic, .modern, .minimalist, .tech, .film]


    var sourceImageAspectRatio: CGFloat {
        guard let size = sourceImage?.size, size.width > 0, size.height > 0 else {
            return 4.0 / 3.0
        }
        return size.width / size.height
    }

    // MARK: - Services
    private let exifService = EXIFService()

    // MARK: - Initializers
    init() {
        // Default initializer for standard flow where the user selects an image.
    }

    convenience init(initialImage: UIImage, asset: PHAsset) {
        self.init()
        self.sourceImage = initialImage
        self.sourceImageData = initialImage.jpegData(compressionQuality: 1.0)
        self.extractWatermarkInfo(from: asset)
    }
    
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
    
    func exportImage(withWatermark: Bool) -> UIImage? {
        // This function will require a more complex implementation to render the watermark
        // onto the image using CoreGraphics or a similar framework.
        return sourceImage
    }
    
    // MARK: - Private Methods
    private func extractWatermarkInfo(from asset: PHAsset) {
        let creationDate = asset.creationDate
        let location = asset.location

        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true

        asset.requestContentEditingInput(with: options) { (input, info) in
            guard let input = input, let fullImage = CIImage(contentsOf: input.fullSizeImageURL!) else { return }

            let properties = fullImage.properties
            let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
            let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]

            // Extract basic EXIF info
            let cameraMake = tiff?["Make"] as? String
            let cameraModel = tiff?["Model"] as? String
            let lensModel = exif?["LensModel"] as? String
            let focalLength = (exif?["FocalLength"] as? Double).map { String(format: "%.1fmm", $0) }
            let aperture = (exif?["FNumber"] as? Double).map { String(format: "f/%.1f", $0) }
            let shutterSpeed = (exif?["ExposureTime"] as? Double).map { "1/\(Int(1.0/$0))s" }
            let iso = (exif?["ISOSpeedRatings"] as? [Int])?.first.map { "ISO \($0)" }
            
            // Format date
            let dateString: String?
            if let date = creationDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                dateString = formatter.string(from: date)
            } else {
                dateString = nil
            }

            // Reverse geocode location (this is async)
            let geocoder = CLGeocoder()
            if let location = location {
                geocoder.geocodeAddressString(location.description) { (placemarks, error) in
                    let locationString = placemarks?.first?.locality
                    self.setWatermarkInfo(
                        cameraMake: cameraMake, cameraModel: cameraModel, lensModel: lensModel,
                        focalLength: focalLength, aperture: aperture, shutterSpeed: shutterSpeed, iso: iso,
                        location: locationString, creationDate: dateString
                    )
                }
            } else {
                self.setWatermarkInfo(
                    cameraMake: cameraMake, cameraModel: cameraModel, lensModel: lensModel,
                    focalLength: focalLength, aperture: aperture, shutterSpeed: shutterSpeed, iso: iso,
                    location: nil, creationDate: dateString
                )
            }
        }
    }

    private func setWatermarkInfo(cameraMake: String?, cameraModel: String?, lensModel: String?, focalLength: String?, aperture: String?, shutterSpeed: String?, iso: String?, location: String?, creationDate: String?) {
        DispatchQueue.main.async {
            self.watermarkInfo = WatermarkInfo(
                cameraMake: cameraMake, cameraModel: cameraModel, lensModel: lensModel,
                focalLength: focalLength, aperture: aperture, shutterSpeed: shutterSpeed, iso: iso,
                location: location, creationDate: creationDate
            )
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
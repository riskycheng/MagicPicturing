# MagicPicturing

MagicPicturing is a modern iOS application designed for applying elegant watermarks to your photos. The app is built entirely in SwiftUI and leverages the latest iOS features to provide a smooth and intuitive user experience.

## Core Features

### 1. Photo Watermarking

The watermarking feature allows you to apply custom, template-based watermarks to your photos. It has been carefully designed to handle a wide variety of image sizes and aspect ratios.

- **Intelligent Scaling**: Images are scaled to fit the screen's width. For tall, portrait-style photos, the image is vertically centered and cropped to ensure it fits perfectly without distortion.
- **Vertically Centered Layout**: The entire composition, including the image and the watermark, is vertically centered for a balanced and professional look.
- **High-Quality Export**: When saving, the app uses iOS 16's `ImageRenderer` to produce a high-resolution image that preserves the original quality and scale, eliminating any blurriness.

## Technical Stack

- **UI Framework**: SwiftUI
- **Dependency Management**: Swift Package Manager
- **Core Libraries**:
    - [AnyImageKit](https://github.com/AnyImage/AnyImageKit): A powerful and elegant image picker.
    - [TOCropViewController](https://github.com/TimOliver/TOCropViewController): For advanced image cropping functionality.
    - [Kingfisher](https://github.com/onevcat/Kingfisher): For efficient image downloading and caching.
    - [SnapKit](https://github.com/SnapKit/SnapKit): A DSL for creating Auto Layout constraints.

## Getting Started

1.  **Clone the Repository**: `git clone [your-repository-url]`
2.  **Open in Xcode**: Open the `MagicPicturing.xcodeproj` file in Xcode.
3.  **Resolve Packages**: Xcode will automatically resolve the Swift Package dependencies.
4.  **Build and Run**: Build the project and run it on a simulator or a physical device.


## 2. Architecture

The project follows the **Model-View-ViewModel (MVVM)** design pattern. This separation of concerns makes the codebase cleaner, more scalable, and easier to test.

- **Model**: Represents the data and business logic of the application (e.g., `CollageLayout`, `WatermarkInfo`).
- **View**: The UI of the application, built with SwiftUI. Views are responsible for displaying data from the ViewModel and capturing user input (e.g., `PhotoCollageView`, `PhotoWatermarkEntryView`).
- **ViewModel**: Acts as a bridge between the Model and the View. It holds the application's state and presentation logic, exposing data to the View through `@Published` properties (e.g., `PhotoCollageViewModel`, `PhotoWatermarkViewModel`).

## 3. Module Breakdown

The application is divided into several feature modules, located in `MagicPicturing/Features/`.

### 3.1. PhotoWatermark

- **Purpose**: Enables users to add professional-grade watermarks to their photos.
- **Available Templates**: `Classic`, `Modern`, `Minimalist`, `Tech`, `Film`.
- **Key Features**:
  - **Dynamic Layouts**: Each template intelligently adapts to display key EXIF data like camera model, lens, and shot details.
  - **Consistent Design**: All templates share a standardized height and clean aesthetic for a cohesive user experience.
  - **Interactive Selection**: Haptic feedback provides a tactile response when switching between templates.

### 3.2. Shared

- **Purpose**: Contains reusable components and utilities shared across all feature modules, including the powerful `ImageEditorView`.

## 4. Recent Progress (July 2025)

- **Watermark Template Refinement**:
  - Standardized all watermark templates to a consistent height for a uniform look and feel.
  - Overhauled the `Tech` template with a clean, high-contrast design (white background, black text), a bold monospaced font, and removed decorative elements.
  - Implemented intelligent text display for both `Tech` and `Classic` templates to ensure key camera details are shown concisely on a single line without font scaling.

- **Enhanced User Experience**:
  - Added subtle haptic feedback when switching between templates, making the UI more interactive and responsive.

- **Codebase Cleanup**:
  - Identified and removed four unused watermark template files (`Artistic`, `Magazine`, `Natural`, `Vintage`), streamlining the project and improving maintainability.

## 5. Future Work

- **User-Customizable Templates**: Allow users to choose which metadata to display or adjust font sizes and colors.
- **Export Quality Settings**: Provide options to select the resolution and compression quality for exported images.
- **Batch Processing**: Enable users to apply the same watermark to multiple images at once.
- **Localization**: Translate the app into multiple languages to reach a wider audience.

## 6. How to Contribute

- **Create a new branch** for each new feature or bug fix.
- **Follow the MVVM architecture** when adding new functionality.
- **Place reusable components** in the `Shared` module.
- **Write clear and concise commit messages**.
- **Submit a pull request** for review.

Happy coding!

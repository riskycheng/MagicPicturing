# MagicPictures Development Guide

Welcome to the MagicPictures development team! This guide provides a comprehensive overview of the project structure, architecture, and development workflow. Its purpose is to help you get up to speed quickly and contribute effectively.

## 1. Project Overview

MagicPictures is a SwiftUI-based application for iOS that provides users with a suite of powerful and easy-to-use photo editing tools. The app is designed with a modular architecture, allowing for independent development and testing of each feature.

**Core Features:**
- **Photo Collage**: Create stunning collages from your photos.
- **Photo Watermark**: Add custom watermarks to your images.
- **3D Grid Effect**: Apply a unique 3D grid effect to your pictures.

## 2. Architecture

The project follows the **Model-View-ViewModel (MVVM)** design pattern. This separation of concerns makes the codebase cleaner, more scalable, and easier to test.

- **Model**: Represents the data and business logic of the application (e.g., `CollageLayout`, `WatermarkInfo`).
- **View**: The UI of the application, built with SwiftUI. Views are responsible for displaying data from the ViewModel and capturing user input (e.g., `PhotoCollageView`, `PhotoWatermarkEntryView`).
- **ViewModel**: Acts as a bridge between the Model and the View. It holds the application's state and presentation logic, exposing data to the View through `@Published` properties (e.g., `PhotoCollageViewModel`, `PhotoWatermarkViewModel`).

## 3. Module Breakdown

The application is divided into several feature modules, located in `MagicPicturing/Features/`. Each module is self-contained, with its own Models, Views, and ViewModels.

### 3.1. PhotoCollage

- **Purpose**: Allows users to create photo collages.
- **Location**: `MagicPicturing/Features/PhotoCollage`
- **Structure**:
  - `Models/`: Data structures for collage layouts and items.
  - `Services/`: Logic for generating collage images.
  - `ViewModels/`: State and logic for the collage creation process.
  - `Views/`: SwiftUI views for the collage feature.

### 3.2. PhotoWatermark

- **Purpose**: Enables users to add watermarks to their photos.
- **Location**: `MagicPicturing/Features/PhotoWatermark`
- **Structure**:
  - `Models/`: Data models for watermark templates and information.
  - `Services/`: EXIF data handling and other utility services.
  - `ViewModels/`: Manages the state for the watermarking flow.
  - `Views/`: UI for selecting images, choosing watermark styles, and previewing the result.
  - `README_WATERMARK_STYLES.md`: A document detailing the different watermark styles available.

### 3.3. ThreeDGrid

- **Purpose**: Applies a 3D grid effect to images.
- **Location**: `MagicPicturing/Features/ThreeDGrid`
- **Structure**:
  - `Models/`: Data models for the 3D grid.
  - `Services/`: Business logic for applying the 3D effect.
  - `Views/`: SwiftUI views for the 3D grid feature.

### 3.4. Shared

- **Purpose**: Contains reusable components and utilities shared across all feature modules.
- **Location**: `MagicPicturing/Features/Shared`
- **Structure**:
  - `Extensions/`: Swift extensions for standard types.
  - `Services/`: Shared services like image caching.
  - `Utils/`: Utility functions and helpers.
  - `Views/`: Reusable SwiftUI views like `ImagePickerView` and `ImageGalleryView`.

## 4. Getting Started

1.  **Clone the repository**.
2.  **Open `MagicPicturing.xcodeproj` in Xcode**.
3.  **Select a simulator or a physical device**.
4.  **Build and run the project (Cmd+R)**.

## 5. How to Contribute

- **Create a new branch** for each new feature or bug fix.
- **Follow the MVVM architecture** when adding new functionality.
- **Place reusable components** in the `Shared` module.
- **Write clear and concise commit messages**.
- **Submit a pull request** for review.

Happy coding!

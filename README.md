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

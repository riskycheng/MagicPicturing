# MagicPictures App

MagicPictures is a cross-platform photo editing application for iOS and macOS that allows users to apply filters, AI-based editing, templates, and adjustments to their photos.

## Features

- 3D card interface for browsing photos
- Photo editing with filters, AI removal, templates, and adjustments
- Gallery view for managing photo collections
- Cross-platform compatibility between iOS and macOS
- Dark mode support
- Localization support

## Project Structure

The project follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Data structures and business logic
- **Views**: User interface components
- **ViewModels**: Manages the state and behavior of the views
- **Utilities**: Helper functions and cross-platform compatibility

## Cross-Platform Compatibility

The app uses a centralized `PlatformTypes.swift` file to define platform-specific types and behaviors:

- `PlatformImage` type alias (UIImage for iOS, NSImage for macOS)
- `PlatformColor` type alias
- `CGRectCorner` enum for macOS compatibility
- `RoundedCorner` shape implementation for both platforms
- View extension for cornerRadius with platform-specific implementations

## Getting Started

1. Open the Xcode project
2. Build and run the application on a simulator or device
3. Explore the app's features

## Implementation Notes

- The app uses SwiftUI for the user interface
- Environment objects are used for sharing data across views
- Conditional compilation is used for platform-specific code
- The app follows Apple's Human Interface Guidelines

## Requirements

- iOS 15.0+ / macOS 12.0+
- Xcode 13.0+
- Swift 5.5+

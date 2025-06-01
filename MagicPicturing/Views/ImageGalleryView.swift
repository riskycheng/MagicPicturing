import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ImageGalleryView: View {
    let initialIndex: Int
    let images: [PlatformImage]
    let onDelete: (Int) -> Void
    let onDismiss: () -> Void
    
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isZoomed: Bool = false
    
    init(initialIndex: Int, images: [PlatformImage], onDelete: @escaping (Int) -> Void, onDismiss: @escaping () -> Void) {
        self.initialIndex = initialIndex
        self.images = images
        self.onDelete = onDelete
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color - light gray to match the second image style
                Color(white: 0.95).edgesIgnoringSafeArea(.all)
                
                // Black bars for letterboxing effect
                VStack {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: geometry.size.height * 0.08)
                    Spacer()
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: geometry.size.height * 0.08)
                }
                .edgesIgnoringSafeArea(.all)
                
                // Main content
                VStack(spacing: 0) {
                    // Header with back button, image count, and delete button
                    HStack {
                        // Back button
                        Button(action: onDismiss) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        
                        Spacer()
                        
                        // Image count indicator
                        Text("\(currentIndex + 1)/\(images.count)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Delete button
                        Button(action: {
                            onDelete(currentIndex)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(Color(white: 0.95))
                    
                    // Image pager
                    TabView(selection: $currentIndex) {
                        ForEach(0..<images.count, id: \.self) { index in
                            ZoomableImageView(
                                image: images[index],
                                scale: index == currentIndex ? $scale : .constant(1.0),
                                offset: index == currentIndex ? $offset : .constant(.zero),
                                isZoomed: index == currentIndex ? $isZoomed : .constant(false),
                                resetZoom: {
                                    withAnimation {
                                        scale = 1.0
                                        offset = .zero
                                        isZoomed = false
                                    }
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .onChange(of: currentIndex) { _, _ in
                        // Reset zoom when changing images
                        withAnimation {
                            scale = 1.0
                            offset = .zero
                            isZoomed = false
                        }
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

struct ZoomableImageView: View {
    let image: PlatformImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var isZoomed: Bool
    let resetZoom: () -> Void
    
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            #if canImport(UIKit)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            
                            // Limit minimum scale to 1.0 and maximum to 4.0
                            let newScale = min(max(scale * delta, 1.0), 4.0)
                            
                            // Only set isZoomed if we're actually zoomed in
                            isZoomed = newScale > 1.0
                            
                            scale = newScale
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            
                            // If scale is close to 1, snap back to 1
                            if scale < 1.1 {
                                withAnimation {
                                    scale = 1.0
                                    offset = .zero
                                    isZoomed = false
                                }
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow dragging if zoomed in
                            if scale > 1.0 {
                                let newOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                
                                // Calculate bounds for dragging based on zoom level
                                let maxX = (geometry.size.width * (scale - 1)) / 2
                                let maxY = (geometry.size.height * (scale - 1)) / 2
                                
                                // Constrain offset within bounds
                                offset = CGSize(
                                    width: min(max(newOffset.width, -maxX), maxX),
                                    height: min(max(newOffset.height, -maxY), maxY)
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                            
                            // If scale is 1, reset offset
                            if scale <= 1.0 {
                                withAnimation {
                                    offset = .zero
                                }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    // Double tap to zoom in/out
                    withAnimation {
                        if scale > 1.0 {
                            // Reset zoom
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                            isZoomed = false
                        } else {
                            // Zoom to 2x
                            scale = 2.0
                            isZoomed = true
                        }
                    }
                }
            #elseif canImport(AppKit)
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
            #endif
        }
        .contentShape(Rectangle()) // Ensures the entire area is tappable
    }
}

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
    @State private var offset: CGSize = .zero
    @State private var isZoomed: Bool = false
    @State private var headerHeight: CGFloat = 44
    @State private var refreshID = UUID() // Used to force refresh gesture handlers
    
    init(initialIndex: Int, images: [PlatformImage], onDelete: @escaping (Int) -> Void, onDismiss: @escaping () -> Void) {
        self.initialIndex = initialIndex
        self.images = images
        self.onDelete = onDelete
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with white background
                HStack {
                    // Back button
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
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
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                .background(GeometryReader { headerGeometry -> Color in
                    DispatchQueue.main.async {
                        self.headerHeight = headerGeometry.size.height
                    }
                    return Color.clear
                })
                
                // Image area with black background
                ZStack {
                    // Black background for the entire image area
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    // Image pager with single-finger swipe
                    TabView(selection: $currentIndex) {
                        ForEach(0..<images.count, id: \.self) { index in
                            // Full screen transparent overlay to capture swipes anywhere
                            GeometryReader { fullScreenGeometry in
                                Color.clear // Transparent full-screen area to capture swipes
                                    .contentShape(Rectangle()) // Make the entire area tappable
                                    .overlay(
                                        ZoomableImageView(
                                            image: images[index],
                                            scale: $scale,
                                            offset: $offset,
                                            isZoomed: $isZoomed,
                                            isActive: index == currentIndex,
                                            screenSize: geometry.size,
                                            headerHeight: headerHeight,
                                            refreshID: refreshID, // Pass the refresh ID
                                            resetZoom: {
                                                withAnimation {
                                                    scale = 1.0
                                                    offset = .zero
                                                    isZoomed = false
                                                }
                                            }
                                        )
                                    )
                            }
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
                            // Generate new UUID to force refresh of gesture handlers
                            refreshID = UUID()
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct ZoomableImageView: View {
    let image: PlatformImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var isZoomed: Bool
    let isActive: Bool // Whether this view is currently visible
    let screenSize: CGSize
    let headerHeight: CGFloat
    let refreshID: UUID // Used to force refresh gesture handlers
    let resetZoom: () -> Void
    
    // For gesture handling
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var imageSize: CGSize = .zero
    @State private var fingerCount: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            #if canImport(UIKit)
            ZStack {
                // Black background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Image with preserved aspect ratio
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .background(GeometryReader { imageGeometry -> Color in
                        DispatchQueue.main.async {
                            self.imageSize = imageGeometry.size
                        }
                        return Color.clear
                    })
                    // Use a transparent overlay to capture all gestures
                    .overlay(
                        // This transparent view captures all gestures and handles them appropriately
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            // Add gesture recognizers
                            .gesture(
                                // Detect number of fingers with DragGesture
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        // This is handled by the UIViewRepresentable below
                                    }
                            )
                    )
                    // Add a UIViewRepresentable to handle the gestures natively
                    .overlay(
                        Group {
                            if isActive { // Only add gesture handlers when view is active
                                GestureHandlerView(scale: $scale, offset: $offset, isZoomed: $isZoomed, lastScale: $lastScale, lastOffset: $lastOffset, imageSize: imageSize, refreshID: refreshID)
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
            }
            #elseif canImport(AppKit)
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .background(Color.black)
            #endif
        }
    }
}

#if canImport(UIKit)
// UIViewRepresentable to handle gestures natively
struct GestureHandlerView: UIViewRepresentable {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var isZoomed: Bool
    @Binding var lastScale: CGFloat
    @Binding var lastOffset: CGSize
    let imageSize: CGSize
    let refreshID: UUID // Used to force refresh gesture handlers
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        // Add pinch gesture recognizer for zooming
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinchGesture.delegate = context.coordinator
        view.addGestureRecognizer(pinchGesture)
        
        // Add pan gesture recognizer for panning when zoomed
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        view.addGestureRecognizer(panGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // When refreshID changes, we need to reinitialize our gesture recognizers
        // This ensures they work properly after swiping to a new image
        if context.coordinator.lastRefreshID != refreshID {
            context.coordinator.lastRefreshID = refreshID
            
            // Remove all existing gesture recognizers
            uiView.gestureRecognizers?.forEach { uiView.removeGestureRecognizer($0) }
            
            // Add fresh gesture recognizers
            let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
            pinchGesture.delegate = context.coordinator
            uiView.addGestureRecognizer(pinchGesture)
            
            let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
            panGesture.delegate = context.coordinator
            uiView.addGestureRecognizer(panGesture)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: GestureHandlerView
        var lastRefreshID: UUID
        var touchStartedOnImage = false
        
        init(_ parent: GestureHandlerView) {
            self.parent = parent
            self.lastRefreshID = parent.refreshID
        }
        
        // Handle pinch gesture for zooming
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.numberOfTouches >= 2 { // Ensure it's a two-finger pinch
                switch gesture.state {
                case .began:
                    parent.lastScale = 1.0
                case .changed:
                    let delta = gesture.scale / parent.lastScale
                    parent.lastScale = gesture.scale
                    
                    // Limit scale between 1.0 and 4.0
                    let newScale = min(max(parent.scale * delta, 1.0), 4.0)
                    parent.scale = newScale
                    parent.isZoomed = newScale > 1.0
                case .ended, .cancelled:
                    parent.lastScale = 1.0
                    
                    // Snap back to 1.0 if close
                    if parent.scale < 1.1 {
                        withAnimation {
                            parent.scale = 1.0
                            parent.offset = .zero
                            parent.isZoomed = false
                        }
                    }
                default:
                    break
                }
            }
        }
        
        // Handle pan gesture for panning when zoomed
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began:
                // Check if we're zoomed in - if so, we'll handle the pan
                if parent.scale > 1.0 {
                    touchStartedOnImage = true
                } else {
                    // Not zoomed, let TabView handle it
                    touchStartedOnImage = false
                }
                
            case .changed:
                // Only allow panning when zoomed in
                if parent.scale > 1.0 && touchStartedOnImage {
                    let translation = gesture.translation(in: gesture.view)
                    let newOffset = CGSize(
                        width: parent.lastOffset.width + translation.x,
                        height: parent.lastOffset.height + translation.y
                    )
                    
                    // Calculate bounds based on zoom level
                    let maxX = (parent.imageSize.width * (parent.scale - 1)) / 2
                    let maxY = (parent.imageSize.height * (parent.scale - 1)) / 2
                    
                    // Constrain offset within bounds
                    parent.offset = CGSize(
                        width: min(max(newOffset.width, -maxX), maxX),
                        height: min(max(newOffset.height, -maxY), maxY)
                    )
                    
                    // Reset translation to avoid accumulation
                    gesture.setTranslation(.zero, in: gesture.view)
                }
                
            case .ended, .cancelled:
                if parent.scale > 1.0 && touchStartedOnImage {
                    parent.lastOffset = parent.offset
                }
                touchStartedOnImage = false
                
            default:
                break
            }
        }
        
        // Implement UIGestureRecognizerDelegate methods
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Always allow two-finger pinch and pan to work together
            if (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer) ||
               (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) {
                return true
            }
            
            // If we're zoomed in, prioritize our pan gesture over TabView's swipe
            if parent.scale > 1.0 && (gestureRecognizer is UIPanGestureRecognizer || otherGestureRecognizer is UIPanGestureRecognizer) {
                return false
            }
            
            // If we're not zoomed, let TabView handle swipes (even on the image)
            return true
        }
    }
}
#endif

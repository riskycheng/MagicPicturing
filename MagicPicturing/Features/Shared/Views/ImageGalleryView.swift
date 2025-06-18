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
    var onEdit: ((Int, PlatformImage) -> Void)? = nil
    
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var isZoomed: Bool = false
    @State private var headerHeight: CGFloat = 44
    @State private var refreshID = UUID()
    @State private var showHeader: Bool = true
    @State private var doubleTapAnchor: CGPoint? = nil
    @State private var dragProgress: CGFloat = 0 // 新增：用于跟踪下拉进度
    @State private var isEditing: Bool = false // 新增：用于显示编辑视图
    
    init(initialIndex: Int, images: [PlatformImage], onDelete: @escaping (Int) -> Void, onDismiss: @escaping () -> Void, onEdit: ((Int, PlatformImage) -> Void)? = nil) {
        self.initialIndex = initialIndex
        self.images = images
        self.onDelete = onDelete
        self.onDismiss = onDismiss
        self.onEdit = onEdit
        _currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色，随拖动进度变化
                Color.black.opacity(1 - dragProgress)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    if showHeader {
                        // Header with white background
                        HStack {
                            Button(action: onDismiss) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text("\(currentIndex + 1)/\(images.count)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Edit button
                            if let onEdit = onEdit {
                                Button(action: {
                                    onEdit(currentIndex, images[currentIndex])
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.trailing, 16) // Spacing between buttons
                            }
                            
                            Button(action: {
                                onDelete(currentIndex)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.5))
                        .background(GeometryReader { headerGeometry -> Color in
                            DispatchQueue.main.async {
                                self.headerHeight = headerGeometry.size.height
                            }
                            return Color.clear
                        })
                    }
                    
                    // Image area
                    TabView(selection: $currentIndex) {
                        ForEach(0..<images.count, id: \.self) { index in
                            ZoomableImageView(
                                image: images[index],
                                scale: $scale,
                                offset: $offset,
                                isZoomed: $isZoomed,
                                isActive: index == currentIndex,
                                screenSize: geometry.size,
                                headerHeight: headerHeight,
                                refreshID: refreshID,
                                dragProgress: $dragProgress,
                                resetZoom: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        scale = 1.0
                                        offset = .zero
                                        isZoomed = false
                                    }
                                },
                                onSingleTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showHeader.toggle()
                                    }
                                },
                                onDismissByDrag: { onDismiss() }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .onChange(of: currentIndex) { _, _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            scale = 1.0
                            offset = .zero
                            isZoomed = false
                            refreshID = UUID()
                        }
                    }
                }
            }
        }
    }
}

struct ZoomableImageUIKitView: UIViewRepresentable {
    let image: UIImage
    var onSingleTap: (() -> Void)?
    var onDismissByDrag: (() -> Void)?
    @Binding var dragProgress: CGFloat
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .clear
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        
        // 单击手势
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(singleTap)
        
        // 双击手势
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
        singleTap.require(toFail: doubleTap)
        
        // 下拉关闭手势
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        imageView.addGestureRecognizer(pan)
        
        context.coordinator.onSingleTap = onSingleTap
        context.coordinator.onDismissByDrag = onDismissByDrag
        context.coordinator.scrollView = scrollView
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // nothing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?
        var onSingleTap: (() -> Void)?
        var onDismissByDrag: (() -> Void)?
        private var dragStartY: CGFloat = 0
        private var dragging = false
        private var parent: ZoomableImageUIKitView
        
        init(_ parent: ZoomableImageUIKitView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
        
        // 保证图片始终居中
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView = imageView else { return }
            let boundsSize = scrollView.bounds.size
            var frameToCenter = imageView.frame
            // 水平方向
            if frameToCenter.size.width < boundsSize.width {
                frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
            } else {
                frameToCenter.origin.x = 0
            }
            // 垂直方向
            if frameToCenter.size.height < boundsSize.height {
                frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
            } else {
                frameToCenter.origin.y = 0
            }
            imageView.frame = frameToCenter
        }
        
        // 缩放结束后自动回弹到1并居中
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            if scale < 1.0 {
                UIView.animate(withDuration: 0.25, animations: {
                    scrollView.setZoomScale(1.0, animated: false)
                }) { _ in
                    self.scrollViewDidZoom(scrollView)
                }
            }
        }
        
        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            onSingleTap?()
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }
            
            if scrollView.zoomScale > 1.0 {
                // 如果已经放大，则缩小
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                // 获取双击位置
                let point = gesture.location(in: imageView)
                // 计算放大区域
                let rect = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
                scrollView.zoom(to: rect, animated: true)
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let imageView = imageView, let scrollView = scrollView else { return }
            
            // 只在未缩放时允许下拉关闭
            if scrollView.zoomScale > 1.0 { return }
            
            let translation = gesture.translation(in: imageView)
            
            switch gesture.state {
            case .began:
                dragStartY = imageView.center.y
                dragging = true
            case .changed:
                if translation.y > 0 {
                    // 计算拖动进度
                    let progress = min(translation.y / 300, 1.0)
                    parent.dragProgress = progress
                    
                    // 应用缩放和位移
                    let scale = 1.0 - (progress * 0.2)
                    imageView.transform = CGAffineTransform(translationX: 0, y: translation.y)
                        .scaledBy(x: scale, y: scale)
                }
            case .ended, .cancelled:
                dragging = false
                if translation.y > 100 {
                    onDismissByDrag?()
                } else {
                    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                        imageView.transform = .identity
                        self.parent.dragProgress = 0
                    }
                }
            default:
                break
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

struct ZoomableImageView: View {
    let image: PlatformImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var isZoomed: Bool
    let isActive: Bool
    let screenSize: CGSize
    let headerHeight: CGFloat
    let refreshID: UUID
    @Binding var dragProgress: CGFloat
    let resetZoom: () -> Void
    var onSingleTap: (() -> Void)?
    var onDismissByDrag: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
#if canImport(UIKit)
            ZStack {
                Color.clear
                ZoomableImageUIKitView(
                    image: image,
                    onSingleTap: onSingleTap,
                    onDismissByDrag: onDismissByDrag,
                    dragProgress: $dragProgress
                )
            }
#else
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
        var baseScale: CGFloat = 1.0 // 记录pinch开始时的缩放比例
        
        init(_ parent: GestureHandlerView) {
            self.parent = parent
            self.lastRefreshID = parent.refreshID
        }
        
        // Handle pinch gesture for zooming
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.numberOfTouches >= 2 { // Ensure it's a two-finger pinch
                switch gesture.state {
                case .began:
                    // 记录当前缩放比例为基准
                    baseScale = parent.scale
                case .changed:
                    // 直接用baseScale * gesture.scale，保证缩放手势连续
                    let newScale = min(max(baseScale * gesture.scale, 1.0), 4.0)
                    parent.scale = newScale
                    parent.isZoomed = newScale > 1.0
                case .ended, .cancelled:
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
                // 无需touchStartedOnImage逻辑
                break
            case .changed:
                // 只在缩放时允许拖动
                if parent.scale > 1.0 {
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
                if parent.scale > 1.0 {
                    parent.lastOffset = parent.offset
                }
                // 无需touchStartedOnImage逻辑
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

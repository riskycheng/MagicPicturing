//
//  NFTGalleryView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/15.
//

import SwiftUI
import Combine
import AudioToolbox

// MARK: - Data Model & Navigation
struct CardStackItem: Identifiable, Equatable {
    static func == (lhs: CardStackItem, rhs: CardStackItem) -> Bool {
        lhs.id == rhs.id
    }
    
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let number: String
    let gradientColors: [Color]
    let navigationTarget: NavigationTarget
}

enum NavigationTarget {
    case threeDGrid
    case collage
    case placeholder(String)
}

// MARK: - ViewModel
class CardStackViewModel: ObservableObject {
    @Published var cardItems: [CardStackItem] = []
    
    // Navigation State
    @Published var showThreeDGridEntry = false
    @Published var showCollageFlow = false
    @Published var showGenericView = false
    @Published var showPhotoWatermark = false
    @Published var selectedPlaceholderTitle = ""
    
    private var allCards: [CardStackItem] = []

    init() {
        allCards = [
            CardStackItem(title: "水印工坊", subtitle: "Photo Framer", description: "Add professional watermarks and frames to your photos.", number: "0000", gradientColors: [Color(hex: "#8E2DE2"), Color(hex: "#4A00E0")], navigationTarget: .placeholder("PhotoWatermark")),
            CardStackItem(title: "拼图", subtitle: "photo collage", description: "A famous technique to calm your nervous system for deep sleep.", number: "0001", gradientColors: [Color(hex: "#36D1DC"), Color(hex: "#5B86E5")], navigationTarget: .collage),
            CardStackItem(title: "立体九宫格", subtitle: "3D Grid", description: "Find your center and calm your mind with this rhythmic pattern.", number: "0002", gradientColors: [Color(hex: "#136a8a"), Color(hex: "#267871")], navigationTarget: .threeDGrid),
            CardStackItem(title: "Body Scan", subtitle: "Drift", description: "Focus on your body and let go of tension with each progressive motion.", number: "0003", gradientColors: [Color(hex: "#5D4157"), Color(hex: "#A8CABA")], navigationTarget: .placeholder("Body Scan Drift")),
            CardStackItem(title: "Keep", subtitle: "Calm", description: "Soothe your body by extending your exhale, signaling relaxation.", number: "0004", gradientColors: [Color(hex: "#2B32B2"), Color(hex: "#1488CC")], navigationTarget: .placeholder("Keep Calm"))
        ]
        loadItems()
    }
    
    func loadItems() {
        self.cardItems = allCards
    }
    
    func cycleTopCard() {
        guard !cardItems.isEmpty else { return }
        let topCard = cardItems.removeLast()
        cardItems.insert(topCard, at: 0)
    }
    
    func cardTapped(item: CardStackItem) {
        switch item.navigationTarget {
        case .threeDGrid:
            showThreeDGridEntry = true
        case .collage:
            showCollageFlow = true
        case .placeholder(let title):
            if title == "PhotoWatermark" {
                showPhotoWatermark = true
            } else {
                selectedPlaceholderTitle = title
                showGenericView = true
            }
        }
    }
    
    func resetCards() {
        loadItems()
    }
}


// MARK: - Main View
struct NFTGalleryView: View {
    @StateObject private var viewModel = CardStackViewModel()
    @State private var displayMode: DisplayMode = .stack
    
    enum DisplayMode {
        case stack, list
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    HeaderView(
                        displayMode: $displayMode
                    )
                    .padding(.bottom, 20)

                    if displayMode == .stack {
                        RingView(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)),
                                removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
                            )
                    } else {
                        CardListView(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .top)),
                                removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
                            )
                    }
                    Spacer(minLength: 0)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $viewModel.showThreeDGridEntry) {
                ThreeDGridEntryView()
            }
            .fullScreenCover(isPresented: $viewModel.showCollageFlow) {
                CollageEntryView()
            }
            .sheet(isPresented: $viewModel.showPhotoWatermark) {
                PhotoWatermarkEntryView()
            }
            .sheet(isPresented: $viewModel.showGenericView) {
                Text("\(viewModel.selectedPlaceholderTitle) feature is in development.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Header
private struct HeaderView: View {
    @Binding var displayMode: NFTGalleryView.DisplayMode

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Magic Picturing")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("build your fantastic photographs")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    displayMode = (displayMode == .stack) ? .list : .stack
                }
            }) {
                Image(systemName: displayMode == .stack ? "list.bullet" : "square.stack.3d.up.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Ring View
struct RingView: View {
    @ObservedObject var viewModel: CardStackViewModel

    // --- Ring Scrolling State ---
    @State private var continuousScrollPosition: CGFloat
    @State private var gestureStartScrollPosition: CGFloat = 0.0
    @State private var isDragging = false

    // --- Ring Geometry Constants ---
    private let rotationRadius: CGFloat = 350
    private let angularSpacing: Double = 0.45
    private var pixelsPerIndex: CGFloat { rotationRadius * CGFloat(angularSpacing) }

    init(viewModel: CardStackViewModel) {
        self.viewModel = viewModel
        // Start with the first card item at the front
        _continuousScrollPosition = State(initialValue: 0)
    }
    
    var body: some View {
        VStack {
            if viewModel.cardItems.isEmpty {
                // Placeholder for empty state
                VStack {
                    Text("No cards available.").font(.headline).foregroundColor(.secondary)
                    Button("Reset", action: viewModel.resetCards).padding()
                }
            } else {
                GeometryReader { geometry in
                    ZStack {
                        // We render a few cards on each side for a seamless circular effect
                        ForEach(-3...3, id: \.self) { index in
                             if isCardVisible(index) {
                                cardView(for: index)
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(y: -50)
                    .contentShape(Rectangle())
                    .gesture(dragGesture)
                    .onChange(of: snappedIndex) {
                        // Play a light haptic feedback
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        // Play a subtle system sound (tock)
                        AudioServicesPlaySystemSound(1104)
                    }
                }
            }
        }
    }
    
    // --- State-driven Computed Properties ---
    private var snappedIndex: Int { Int(round(continuousScrollPosition)) }
    private var continuousAngleOffset: Double {
        let fractionalPart = continuousScrollPosition - CGFloat(snappedIndex)
        return -fractionalPart * angularSpacing
    }

    // --- Helper Functions ---
    private func getRingIndex(for offsetIndex: Int) -> Int {
        guard !viewModel.cardItems.isEmpty else { return 0 }
        let totalCount = viewModel.cardItems.count
        let rawIndex = (snappedIndex + offsetIndex) % totalCount
        return rawIndex < 0 ? rawIndex + totalCount : rawIndex
    }
    
    private func isCardVisible(_ offsetIndex: Int) -> Bool {
        let ringIndex = getRingIndex(for: offsetIndex)
        return viewModel.cardItems.indices.contains(ringIndex)
    }

    // --- Geometry Calculation Functions ---
    private func calculateCardAngle(for offsetIndex: Int) -> Double {
        return Double(offsetIndex) * angularSpacing + continuousAngleOffset
    }
    
    private func geometry(for angle: Double) -> (scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat, zIndex: Double, opacity: Double) {
        let scale = (cos(angle) * 0.35) + 0.65
        let yOffset = (1 - cos(angle)) * -90
        let xOffset = sin(angle) * rotationRadius * 0.7
        let zIndex = cos(angle) * 10
        let opacity = pow(cos(angle / 2.0), 3)
        return (scale, xOffset, yOffset, zIndex, opacity)
    }
    
    // --- Card View Builder ---
    @ViewBuilder
    private func cardView(for offsetIndex: Int) -> some View {
        let ringIndex = getRingIndex(for: offsetIndex)
        let item = viewModel.cardItems[ringIndex]
        let angle = calculateCardAngle(for: offsetIndex)
        let geo = geometry(for: angle)
        let isFocused = abs(angle) < (angularSpacing / 2.0)

        SingleCardView(item: item, isFocused: isFocused)
            .scaleEffect(geo.scale)
            .offset(x: geo.xOffset, y: geo.yOffset)
            .zIndex(geo.zIndex)
            .opacity(geo.opacity)
            .onTapGesture {
                if isFocused {
                    viewModel.cardTapped(item: item)
                } else {
                    let targetPosition = CGFloat(snappedIndex + offsetIndex)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        continuousScrollPosition = targetPosition
                    }
                }
            }
    }
    
    // --- Drag Gesture & Physics ---
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    gestureStartScrollPosition = continuousScrollPosition
                }
                let dragDistance = value.translation.width
                continuousScrollPosition = gestureStartScrollPosition - (dragDistance / pixelsPerIndex)
            }
            .onEnded { value in
                isDragging = false
                
                let velocity = -value.predictedEndTranslation.width / pixelsPerIndex
                let projectedPosition = continuousScrollPosition + velocity * 0.2
                let targetPosition = round(projectedPosition)

                // Clamp to prevent over-scrolling in a non-looping list
                // let maxIndex = CGFloat(viewModel.cardItems.count - 1)
                // targetPosition = max(0, min(targetPosition, maxIndex))

                let spring = Animation.interpolatingSpring(
                    mass: 0.5, stiffness: 100, damping: 20, initialVelocity: velocity
                )
                
                withAnimation(spring) {
                    continuousScrollPosition = targetPosition
                }
            }
    }
}

// MARK: - Card List View
struct CardListView: View {
    @ObservedObject var viewModel: CardStackViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Array(viewModel.cardItems.enumerated()), id: \.element.id) { index, item in
                    SingleCardView(item: item)
                        .onTapGesture { viewModel.cardTapped(item: item) }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 30)),
                            removal: .opacity.combined(with: .offset(y: -30)))
                        )
                }
            }
            .padding()
        }
    }
}

// MARK: - Reusable Single Card View
struct SingleCardView: View {
    let item: CardStackItem
    var isFocused: Bool = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 25)
                .fill(LinearGradient(gradient: Gradient(colors: item.gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing))
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 34, weight: .heavy))
                        Text(item.subtitle)
                             .font(.system(size: 28, weight: .bold))
                    }
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                    
                    Spacer()
                    
                    Text(item.number)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 5)
                }
                
                Spacer()
                
                Text(item.description)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(3)
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 1)

            }
            .foregroundColor(.white)
            .padding(25)
        }
        .frame(width: 320, height: isFocused ? 500 : 420)
        .shadow(color: .black.opacity(0.2), radius: 12, y: 8)
    }
}


// MARK: - Helpers & Previews
struct NFTGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        NFTGalleryView()
    }
}

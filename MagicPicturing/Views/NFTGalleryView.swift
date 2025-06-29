//
//  NFTGalleryView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/15.
//

import SwiftUI
import Combine

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
    @Published var selectedPlaceholderTitle = ""
    
    private var allCards: [CardStackItem] = []

    init() {
        allCards = [
            CardStackItem(title: "Keep", subtitle: "Calm", description: "Soothe your body by extending your exhale, signaling relaxation.", number: "0004", gradientColors: [Color(hex: "#2B32B2"), Color(hex: "#1488CC")], navigationTarget: .placeholder("Keep Calm")),
            CardStackItem(title: "Body Scan", subtitle: "Drift", description: "Focus on your body and let go of tension with each progressive motion.", number: "0003", gradientColors: [Color(hex: "#5D4157"), Color(hex: "#A8CABA")], navigationTarget: .placeholder("Body Scan Drift")),
            CardStackItem(title: "Box", subtitle: "Breathing", description: "Find your center and calm your mind with this rhythmic pattern.", number: "0002", gradientColors: [Color(hex: "#136a8a"), Color(hex: "#267871")], navigationTarget: .threeDGrid),
            CardStackItem(title: "Relaxing", subtitle: "Breath", description: "A famous technique to calm your nervous system for deep sleep.", number: "0001", gradientColors: [Color(hex: "#36D1DC"), Color(hex: "#5B86E5")], navigationTarget: .collage)
        ]
        loadItems()
    }
    
    func loadItems() {
        self.cardItems = allCards
    }
    
    func cardSwiped(item: CardStackItem) {
        if let index = cardItems.firstIndex(where: { $0.id == item.id }) {
            cardItems.remove(at: index)
        }
    }
    
    func cardTapped(item: CardStackItem) {
        switch item.navigationTarget {
        case .threeDGrid:
            showThreeDGridEntry = true
        case .collage:
            showCollageFlow = true
        case .placeholder(let title):
            selectedPlaceholderTitle = title
            showGenericView = true
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
                        cardCount: viewModel.cardItems.count,
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
            .sheet(isPresented: $viewModel.showGenericView) {
                Text("\(viewModel.selectedPlaceholderTitle) feature is in development.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Header
private struct HeaderView: View {
    let cardCount: Int
    @Binding var displayMode: NFTGalleryView.DisplayMode

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Sleep Collection")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("\(cardCount) Presets")
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

// MARK: - Card Stack View (Now RingView)
struct RingView: View {
    @ObservedObject var viewModel: CardStackViewModel

    // --- Ring Scrolling State ---
    @State private var continuousScrollPosition: CGFloat = 0.0
    @State private var gestureStartScrollPosition: CGFloat = 0.0
    @State private var isDragging = false

    // --- Ring Geometry Constants ---
    private let rotationRadius: CGFloat = 500
    private let angularSpacing: Double = 0.40
    private var pixelsPerIndex: CGFloat { rotationRadius * CGFloat(angularSpacing) * 0.5 }

    var body: some View {
        VStack {
            if viewModel.cardItems.isEmpty {
                VStack {
                    Text("All cards viewed.").font(.headline).foregroundColor(.secondary)
                    Button("Reset Cards", action: viewModel.resetCards).padding()
                }
            } else {
                GeometryReader { geometry in
                    ZStack {
                        ForEach(-3...3, id: \.self) { index in
                             if isCardVisible(index) {
                                cardView(for: index)
                            }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .gesture(dragGesture)
                }
            }
        }
    }
    
    // --- Computed Properties from State ---
    private var snappedIndex: Int { Int(round(continuousScrollPosition)) }
    private var continuousAngleOffset: Double {
        let fractionalPart = continuousScrollPosition - CGFloat(snappedIndex)
        return -fractionalPart * angularSpacing
    }

    // --- Helper Functions ---
    private func getRingIndex(for index: Int) -> Int {
        guard !viewModel.cardItems.isEmpty else { return 0 }
        let totalCount = viewModel.cardItems.count
        let rawIndex = (snappedIndex + index) % totalCount
        return rawIndex < 0 ? rawIndex + totalCount : rawIndex
    }
    
    private func isCardVisible(_ index: Int) -> Bool {
        let ringIndex = getRingIndex(for: index)
        return viewModel.cardItems.indices.contains(ringIndex)
    }

    private func calculateCardAngle(for index: Int) -> Double {
        return Double(index) * angularSpacing + continuousAngleOffset
    }

    private func calculateScale(for angle: Double) -> CGFloat {
        return 1.0 - abs(angle) * 0.4
    }
    
    private func calculateYOffset(for angle: Double) -> CGFloat {
        return (1 - cos(angle)) * -rotationRadius * 0.3
    }
    
    private func calculateXOffset(for angle: Double) -> CGFloat {
        return sin(angle) * rotationRadius * 0.5
    }

    private func calculateZIndex(for angle: Double) -> Double {
        return cos(angle) * 10
    }
    
    private func calculateOpacity(for angle: Double) -> Double {
        return pow(cos(angle / 2.0), 4)
    }
    
    // --- Card View Builder ---
    @ViewBuilder
    private func cardView(for index: Int) -> some View {
        let ringIndex = getRingIndex(for: index)
        let item = viewModel.cardItems[ringIndex]
        let angle = calculateCardAngle(for: index)
        let isFocused = abs(angle) < (angularSpacing / 2.0)

        SingleCardView(item: item)
            .scaleEffect(calculateScale(for: angle))
            .offset(x: calculateXOffset(for: angle), y: calculateYOffset(for: angle))
            .zIndex(calculateZIndex(for: angle))
            .opacity(calculateOpacity(for: angle))
            .onTapGesture {
                if isFocused {
                    viewModel.cardTapped(item: item)
                } else {
                    let targetPosition = CGFloat(snappedIndex + index)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        continuousScrollPosition = targetPosition
                    }
                }
            }
    }
    
    // --- Drag Gesture Logic ---
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
                
                let velocity = value.predictedEndTranslation.width / pixelsPerIndex
                let projectedPosition = continuousScrollPosition - velocity * 0.1
                let targetPosition = round(projectedPosition)

                let spring = Animation.interpolatingSpring(
                    mass: 0.8, stiffness: 100.0, damping: 25.0, initialVelocity: -velocity
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
                             .font(.system(size: 34, weight: .heavy))
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
        .frame(width: 320, height: 420)
        .shadow(color: .black.opacity(0.2), radius: 12, y: 8)
    }
}


// MARK: - Helpers & Previews
struct NFTGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        NFTGalleryView()
    }
}

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
                        CardStackView(viewModel: viewModel)
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

// MARK: - Card Stack View
struct CardStackView: View {
    @ObservedObject var viewModel: CardStackViewModel
    
    var body: some View {
        VStack {
            Spacer()
            if viewModel.cardItems.isEmpty {
                VStack {
                    Text("All cards viewed")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Button("Reset Cards", action: viewModel.resetCards)
                        .padding()
                }
            } else {
                ZStack {
                    ForEach(viewModel.cardItems) { item in
                        CardViewContainer(
                            item: item,
                            viewModel: viewModel,
                            isTopCard: viewModel.cardItems.last?.id == item.id
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Spacer()
        }
    }
}

struct CardViewContainer: View {
    let item: CardStackItem
    @ObservedObject var viewModel: CardStackViewModel
    let isTopCard: Bool

    @State private var offset: CGSize = .zero
    
    private func getCardIndex() -> Int? {
        // Find the index from the back of the array
        viewModel.cardItems.firstIndex(where: { $0.id == item.id })
    }

    var body: some View {
        if let index = getCardIndex() {
            // Stack position is calculated from the end of the array
            let stackPosition = viewModel.cardItems.count - 1 - index
            let scale = 1.0 - (CGFloat(stackPosition) * 0.05)
            let verticalOffset = CGFloat(stackPosition) * -15.0

            SingleCardView(item: item)
                .scaleEffect(isTopCard ? 1.0 : scale)
                .offset(y: verticalOffset)
                .offset(x: isTopCard ? offset.width : 0, y: isTopCard ? offset.height : 0)
                .rotationEffect(.degrees(isTopCard ? Double(offset.width / 40.0) : 0))
                .gesture(isTopCard ? dragGesture : nil)
                .onTapGesture { if isTopCard { viewModel.cardTapped(item: item) } }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: offset)
                .zIndex(Double(index))
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                offset = gesture.translation
            }
            .onEnded { gesture in
                let swipeThreshold: CGFloat = 120
                if abs(gesture.predictedEndTranslation.width) > swipeThreshold {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        let sign = gesture.predictedEndTranslation.width > 0 ? 1.0 : -1.0
                        offset.width = sign * 1000
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        viewModel.cardSwiped(item: item)
                    }
                } else {
                    withAnimation(.spring()) {
                        offset = .zero
                    }
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

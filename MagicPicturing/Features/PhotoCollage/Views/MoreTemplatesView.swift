import SwiftUI

struct MoreTemplatesView: View {
    @Binding var isPresented: Bool
    let imageCount: Int
    let onLayoutSelected: (CollageLayout) -> Void
    
    @State private var layouts: [CollageLayout] = []
    private let layoutProvider = JSONCollageLayoutProvider()
    
    // Define a grid layout for the templates
    private let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("More Templates")
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding([.top, .horizontal])
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(layouts) { layout in
                        Button(action: {
                            onLayoutSelected(layout)
                            isPresented = false
                        }) {
                            VStack {
                                layout.preview
                                    .frame(width: 80, height: 80)
                                Text("\(layout.cellStates.count) Photos")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear(perform: loadLayouts)
    }
    
    private func loadLayouts() {
        self.layouts = layoutProvider.loadTemplates(for: imageCount)
    }
} 
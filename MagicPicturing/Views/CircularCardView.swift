//
//  CardStackView.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/13.
//

import SwiftUI

// This is now a simple wrapper around NFTGalleryView
struct CircularCardView: View {
    @ObservedObject var viewModel: PhotoLibraryViewModel
    
    var body: some View {
        NFTGalleryView(viewModel: viewModel)
    }
}

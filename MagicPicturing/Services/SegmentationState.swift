//
//  SegmentationState.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/18.
//

import Foundation
import SwiftUI

/// Represents the current state of the segmentation process
enum SegmentationState: Equatable {
    case idle
    case loading
    case success(PlatformImage)
    case failure(String)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var resultImage: PlatformImage? {
        if case .success(let image) = self {
            return image
        }
        return nil
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }
    
    static func == (lhs: SegmentationState, rhs: SegmentationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.success(let lhsImage), .success(let rhsImage)):
            return lhsImage === rhsImage
        case (.failure(let lhsMessage), .failure(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

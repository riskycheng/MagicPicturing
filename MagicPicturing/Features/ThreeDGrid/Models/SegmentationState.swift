//
//  SegmentationState.swift
//  MagicPicturing
//
//  Created by Jian Cheng on 2025/5/18.
//

import Foundation
import SwiftUI

/// 简单的分割状态枚举，不带关联值
enum SegmentationState: Equatable {
    case idle
    case loading
    case success
    case failure
}

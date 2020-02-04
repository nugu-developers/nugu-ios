//
//  PlaySyncDuration.swift
//  NuguCore
//
//  Created by childc on 2020/01/29.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
//

import Foundation

public enum PlaySyncDuration {
    case none
    case short
    case mid
    case long
    case longest
}

public extension PlaySyncDuration {
    var time: DispatchTimeInterval {
        switch self {
        case .none: return .seconds(0)
        case .short: return .seconds(7)
        case .mid: return .seconds(15)
        case .long: return .seconds(30)
        case .longest: return .seconds(60 * 10)
        }
    }
}

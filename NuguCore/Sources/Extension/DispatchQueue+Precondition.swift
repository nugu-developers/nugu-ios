//
//  DispatchQueue+Precondition.swift
//  NuguCore
//
//  Created by childc on 2020/01/23.
//

import Foundation

public enum DispatchQueuePredicate {
    case onQueue
    case onQueueAsBarrier
    case notOnQueue
}

public extension DispatchQueue {
    func precondition(_ condition: DispatchQueuePredicate) {
        #if DEBUG
        var dispatchPredicate: DispatchPredicate {
            switch condition {
            case .onQueue:
                return .onQueue(self)
            case .onQueueAsBarrier:
                return .onQueueAsBarrier(self)
            case .notOnQueue:
                return .notOnQueue(self)
            }
        }
        
        dispatchPrecondition(condition: dispatchPredicate)
        #endif
    }
}

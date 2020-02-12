//
//  NSObject+Rx.swift
//  NuguAgents
//
//  Created by Krunoslav Zaher on 2/21/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

import RxSwift

private var deallocatedSubjectTriggerContext: UInt8 = 0
private var deallocatedSubjectContext: UInt8 = 0

extension Reactive where Base: AnyObject {
    /**
    Observable sequence of object deallocated events.
    
    After object is deallocated one `()` element will be produced and sequence will immediately complete.
    
    - returns: Observable sequence of object deallocated events.
    */
    var deallocated: Observable<Void> {
        return self.synchronized {
            if let deallocObservable = objc_getAssociatedObject(self.base, &deallocatedSubjectContext) as? DeallocObservable {
                return deallocObservable.subject
            }

            let deallocObservable = DeallocObservable()

            objc_setAssociatedObject(self.base, &deallocatedSubjectContext, deallocObservable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return deallocObservable.subject
        }
    }
}

extension Reactive where Base: AnyObject {
    func synchronized<T>( _ action: () -> T) -> T {
        objc_sync_enter(self.base)
        let result = action()
        objc_sync_exit(self.base)
        return result
    }
}

private final class DeallocObservable {
    let subject = ReplaySubject<Void>.create(bufferSize: 1)

    init() {
    }

    deinit {
        self.subject.on(.next(()))
        self.subject.on(.completed)
    }
}

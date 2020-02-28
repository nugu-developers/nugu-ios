//
//  ObserverProtocol.swift
//  NuguCore
//
//  Created by childc on 2020/02/27.
//

import Foundation

public protocol ObserverProtocol: class {
    func updated<Value>(_ value: Value)
}

public protocol EmitterProtocol {
    func register<T: ObserverProtocol>(_ observer: T)
    func remove<T: ObserverProtocol>(_ observer: T)
}

//class QWER: EmitterProtocol {
//    func register<T>(_ observer: T) where T : ObserverProtocol {
//        observers.append(observer)
//    }
//    
//    func remove<T>(_ observer: T) where T : ObserverProtocol {
//        if let index = observers.firstIndex(where: { $0 === observer }) {
//            observers.remove(at: index)
//        }
//    }
//    
//    var observers = [ObserverProtocol]()
//    
//    func notifyAll() {
//        observers.forEach { observer in
//            observer.updated(3)
//        }
//    }
//    
//    init() {
//        DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [weak self] in
//            self?.notifyAll()
//        }
//    }
//}
//
//class ZXCV: ObserverProtocol {
//    func updated<Value>(_ value: Value) {
//        print("value updated: \(value)")
//    }
//}

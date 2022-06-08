//
//  DataBoundInputStream.swift
//  NuguUtils
//
//  Created by childc on 2021/01/27.
//  Copyright © 2021 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

public class DataBoundInputStream: InputStream {
    @Atomic private var data: Data
    @Atomic var isLastDataAppended = false
    @Atomic private var internalProperty = [Stream.PropertyKey: Any?]()
    private var runLoop = RunLoop.main
    private var runLoopMode = RunLoop.Mode.default
    
    private weak var internalDelegate: StreamDelegate?
    public override var delegate: StreamDelegate? {
        set {
            internalDelegate = newValue
        }

        get {
            return internalDelegate
        }
    }

    @Atomic private var internalStatus: Stream.Status = .notOpen
    public override var streamStatus: Stream.Status {
        get {
            return internalStatus
        }

        set {
            internalStatus = newValue
        }
    }
    
    public override init(data: Data) {
        self.data = data
        super.init(data: data)
    }
    
    public override func open() {
        internalStatus = .open
        notify(event: .openCompleted)

        if 0 < data.count {
            notify(event: .hasBytesAvailable)
        }
    }

    public override func close() {
        internalStatus = .closed
    }

    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        internalStatus = .reading
        
        var popData: Data?
        _data.mutate {
            let length = min($0.count, len)
            guard 0 < length else { return }
            
            popData = $0[..<length]
            $0.removeSubrange(..<length)
            
            switch $0.count {
            case 0 where isLastDataAppended:
                internalStatus = .atEnd
                notify(event: .endEncountered)
                
            case 1...:
                internalStatus = .open
                notify(event: .hasBytesAvailable)
                
            default:
                internalStatus = .open
            }
        }
        guard let readData = popData else { return 0 }

        readData.copyBytes(to: buffer, from: 0..<readData.count)
        return readData.count
    }
    
    public override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        guard 0 < data.count else { return false }
        
        let copiedBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: copiedBuffer, from: 0..<data.count)
        buffer.pointee = copiedBuffer
        len.pointee = data.count
        
        return true
    }
    
    public override var hasBytesAvailable: Bool {
        return 0 < data.count
    }

    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        runLoop = aRunLoop
        runLoopMode = mode
    }
    
    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        runLoop = RunLoop.main
        runLoopMode = RunLoop.Mode.default
    }
    
    public override func property(forKey key: Stream.PropertyKey) -> Any? {
        return internalProperty[key] ?? nil
    }
    
    public override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool {
        _internalProperty.mutate {
            $0.updateValue(property, forKey: key)
        }
        return true
    }

    func notify(event: Stream.Event) {
        guard streamStatus != .notOpen else { return }
        runLoop.perform(inModes: [runLoopMode]) { [weak self] in
            guard let self = self else { return }
            self.delegate?.stream?(self, handle: event)
        }
    }
}

// MARK: Data releated

extension DataBoundInputStream {
    public func appendData(_ other: Data) {
        guard isLastDataAppended == false else { return }

        self._data.mutate {
            $0.append(other)
        }
        
        notify(event: .hasBytesAvailable)
    }
    
    public func lastDataAppended() {
        isLastDataAppended = true

        if data.count == 0 {
            internalStatus = .atEnd
            notify(event: .endEncountered)
        }
    }
}

//
//  InputStreamPipedData.swift
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

public class InputStreamPipedData {
    @Atomic private var data = Data()
    @Atomic var isOpened = true

    private lazy var internalInputStream = InputStream(base: self)
    public var input: Foundation.InputStream {
        return internalInputStream
    }
    
    public init() {}

    public func append(_ other: Data) {
        guard isOpened else { return }

        self._data.mutate {
            $0.append(other)
            internalInputStream.notify(event: .hasBytesAvailable)
        }
    }

    private func detach(count: Int) -> Data? {
        var data: Data?
        _data.mutate {
            let length = min($0.count, count)
            guard 0 < length else { return }
            
            data = $0[..<length]
            $0.removeSubrange(..<length)

            guard 0 < $0.count else {
                if isOpened == false {
                    internalInputStream.finish()
                }

                return
            }

            internalInputStream.notify(event: .hasBytesAvailable)
        }

        return data
    }

    public func finish() {
        isOpened = false
    }
}

extension InputStreamPipedData {
    private class InputStream: Foundation.InputStream {
        private weak var base: InputStreamPipedData!
        private var runLoop = RunLoop.main
        private var runLoopMode = RunLoop.Mode.default
        
        private weak var internalDelegate: StreamDelegate?
        override var delegate: StreamDelegate? {
            set {
                internalDelegate = newValue
            }

            get {
                return internalDelegate
            }
        }

        private var internalStatus: Stream.Status = .notOpen
        override var streamStatus: Stream.Status {
            get {
                return internalStatus
            }

            set {
                internalStatus = newValue
            }
        }
        
        convenience init(base: InputStreamPipedData) {
            self.init()
            self.base = base
        }

        override func open() {
            internalStatus = .open
            notify(event: .openCompleted)

            if 0 < base.data.count {
                notify(event: .hasBytesAvailable)
            }
        }

        override func close() {
            internalStatus = .closed
        }

        override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            defer {
                internalStatus = .open
            }

            internalStatus = .reading
            guard let data = base.detach(count: len) else { return 0}

            data.copyBytes(to: buffer, from: 0..<data.count)
            return data.count
        }

        override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
            defer {
                internalStatus = .open
            }

            internalStatus = .reading
            guard len.pointee <= base.data.count,
                  let data = base.detach(count: len.pointee) else { return false }

            let copybuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: len.pointee)
            data.copyBytes(to: copybuffer, from: 0..<data.count)
            buffer.pointee = copybuffer

            return true
        }

        override var hasBytesAvailable: Bool {
            return 0 < base.data.count
        }

        override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
            runLoop = aRunLoop
            runLoopMode = mode
        }

        func finish() {
            internalStatus = .atEnd
            notify(event: .endEncountered)
        }

        func notify(event: Stream.Event) {
            guard streamStatus != .notOpen else { return }
            runLoop.perform(inModes: [runLoopMode]) { [weak self] in
                guard let self = self else { return }
                self.delegate?.stream?(self, handle: event)
            }
        }
    }
}

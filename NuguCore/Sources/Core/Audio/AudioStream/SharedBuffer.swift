//
//  SharedBuffer.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 01/05/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
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
import AVFoundation
import RxSwift

/**
 SharedBuffer is based on RingBuffer.
 It can have only one writer and multiple reader.
 */
public class SharedBuffer<Element> {
    private var array: [Element?]
    @Atomic private var lastIndex: SharedBufferIndex

    weak var writer: Writer?
    let writeQueue = DispatchQueue(label: "com.sktelecom.romaine.ring_buffer.write")
    let writeSubject: PublishSubject<Element> = PublishSubject<Element>()
    private var readers: NSHashTable<Reader> = NSHashTable.weakObjects()
    private let disposeBag = DisposeBag()
    
    public init(capacity: Int) {
        array = [Element?](repeating: nil, count: capacity)
        lastIndex = SharedBufferIndex(bufferSize: array.count)
    }
    
    private func write(_ element: Element) {
        writeQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.array[self.lastIndex.value] = element
            self.lastIndex += 1
            
            self.writeSubject.onNext(element)
        }
    }
    
    private func read(index: SharedBufferIndex) -> Observable<Element> {
        return Observable<Element>.create { [weak self] (observer) -> Disposable in
            let disposable = Disposables.create()
            
            guard let self = self else { return disposable }
            guard index < self.lastIndex, let value = self.array[index.value] else {
                self.writeSubject
                    .take(1)
                    .subscribe(onNext: { (element) in
                        observer.onNext(element)
                        observer.onCompleted()
                    }).disposed(by: self.disposeBag)
                
                return disposable
            }
            
            observer.onNext(value)
            observer.onCompleted()
            
            return disposable
        }
    }
    
    public func makeBufferWriter() -> Writer {
        let writer = Writer(buffer: self)
        self.writer = writer
        return writer
    }
    
    public func makeBufferReader() -> Reader {
        return Reader(buffer: self)
    }
}

// MARK: - Writer/Reader
extension SharedBuffer {
    public class Writer {
        let buffer: SharedBuffer
        
        init(buffer: SharedBuffer) {
            self.buffer = buffer
        }
        
        public func write(_ element: Element) throws {
            guard buffer.writer === self else {
                throw SharedBufferError.writePermissionDenied
            }
            
            buffer.write(element)
        }
        
        public func finish() {
            log.debug("readers cnt: \(buffer.readers.allObjects.count)")
            buffer.readers.allObjects.forEach { (reader) in
                reader.readDisposable?.dispose()
            }
        }
    }
    
    public class Reader {
        private let buffer: SharedBuffer
        private let readQueue = DispatchQueue(label: "com.sktelecom.romaine.ring_buffer.reader")
        @Atomic private var readIndex: SharedBufferIndex
        public var readDisposable: Disposable?
        private let disposeBag = DisposeBag()
        
        init(buffer: SharedBuffer) {
            self.buffer = buffer
            self.readIndex = buffer.lastIndex
            buffer.readers.add(self)
        }
        
        public func read(complete: @escaping (Result<Element, Error>) -> Void) {
            var isCompleted = false
            self.readDisposable = self.buffer.read(index: self.readIndex)
                .take(1)
                .observeOn(SerialDispatchQueueScheduler(queue: readQueue, internalSerialQueueName: "rx-"+readQueue.label))
                .subscribe(onNext: { [weak self] (writtenElement) in
                    isCompleted = true
                    self?.readIndex += 1
                    complete(.success(writtenElement))
                }, onDisposed: {
                    if isCompleted == false {
                        complete(.failure(SharedBufferError.writerFinished))
                    }
                })
            self.readDisposable?.disposed(by: self.disposeBag)
        }
    }
}

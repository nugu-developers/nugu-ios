//
//  ServerEndPointDetector.swift
//  NuguAgents
//
//  Created by MinChul Lee on 2020/04/03.
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

import NuguCore
import JadeMarble

import RxSwift

class ServerEndPointDetector: EndPointDetectable {
    weak var delegate: EndPointDetectorDelegate?
    
    private var boundStreams: AudioBoundStreams?
    private var streamDelegator: InputStreamDelegator?
    private let asrOptions: ASROptions
    private let speexEncoder: SpeexEncoder
    
    private let epdQueue = DispatchQueue(label: "com.sktelecom.romaine.server_end_point_detector")
    private lazy var epdScheduler = SerialDispatchQueueScheduler(
        queue: epdQueue,
        internalSerialQueueName: "com.sktelecom.romaine.server_end_point_detector"
    )
    private var inputStream: InputStream?
    private var listeningTimer: Disposable?
    
    private var state: EndPointDetectorState = .idle {
        didSet {
            switch state {
            case .listening:
                startListeningTimer()
            case .unknown, .end, .timeout:
                listeningTimer?.dispose()
                stop()
            default:
                break
            }
            delegate?.endPointDetectorStateChanged(state)
        }
    }
    
    #if DEBUG
    private var outputData = Data()
    #endif
    
    init(asrOptions: ASROptions) {
        self.asrOptions = asrOptions
        speexEncoder = SpeexEncoder(sampleRate: Int(asrOptions.sampleRate), inputType: .linearPcm16)
    }
    
    deinit {
        internalStop()
    }
    
    func start(audioStreamReader: AudioStreamReadable) {
        log.debug("")
        
        epdQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.internalStop()
            self.boundStreams = AudioBoundStreams(audioStreamReader: audioStreamReader)
            let inputStream = self.boundStreams!.input
            
            self.streamDelegator = InputStreamDelegator(owner: self)
            CFReadStreamSetDispatchQueue(inputStream, self.epdQueue)
            inputStream.delegate = self.streamDelegator
            inputStream.open()
            
            self.state = .listening
        }
    }
    
    func stop() {
        log.debug("stop")
        
        epdQueue.async { [weak self] in
            self?.internalStop()
        }
    }
    
    private func internalStop() {
        listeningTimer?.dispose()
        boundStreams?.stop()
        
        if let inputStream = inputStream,
            inputStream.streamStatus != .closed {
            inputStream.close()
            inputStream.delegate = nil
        }

        state = .idle
        streamDelegator = nil
    }
    
    func handleNotifyResult(_ state: ASRNotifyResult.State) {
        switch state {
        case .error:
            self.state = .unknown
        case .sos:
            self.state = .start
        case .eos:
            self.state = .end
            
            #if DEBUG
            do {
                let speexFileName = FileManager.default.urls(for: .documentDirectory,
                                                             in: .userDomainMask)[0].appendingPathComponent("server_epd_output.speex")
                log.debug("speex data to file :\(speexFileName)")
                try outputData.write(to: speexFileName)
                
                outputData.removeAll()
            } catch {
                log.debug(error)
            }
            #endif
        case .falseAcceptance:
            // TODO:
            break
        default:
            break
        }
    }
}

extension ServerEndPointDetector {
    private class InputStreamDelegator: NSObject, StreamDelegate {
        private let owner: ServerEndPointDetector
        
        init(owner: ServerEndPointDetector) {
            self.owner = owner
        }
        
        func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            guard let inputStream = aStream as? InputStream,
                inputStream == owner.inputStream else { return }
            
            switch eventCode {
            case .hasBytesAvailable:
                let inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(4096))
                defer { inputBuffer.deallocate() }
                
                let inputLength = inputStream.read(inputBuffer, maxLength: 4096)
                guard 0 < inputLength else { return }
                
                do {
                    let data = try owner.speexEncoder.encode(data: Data(bytes: inputBuffer, count: Int(inputLength)))
                    owner.delegate?.endPointDetectorSpeechDataExtracted(speechData: data)
                    
                    #if DEBUG
                    owner.outputData.append(data)
                    #endif
                } catch {
                    log.error(error)
                }
                
                if [.idle, .listening, .start].contains(owner.state) == false {
                    owner.stop()
                }
            case .endEncountered:
                log.debug("epd stream endEncountered")
                owner.stop()
            default:
                break
            }
        }
    }
}

// MARK: - Private

extension ServerEndPointDetector {
    func startListeningTimer() {
        listeningTimer = Completable.create { [weak self] (event) -> Disposable in
            guard let self = self else { return Disposables.create() }
            
            self.state = .timeout
            
            event(.completed)
            return Disposables.create()
        }
        .delaySubscription(asrOptions.timeout.dispatchTimeInterval, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
        .subscribe()
    }
}

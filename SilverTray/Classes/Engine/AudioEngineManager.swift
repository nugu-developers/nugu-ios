//  limitations under the License.
//

import Foundation
import AVFoundation
import os.log

class AudioEngineManager<Observer: AudioEngineObservable> {
    private let audioEngine = Atomic(AVAudioEngine())
    private let audioEngineQueue = OperationQueue()
    private var audioEngineObservers = Atomic(Set<Observer>())
    
    private let notificationCenter = NotificationCenter.default
    private var audioEngineConfigurationObserver: Any?
    
    var inputNode: AVAudioInputNode {
        audioEngine.atomicValue.inputNode
    }
    
    var outputNode: AVAudioOutputNode {
        audioEngine.atomicValue.outputNode
    }
    
    var mainMixerNode: AVAudioMixerNode {
        audioEngine.atomicValue.mainMixerNode
    }
    
    var isRunning: Bool {
        audioEngine.atomicValue.isRunning
    }
    
    init() {
        audioEngineQueue.name = "com.sktelecom.romain.silver_tray.audio_engine_notification"
    }
    
    func startAudioEngine() throws {
        var engineError: Error!
        audioEngine.atomicMutate { engine in
            guard engine.isRunning == false else { return }
            
            if let error = STUnifiedErrorCatcher.try({ () -> Error? in
                do {
                    // start audio engine
                    // This Api throws `Error` and raises `NSException` both.
                    try engine.start()
                    
                    os_log("audioEngine started", log: .audioEngine, type: .debug)
                } catch {
                    return error
                }
                
                return nil
            }) {
                engineError = error
            }
        }
        
        if let engineError = engineError {
            throw engineError
        }
        
        // if audio session is changed then influence to the AVAudioEngine, we should handle this.
        if let audioEngineConfigurationObserver = audioEngineConfigurationObserver {
            notificationCenter.removeObserver(audioEngineConfigurationObserver)
        }
        
        audioEngineConfigurationObserver = notificationCenter.addObserver(forName: .AVAudioEngineConfigurationChange, object: audioEngine.atomicValue, queue: audioEngineQueue) { [weak self] (notification) in
            self?.engineConfigurationChange(notification: notification)
        }
    }
    
    private func stopAudioEngine() throws {
        // if audio session is changed then influence to the AVAudioEngine, we should handle this.
        if let audioEngineConfigurationObserver = audioEngineConfigurationObserver {
            notificationCenter.removeObserver(audioEngineConfigurationObserver)
        }
        
        if let error = (STUnifiedErrorCatcher.try {
            // start audio engine
            audioEngine.atomicValue.stop()
            
            os_log("audioEngine stopped", log: .audioEngine, type: .debug)
            return nil
        }) {
            throw error
        }
    }
}

// MARK: - AVAudioEngine wrapper

extension AudioEngineManager {
    func attach(_ node: AVAudioNode) {
        audioEngine.atomicValue.attach(node)
    }
    
    func detach(_ node: AVAudioNode) {
        audioEngine.atomicValue.detach(node)
    }
    
    func connect(_ node1: AVAudioNode, to: AVAudioNode, format: AVAudioFormat?) {
        audioEngine.atomicValue.connect(node1, to: to, format: format)
    }
    
    func disconnectNodeOutput(_ node: AVAudioNode) {
        audioEngine.atomicValue.disconnectNodeOutput(node)
    }
}

// MARK: - Observer

extension AudioEngineManager {
    @discardableResult func registerObserver(_ observer: Observer) -> Bool {
        var isInserted = false
        audioEngineObservers.atomicMutate {
            isInserted = $0.insert(observer).inserted
        }
        try? startAudioEngine()
        
        return isInserted
    }
    
    @discardableResult func removeObserver(_ observer: Observer) -> Observer? {
        var removedObserver: Observer? = nil
        audioEngineObservers.atomicMutate {
            removedObserver = $0.remove(observer)
            if $0.count == 0 {
                try? stopAudioEngine()
            }
        }
        
        return removedObserver
    }
}

private extension AudioEngineManager {
    func engineConfigurationChange(notification: Notification) {
        os_log("engineConfigurationChange: %{private}@", log: .audioEngine, type: .debug, "\(notification)")
        
        do {
            try startAudioEngine()
        } catch {
            os_log("audioEngine start failed", log: .audioEngine, type: .debug)
        }
        
        audioEngineObservers.atomicValue.forEach { (observer) in
            observer.engineConfigurationChange(notification: notification)
        }
    }
}

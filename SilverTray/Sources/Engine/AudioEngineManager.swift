//  limitations under the License.
//

import Foundation
import AVFoundation
import os.log

import NuguUtils
import NuguObjcUtils

class AudioEngineManager<Observer: AudioEngineObservable> {
    @Atomic private var audioEngine = AVAudioEngine()
    private let audioEngineQueue = DispatchQueue(label: "com.sktelecom.romain.silver_tray.audio_engine_notification")
    private var audioEngineObservers = Set<Observer>()
    
    private let notificationCenter = NotificationCenter.default
    private var audioEngineConfigurationObserver: Any?
    
    var inputNode: AVAudioInputNode {
        audioEngine.inputNode
    }
    
    var outputNode: AVAudioOutputNode {
        audioEngine.outputNode
    }
    
    var mainMixerNode: AVAudioMixerNode {
        audioEngine.mainMixerNode
    }
    
    var isRunning: Bool {
        audioEngine.isRunning
    }
    
    private func startAudioEngine() throws {
        var engineError: Error?
        _audioEngine.mutate { engine in
            guard engine.isRunning == false else { return }
            
            if let error = UnifiedErrorCatcher.try({
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
        
        audioEngineConfigurationObserver = notificationCenter.addObserver(forName: .AVAudioEngineConfigurationChange, object: audioEngine, queue: nil) { [weak self] (notification) in
            self?.engineConfigurationChange(notification: notification)
        }
    }
    
    private func stopAudioEngine() throws {
        // if audio session is changed then influence to the AVAudioEngine, we should handle this.
        if let audioEngineConfigurationObserver = audioEngineConfigurationObserver {
            notificationCenter.removeObserver(audioEngineConfigurationObserver)
        }
        
        if let error = (UnifiedErrorCatcher.try {
            // start audio engine
            audioEngine.stop()
            
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
        _audioEngine.mutate { $0.attach(node) }
    }
    
    func detach(_ node: AVAudioNode) {
        _audioEngine.mutate { $0.detach(node) }
    }
    
    func connect(_ node1: AVAudioNode, to: AVAudioNode, format: AVAudioFormat?) {
        _audioEngine.mutate { $0.connect(node1, to: to, format: format) }
    }
    
    func disconnectNodeOutput(_ node: AVAudioNode) {
        _audioEngine.mutate { $0.disconnectNodeOutput(node) }
    }
}

// MARK: - Observer

extension AudioEngineManager {
    func registerObserver(_ observer: Observer, completion: ((Bool) -> Void)? = nil) {
        audioEngineQueue.async { [weak self] in
            guard let self = self else { return }
            let isInserted = self.audioEngineObservers.insert(observer).inserted
            try? self.startAudioEngine()
            
            completion?(isInserted)
        }
    }
    
    func removeObserver(_ observer: Observer, completion: ((Observer?) -> Void)? = nil) {
        audioEngineQueue.async { [weak self] in
            guard let self = self else { return }
            let removedObserver = self.audioEngineObservers.remove(observer)
            if self.audioEngineObservers.isEmpty {
                try? self.stopAudioEngine()
            }
            
            completion?(removedObserver)
        }
    }
}

private extension AudioEngineManager {
    func engineConfigurationChange(notification: Notification) {
        os_log("engineConfigurationChange: %{public}@", log: .audioEngine, type: .debug, "\(notification)")
        
        audioEngineQueue.async { [weak self] in
            do {
                try self?.startAudioEngine()
            } catch {
                os_log("audioEngine start failed: %{public}@", log: .audioEngine, type: .error, "\(error)")
                return
            }
            
            self?.audioEngineObservers.forEach { (observer) in
                observer.engineConfigurationChange(notification: notification)
            }
        }
    }
}

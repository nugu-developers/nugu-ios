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
    @Atomic private var audioEngineObservers = Set<Observer>()
    
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
    
    func startAudioEngine() throws {
        var engineError: Error!
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
            self?.audioEngineQueue.async { [weak self] in
                self?.engineConfigurationChange(notification: notification)
            }
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
    @discardableResult func registerObserver(_ observer: Observer) -> Bool {
        var isInserted = false
        _audioEngineObservers.mutate {
            isInserted = $0.insert(observer).inserted
        }
        try? startAudioEngine()
        
        return isInserted
    }
    
    @discardableResult func removeObserver(_ observer: Observer) -> Observer? {
        var removedObserver: Observer? = nil
        _audioEngineObservers.mutate {
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
        
        audioEngineObservers.forEach { (observer) in
            observer.engineConfigurationChange(notification: notification)
        }
    }
}

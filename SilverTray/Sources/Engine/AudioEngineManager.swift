//  limitations under the License.
//

import Foundation
import AVFoundation
import os.log

import NuguObjcUtils

class AudioEngineManager<Observer: AudioEngineObservable> {
    private var audioEngine = AVAudioEngine()
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
    
    func startAudioEngine() {
        audioEngineQueue.async { [weak self] in
            self?.internalStartAudioEngine()
        }
    }
    
    private func internalStartAudioEngine() {
        guard audioEngine.isRunning == false else { return }
        
        if let error = (UnifiedErrorCatcher.try {
            do {
                // start audio engine
                // This Api throws `Error` and raises `NSException` both.
                try audioEngine.start()
                
                os_log("audioEngine started", log: .audioEngine)
            } catch {
                return error
            }
            
            return nil
        }) {
            os_log("audioEngine start failed: %@", log: .audioEngine, type: .error, error.localizedDescription)
        }
        
        // if audio session is changed then influence to the AVAudioEngine, we should handle this.
        if let audioEngineConfigurationObserver = audioEngineConfigurationObserver {
            self.notificationCenter.removeObserver(audioEngineConfigurationObserver)
        }
        
        self.audioEngineConfigurationObserver = notificationCenter.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: audioEngine,
            queue: nil
        ) { [weak self] (notification) in
            self?.audioEngineQueue.async { [weak self] in
                self?.engineConfigurationChange(notification: notification)
            }
        }
    }
    
    func stopAudioEngine() {
        audioEngineQueue.async { [weak self] in
            self?.internalStopAudioEngine()
        }
    }
    
    private func internalStopAudioEngine() {
        // if audio session is changed then influence to the AVAudioEngine, we should handle this.
        if let audioEngineConfigurationObserver = self.audioEngineConfigurationObserver {
            notificationCenter.removeObserver(audioEngineConfigurationObserver)
        }
        
        if let error = (UnifiedErrorCatcher.try {
            // start audio engine
            audioEngine.stop()
            os_log("audioEngine stopped", log: .audioEngine)
            return nil
        }) {
            os_log("audioEngine start failed", log: .audioEngine, type: .error, error.localizedDescription)
        }
    }
}

// MARK: - AVAudioEngine wrapper

extension AudioEngineManager {
    func attach(_ node: AVAudioNode) {
        audioEngineQueue.async { [weak self] in
            self?.audioEngine.attach(node)
        }
    }
    
    func detach(_ node: AVAudioNode) {
        audioEngineQueue.async { [weak self] in
            self?.audioEngine.detach(node)
        }
    }
    
    func connect(_ node1: AVAudioNode, to: AVAudioNode, format: AVAudioFormat?) {
        audioEngineQueue.async { [weak self] in
            self?.audioEngine.connect(node1, to: to, format: format)
        }
    }
    
    func disconnectNodeOutput(_ node: AVAudioNode) {
        audioEngineQueue.async { [weak self] in
            self?.audioEngine.disconnectNodeOutput(node)
        }
    }
}

// MARK: - Observer

extension AudioEngineManager {
    func registerObserver(_ observer: Observer) {
        audioEngineQueue.async { [weak self] in
            self?.audioEngineObservers.insert(observer)
            self?.internalStartAudioEngine()
        }
    }
    
    func removeObserver(_ observer: Observer) {
        audioEngineQueue.async { [weak self] in
            guard let self = self else { return }
            if self.audioEngineObservers.remove(observer) == nil {
                os_log("[%@] removing observer failed", log: .player, "\(observer.id)")
            }
            
            if self.audioEngineObservers.isEmpty {
                self.internalStopAudioEngine()
            }
        }
    }
}

private extension AudioEngineManager {
    func engineConfigurationChange(notification: Notification) {
        os_log("engineConfigurationChange: %{private}@", log: .audioEngine, "\(notification)")
        startAudioEngine()
        
        audioEngineObservers.forEach { (observer) in
            observer.engineConfigurationChange(notification: notification)
        }
    }
}

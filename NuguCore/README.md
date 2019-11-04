# NuguCore
![Platform](https://img.shields.io/cocoapods/p/NuguCore)
![CocoaPods compatible](https://img.shields.io/cocoapods/v/NuguCore)
![License](https://img.shields.io/github/license/nugu-developers/nugu-ios)

Nugu framework for AI Service.

## Installation

### CocoaPods
NuguCore is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:
```ruby
pod 'NuguCore'
```

## SDK Components
### Capability Agents
#### AudioPlayer
AudioPlayerAgent handles directives for controlling audio playback.

```swift
// Suppose usage of NuguClient's default instance
let audioPlayerAgent = NuguClient.default.audioPlayerAgent!

// Set delegate for receiving events of media state change
class MyAudioPlayerAgentDelegate: AudioPlayerAgentDelegate {
    func audioPlayerAgentDidChange(state: AudioPlayerState) {
        // Update player's displaying UI with AudioPlayerState state appropriately
    }
}
audioPlayerAgent.delegate = MyAudioPlayerAgentDelegate()

// play/pause/stop/previous/next request
audioPlayerAgent.request(command: .pause)
```

AudioPlayerAgent also handles directives for controlling player template display.

```swift
// Suppose usage of NuguClient's default instance
let audioPlayerAgent = NuguClient.default.audioPlayerAgent!

// Synchronize SDK's player UI state with AudioPlayerDisplayDelegate
class MyAudioPlayerDisplayDelegate: AudioPlayerDisplayDelegate {
    func audioPlayerDisplayShouldRender(template: DisplayPlayerTemplate) -> Bool {
        // Return false if player's UI is unnecessary
        return true
    }

    func audioPlayerDisplayDidRender(template: AudioPlayerDisplayTemplate) {
        // Draw player's UI with AudioPlayerDisplayTemplate
    }

    func audioPlayerDisplayShouldClear(template: AudioPlayerDisplayTemplate) -> Bool {
        // Return false if player's UI is not ready to be clear
        return true
    }

    func audioPlayerDisplayDidClear(template: AudioPlayerDisplayTemplate) {
        // Clear player's UI
    }
}
audioPlayerAgent.addDisplay(delegate: AudioPlayerDisplayTemplate())
```

#### ASR(AutomaticSpeechRecognition)
ASRAgent delivers user's voice to server and handles voice recognition results or continuous speech directives.

```swift
// Suppose usage of NuguClient's default instance
let asrAgent = NuguClient.default.asrAgent!

// Add delegate for speech recognition result receive
class MyAsrASRAgentDelegate: ASRAgentDelegate {
    func asrAgentDidReceive(result: ASRResult) {
        switch result {
        case .complete(let text):
            // Handle reconized final result of voice recognition
            break
        case .partial(let text):
            // Handle partialy recognized voice dynamically
            break
        case .responseTimeout:
            // No result from server until timeout
            break
        case .listeningTimeout:
            // User did not speak at all until timeout
            break
        default: 
            // States will be added
            break
        }
    }
}
asrAgent.add(delegate: MyAsrASRAgentDelegate())

// Start voice recognition
asrAgent.recognize()
```

#### Display
DisplayAgent handles directives for controlling template display.

```swift
// Suppose usage of NuguClient's default instance
let displayAgent = NuguClient.default.displayAgent!

// Synchronize SDK's display template UI state with DisplayAgentDelegate
class MyDisplayAgentDelegate: DisplayAgentDelegate {
    func displayAgentShouldRender(template: DisplayTemplate) -> Bool {
        // Return false if display template's UI is unnecessary
        return true
    }

    func displayAgentDidRender(template: DisplayTemplate) {
         // Draw display template UI with DisplayTemplate
    }

    func displayAgentShouldClear(template: DisplayTemplate) -> Bool {
        // Return false if display template UI is not ready to be clear
        return true
    }

    func displayAgentDidClear(template: DisplayTemplate) {
        // Clear display template UI
    }
}
displayAgent.add(delegate: MyDisplayAgentDelegate())
```

#### Extension
Extension delivers custom action directives which were previously promised in Play Builder or Backend proxy for appliction to handle it's own actions.

```swift
// Suppose usage of NuguClient's default instance
let extensionAgent = NuguClient.default.extensionAgent!

// Set delegate for receiving extension directives
class MyExtensionAgentDelegate: ExtensionAgentDelegate {
    func extensionAgentDidReceive(data: [String: Any], playServiceId: String, completion: @escaping (Bool) -> Void) {
        // Should return false if actions or data can not be handled
        completion(true)
    }
}
```

#### Text
TextAgent delivers user's text command to server and handles result directives of text command recognition result.

```swift
// Suppose usage of NuguClient's default instance
let textAgent = NuguClient.default.textAgent!

// Add delegate for receiving text command recognition results
class MyTextAgentDelegate: TextAgentDelegate {
    func textAgentDidReceive(result: TextAgentResult) {
        switch result {
        case .complete:
            // Text command recognition success
            break
        case .responseTimeout:
            // No result from server until timeout
            break
        }
    }
}
textAgent.add(delegate: MyTextAgentDelegate())

// Send text command to server
textAgent.recognize(text: command)
```

#### TTS(TextToSpeech)
TTSAgent handles directives for controlling speech playback.

```swift
// Suppose usage of NuguClient's default instance
let ttsAgent = NuguClient.default.TTSAgent!

// Request for text-to-speech message generation and play
ttsAgent.requestTTS(text: text)
```

### AuthorizationManager
To be updated

### NetworkManager
To be updated

## License
The contents of this repository is licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

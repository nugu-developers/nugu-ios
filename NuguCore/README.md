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
The AudioPlayerAgent handles directives for controlling audio playback.

```swift
// NuguClient의 default 인스턴스 사용을 가정합니다.
let audioPlayerAgent = NuguClient.default.audioPlayerAgent!

// 미디어 재생 상태 변경 이벤트를 받기위한 delegate 를 등록합니다.
class MyAudioPlayerAgentDelegate: AudioPlayerAgentDelegate {
    func audioPlayerAgentDidChange(state: AudioPlayerState) {
        // DialogPlayerAgent 를 통해 display 중인 player 정보를 state 에 따라 업데이트 합니다.
    }
}
audioPlayerAgent.delegate = MyAudioPlayerAgentDelegate()

// 재생/일시정지/정지/이전/다음 요청
audioPlayerAgent.request(command: .pause)
```

The AudioPlayer handles directives for controlling player template display.

```swift
// NuguClient의 default 인스턴스 사용을 가정합니다.
let audioPlayerAgent = NuguClient.default.audioPlayerAgent!

// AudioPlayerDisplayDelegate 을 통해 player 에 대한 UI 구성 상태를 SDK 와 동기화 합니다.
class MyAudioPlayerDisplayDelegate: AudioPlayerDisplayDelegate {
    func audioPlayerDisplayShouldRender(template: DisplayPlayerTemplate) -> Bool {
        // UI 를 구성하지 않으려면 false 를 반환해야 합니다.
        return true
    }

    func audioPlayerDisplayDidRender(template: AudioPlayerDisplayTemplate) {
        // UI 를 구성합니다.
    }

    func audioPlayerDisplayShouldClear(template: AudioPlayerDisplayTemplate) -> Bool {
        // UI 를 유지하려면 false 를 반환해야 합니다.
        return true
    }

    func audioPlayerDisplayDidClear(template: AudioPlayerDisplayTemplate) {
        // UI 를 제거합니다.
    }
}
audioPlayerAgent.addDisplay(delegate: AudioPlayerDisplayTemplate())
```

#### ASR(AutomaticSpeechRecognition)
ASRAgent 는 사용자 음성을 서버로 전송하고 음성 인식 결과 및 연속 발화 directive 를 처리합니다.

```swift
// NuguClient의 default 인스턴스 사용을 가정합니다.
let asrAgent = NuguClient.default.asrAgent!

// 음성 인식 결과를 받기위한 delegate 를 등록합니다.
class MyAsrASRAgentDelegate: ASRAgentDelegate {
    func asrAgentDidReceive(result: ASRResult) {
        switch result {
        case .complete(let text):
            // 최종 인식 결과 처리.
            break
        case .partial(let text):
            // 부분 인식 결과 업데이트.
            break
        case .responseTimeout:
            // 서버 응답 없음.
            break
        case .listeningTimeout:
            // 사용자가 발화를 하지 않음.
            break
        default: 
            // 화자 인식 등 추후 업데이트 될 기능을 위한 state.
            break
        }
    }
}
asrAgent.add(delegate: MyAsrASRAgentDelegate())

// 음성 인식을 시작합니다.
asrAgent.recognize()
```

#### Display
The DisplayAgent handles directives for controlling template display.

```swift
// NuguClient의 default 인스턴스 사용을 가정합니다.
let displayAgent = NuguClient.default.displayAgent!

// DisplayAgentDelegate 을 통해 template 에 대한 UI 구성 상태를 SDK 와 동기화 합니다.
class MyDisplayAgentDelegate: DisplayAgentDelegate {
    func displayAgentShouldRender(template: DisplayTemplate) -> Bool {
        // UI 를 구성하지 않으려면 false 를 반환해야 합니다.
        return true
    }

    func displayAgentDidRender(template: DisplayTemplate) {
        // UI 를 구성합니다.
    }

    func displayAgentShouldClear(template: DisplayTemplate) -> Bool {
        // UI 를 유지하려면 false 를 반환해야 합니다.
        return true
    }

    func displayAgentDidClear(template: DisplayTemplate) {
        // UI 를 제거합니다.
    }
}
displayAgent.add(delegate: MyDisplayAgentDelegate())
```

#### Extension
Play Builder 및 Backend proxy 에서 정의한 custom action 을 application 에서 처리 할 수 있도록 directive 를 전달합니다.

```swift
// NuguClient의 default 인스턴스 사용을 가정합니다.
let extensionAgent = NuguClient.default.extensionAgent!

// directive 를 전달받기 위해 delegate 를 등록합니다.
class MyExtensionAgentDelegate: ExtensionAgentDelegate {
    func extensionAgentDidReceive(data: [String: Any], playServiceId: String, completion: @escaping (Bool) -> Void) {
        // action 및 data 를 처리할 수 없다면 false 를 전달해야 합니다.
        completion(true)
    }
}
```

#### Text
TextAgent 는 텍스트 명령을 서버로 전송하고 텍스트 명령 인식 결과 directive 를 처리합니다.

```swift
// NuguClient의 default 인스턴스 사용을 가정합니다.
let textAgent = NuguClient.default.textAgent!

// 텍스트 명령 인식 결과를 받기위한 delegate 를 등록합니다.
class MyTextAgentDelegate: TextAgentDelegate {
    func textAgentDidReceive(result: TextAgentResult) {
        switch result {
        case .complete:
            // 텍스트 명령 인식 성공
            break
        case .responseTimeout:
            // 서버 응답 없음.
            break
        }
    }
}
textAgent.add(delegate: MyTextAgentDelegate())

// 텍스트 명령 서버 전송
textAgent.recognize(text: command)
```

#### TTS(TextToSpeech)
The TTSAgent handles directives for controlling speech playback.

```swift
// NuguClient의 default 인스턴스 사용을 가정합니다.
let ttsAgent = NuguClient.default.TTSAgent!

// text 에 대한 음성 합성 및 재생을 요청합니다.
ttsAgent.requestTTS(text: text)
```

### AuthorizationManager
작성예정

### NetworkManager
작성예정

## License
The contents of this repository is licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

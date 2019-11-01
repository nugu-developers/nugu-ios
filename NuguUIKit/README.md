# NuguUIKit
![Platform](https://img.shields.io/cocoapods/p/NuguUIKit)
![CocoaPods compatible](https://img.shields.io/cocoapods/v/NuguUIKit)
![License](https://img.shields.io/github/license/nugu-developers/nugu-ios)

Provides default instances for using Nugu service 

## Installation

### CocoaPods
NuguUIKit is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:
```ruby
pod 'NuguUIKit'
```

## Dependency
NuguUIKit has dependency on [Lottie](https://github.com/airbnb/lottie-ios) for NuguVoiceChrome animation

## Usage
### Initialize
> By Code
```swift
import NuguUIKit

let recommendedNuguVoiceChromeFrame = CGRect(x: 0, y: view.frame.size.height, width: view.frame.size.width, height: NuguVoiceChrome.recommendedHeight + bottomSafeAreaHeight)
var nuguVoiceChrome = NuguVoiceChrome(frame: recommendedNuguVoiceChromeSize)
```
> By Storyboard
```
Place UIButton or UIView in storyboard and change it's class to NuguButton or NuguVoiceChrome (from NuguUIKit module) in storyboard's Custom Class section
```

>  **NuguButton and NuguVoiceChrome are designed in accordance with recommended size
<br>Note that NuguButton and NuguVoiceChrome might look awkward in other sizes**

### NuguButton
```swift
    // MARK: Customizable Properties
    
    @IBInspectable
    public var startColor: UIColor = UIColor(red: 0.0, green: 157.0/255.0, blue: 1.0, alpha: 1.0)
    
    @IBInspectable
    public var endColor: UIColor = UIColor(red: 0.0, green: 157.0/255.0, blue: 1.0, alpha: 1.0)
    
    // MARK: - Public Methods

    public func startListeningAnimation()
    public func stopListeningAnimation()
```
### NuguVoiceChrome
```swift
    // MARK: Customizable Properties
    
    public var onCloseButtonClick: (() -> Void)?
    
    // MARK: - Public Methods

    public func changeState(state: NuguVoiceChrome.State)
    public func setRecognizedText(text: String?)
    public func minimize()
    public func maximize()
```
```swift
public extension NuguVoiceChrome {
    enum State {
        case listeningPassive
        case listeningActive
        case processing
        case speaking
        case speakingError
    }
}
```

## License

The contents of this repository is licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

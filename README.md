# nugu-ios
[![Build Status](https://travis-ci.org/nugu-developers/nugu-ios.svg?branch=master)](https://travis-ci.org/nugu-developers/nugu-ios)
![Platform](https://img.shields.io/badge/platform-iOS-999999)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/NuguClientKit)](https://github.com/nugu-developers/nugu-ios)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![License](https://img.shields.io/github/license/nugu-developers/nugu-ios)

## Requirements
- iOS 10.0+
- Xcode 11.0+
- Swift 5.1+

## Components
NUGU SDK for iOS is composed of following Libraries 
- [NuguCore](NuguCore/) - Main Framework of NUGU SDK, which has implementation of core functions such as network management, data transmission, media control, etc
- [NuguAgents](NuguAgents/) - The Framework which includes built-in capability-agents.
- [NuguClientKit](NuguClientKit/) - The Framework for initializing essential components and inject dependency between components to use NUGU SDK
- [NuguLoginKit](NuguLoginKit/) - The Framework for user authentication with OAuth2.0
- [NuguUIKit](NuguUIKit/) - The Framework for user interface components
- [NuguServiceKit](NuguServiceKit/) - The Framework provides customized webview for NUGU service

## Sample Application

### Run
We have sample application in `nugu-ios.xcodeproj`.  
To use it download or clone this repository, and run `carthage update --platform iOS` to install required frameworks.  
Open `nugu-ios.xcodeproj` and you can run it through `SampleApp` scheme.

### See also
Unfortunately, we still have some step to use sample application.
For more information, See the [How to use sample application](https://github.com/nugu-developers/nugu-ios/wiki/How-to-use-sample-application).

## Installation

### CocoaPods
Each components of `NUGU SDK for iOS` is available through [CocoaPods](https://cocoapods.org).  
To install it for easy use, simply add the following line to your `Podfile`:  

```ruby
pod 'NuguClientKit'
```

### Carthage
NUGU SDK for iOS is available through [Carthage](https://github.com/Carthage/Carthage).  
To install it, add the following line to your `Cartfile`:  

```
github "nugu-developers/nugu-ios"
```

Then run `carthage update --platform iOS`.  
If your application is first time adopting carthage, you'll need to set additional steps.  
For more information, See the [Carthage for Application](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)  

## Usage

### Get Started
Using `NUGU SDK for iOS` is easy after some setup.
Here are some basic examples for some capability-agent.
#### Initialize & Enable
Before using `NUGU SDK for iOS`, enable to nugu when using NuguClientKit. like this:
```swift 
class SomeClass: NuguClientDelegate {
    let client = NuguClient(delegate: self)
    ...
}
```

#### Using ASRAgent (Automatic Speech Recognition Agent)
```swift
guard let epdFile = Bundle.main.url(forResource: "skt_epd_model", withExtension: "raw") else {
    log.error("EPD model file not exist")
    return
}
let options = ASROptions(initiator: .user, endPointing: .client(epdFile: epdFile))
client.asrAgent.startRecognition(options: options)
```

### See also
For more information, See the [How to use NUGU SDK for iOS](https://github.com/nugu-developers/nugu-ios/wiki/How-to-use-NUGU-SDK-for-iOS)

## License
The contents of this repository is licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## See Also
Please visit [Nugu Developers Guide page](https://developers-doc.nugu.co.kr/nugu-sdk/platform/ios)

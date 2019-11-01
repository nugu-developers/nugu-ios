# NuguClientKit
![Platform](https://img.shields.io/cocoapods/p/NuguClientKit)
![CocoaPods compatible](https://img.shields.io/cocoapods/v/NuguClientKit)
![License](https://img.shields.io/github/license/nugu-developers/nugu-ios)

Provides nugu-client instances for using Nugu service.

## Installation

### CocoaPods
NuguClientKit is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:
```ruby
pod 'NuguClientKit'
```

## Component Libraries
NUGU SDK is composed of following Libraries 
- [NuguLoginKit](https://github.com/nugu-developers/nugu-login-kit-ios) - Library for user authentication with OAuth2.0
- [NuguClientKit](https://github.com/nugu-developers/nugu-client-kit-ios) - Library for initializing essential components and inject dependency between components to use NUGU SDK
- [NuguInterface](https://github.com/nugu-developers/nugu-interface-ios) - Library which includes protocols, enums, structs of public components of NUGU SDK 
- [NuguCore](https://github.com/nugu-developers/nugu-core-ios) - Main library of NUGU SDK, which has implementation of core functions such as network management, data transmission, media control, etc
- [KeenSense](https://github.com/nugu-developers/keen-sense-ios) - Library for detecting keywords such as "Tinkerbell", "Aria" 
- [JadeMarble](https://github.com/nugu-developers/jade-marble-ios) - Library for detecting end point of user speech

## Example
To run the example project, clone the repo, and run `pod install` from the Example directory.

## License
The contents of this repository is licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

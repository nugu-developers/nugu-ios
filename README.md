# nugu-ios
![Swift](https://img.shields.io/badge/swift-5.1-orange) ![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)

## Requirements
- iOS 10.0+
- Xcode 11.0+
- Swift 5.1+

## Components
NUGU SDK for iOS is composed of following Libraries 
- [NuguUIKit](NuguUIKit/) - Library for user interface components
- [NuguLoginKit](NuguLoginKit/) - Library for user authentication with OAuth2.0
- [NuguClientKit](NuguClientKit/) - Library for initializing essential components and inject dependency between components to use NUGU SDK
- [NuguInterface](NuguInterface/) - Library which includes protocols, enums, structs of public components of NUGU SDK 
- [NuguCore](NuguCore/) - Main library of NUGU SDK, which has implementation of core functions such as network management, data transmission, media control, etc
- [KeenSense](KeenSense/) - Library for detecting keywords such as "Tinkerbel", "Aria" 
- [JadeMarble](JadeMarble/) - Library for detecting end point of user speech

## License

The contents of this repository is licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## See Also
Please visit [Nugu Developers Guide page](https://developers-doc.nugu.co.kr/nugu-sdk/platform/ios)

# Change Log
All notable changes to this project will be documented in this file.
`NUGU SDK for iOS` adheres to [Semantic Versioning](https://semver.org/).

---
## [0.6.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.6.1)
Released on 2019-11-17

#### Fixed
- Make `JadeMarble` and `KeenSense` not to be stuck in their `RunLoop`.

#### Updated
- Updates model related `LocationAgent` and `PermissionAgent`.

## [0.6.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.6.0)
Released on 2019-11-15

#### Fixed
- Stop `BoundStreams` before creating new instance. (#89)

## [0.5.3](https://github.com/nugu-developers/nugu-ios/releases/tag/0.5.3)
Released on 2019-11-15

#### Fixed
- Call `TycheEpd.stop()` and `TycheKwd.stop()` method as appropriate. (#87)

## [0.5.2](https://github.com/nugu-developers/nugu-ios/releases/tag/0.5.2)
Released on 2019-11-15

#### Fixed
- Deallocates `NuguApiProvider` instance after calling `NuguApiProvider.disconnect()`. (#79)
- Deallocates `ASRExpectSpeech` instance from `ASRAgent.stopRecognition()`. (#81)

#### Updated
- Updates `xcodeproj` for ordering files.

## [0.5.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.5.1)
Released on 2019-11-14

#### Added
- Adds `ISSUE_TEMPLATE` .
- Implements `PermissionAgent`.

#### Updated
- Updates model for `LocationAgent`.

## [0.5.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.5.0)
Released on 2019-11-13

#### Fixed
- Fixes a bug where `ASRState` doesn't change to listening when network condition is bad. (#62)
- Fixes a bug that `KeyWordDetector` should change it's state when it stopped.

#### Updated
- Separate `JadeMarble` & `KeenSense` from `NUGU` echo system. (#56)

## [0.4.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.4.1)
Released on 2019-11-12

#### Added
- Support `Carthage`

#### Fixed
- Fixes a bug that was not handled when the `ASRResult` was the same as before.
- Fixes event name in `ASRAgent`. (#50)

#### Updated
- Restructure project based `Carthage`. (#46) (#47)
- Deprecates `System.Revoke` directive. (#42)
- Refactor related directives.
- Disable travis temporary.

## [0.4.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.4.0)
Released on 2019-11-06

#### Added
- Enable travis. (#26)

#### Fixed
- Fixes `DirectiveMedium` so that `TTS.Stop` directive does not blocked. (#35)

#### Updated
- Updates project setting. (#38)
- Make stream start/stop order to be strict. (#39)

## [0.3.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.3.0)
Released on 2019-11-01

#### Fixed
- Fixes an issue where delegate was not called because `currentMedia` is nil. (#25)

#### Updated
- Renames `ProvideContextDelegate` to `ContextInfoDelegate`. (#28)
- Renames `ExtensionAgentDelegate.extensionAgentDidReceive` to `ExtensionAgentDelegate.extensionAgentDidReceiveAction`. (#27)

## [0.2.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.2.0)
Released on 2019-10-31

#### Added
- Initial release of NUGU SDK for iOS.

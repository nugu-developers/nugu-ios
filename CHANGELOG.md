# Change Log
All notable changes to this project will be documented in this file.
`NUGU SDK for iOS` adheres to [Semantic Versioning](https://semver.org/).

---
## [0.16.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.16.0)
Released on 2020-08-04
#### Fixed
- [NuguCore] Fix bugs about layer policy.  (#397) (#398) 

#### Updated
- [NuguCore] Apply layer policy v1.4.6 (#397) (#414) (#417)
- [NuguCore] Cancel directive when associated directive was canceled. (#415) 
- [NuguAgents] Add `defaultDisplayTempalteDuration` property to `DisplayAgent` (#396)
- [NuguClientKit] Add `nuguClientWillSend` function to `NuguClientDelegate` (#399) 
- [NuguAgents] `SystemAgent` 1.3 (upgrade capability-agent) (#401)
- [NuguAgents] Add `isSeekable` variable to `AudioPlayerDisplayTemplate` (#406)
- [NuguUIKit] Remove chips count limit (#411)
- [NuguUIKit] Update lottie animation files (#407)
- [Sample] Open mic from application. (#423) (#424) (#429)

#### Added
- [NuguAgents] Implement `MediaPlayerAgent` (#418)

## [0.15.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.15.0)
Released on 2020-07-10
#### Fixed
- Make streams thread safe (#387) 
- Add `WeakScriptMessageHandler` to `NuguServiceKit`to solve memory leak (#385) 

#### Updated
- Change audioplayer's favorite / repeat / shuffle methods (#384)
- Apply layer policy v1.4.4 (#386)
- Upgrade `NuguServiceKit` and apply to `SampleApp` (#388)
- Adopt blocking policy in `PhoneCallAgent` (#389)
- Update `SendCandidates` event in `PhoneCallAgent` (#389)

## [0.14.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.14.0)
Released on 2020-07-03
#### Fixed
- Handle exception during creating input node (#372) 
- Make `boundStreams` thread-safety (#371) 
- Remove `wakeupWord` in `context` when `KeywordDetector` disabled. (#368)
- Modify data structure of multi-part data. (#380)

#### Updated
- Remove `textSource`, `icon` and `image` on `ChipsAgentItem.Chip`. (#369)
- Modify `DisplayAgentDelegate` and `AudioPlayerDisplayDelegate` (#381)

#### Added
- Add `PhoneCallAgent` 1.0 (upgrade capability-agent) (#374) (#375) (#376) (#377) (#379)
- Apply `NuguServiceKit` to `SampleApp` (#378)

## [0.13.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.13.0)
Released on 2020-06-19
#### Fixed
- Fixes a bug where the session does not deactivaed. (#356)
- Fixes a crash in `PlayStackManager`. (#357)
- Fixes a bug about lifecycle of `Session` (#364)
- Remove `Runloop` controls to fix crashes (#355) 

#### Updated
- Update `SystemAgentRevokeReason` to add `unknown`case (#352)
- Update `NuguLoginKitError` to add `errorCode` (#353)
- Apply context policy(v.1.4.0) (#354)
- Update `DialogState` to add `chips` parameter (#360)
- Rename from `didFinishSafariViewController` to `cancelled` (#359)
- Update `SettingViewController` (#362) 

#### Added
- Add `NuguServiceKit` (#361) 

## [0.12.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.12.0)
Released on 2020-06-08
#### Fixed
- Fixes a bug where the connection timeout occurs before the `ASR.ListenTimeout` period is reached. (#333)
- Fix HideRyrics directive name to HideLyrics (#347)

#### Updated
- Update `TTSAgent` 1.2 (upgrade capability-agent) (#334)
- Apply `SystemAgent` v1.2 to `Sample App` (`SystemAgentRevokeReason`) (#331)
- Add `os` parameter to `context/client` in event body. (#336)
- Update `DisplayAgent` from v1.2 to v1.4 (upgrade capability-agent) (#339)

#### Added
- Add `SessionAgent` 1.0 (upgrade capability-agent) (#335)
- Add `ChipsAgent` 1.0 (upgrade capability-agent) (#340)
- Add APIs in `NuguLoginKit` (#345) 

#### Removed
- Remove `System.SynchronizedState` event that is called when initializing `NuguClient`. (#332)

## [0.11.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.11.0)
Released on 2020-05-26
#### Fixed
- Fixes a bug where `DisplayAgent.handleControlScroll` doesn't call completion handler. (#310)
- Fixes a bug where `AudioPlayerAgent` doesn't release `MediaPlayer`. (#322)

#### Updated
- Update `AudioPlayerAgent` 1.3 (upgrade capability-agent) (#317)
- Update voice chrome view. (#316)
- Update display and audio template views. (#304)(#321)
- Make `NuguOAuthClient.deviceUniqueId` mutable (#313)
- Update `SystemAgent` 1.2 (upgrade capability-agent) (#320)

#### Removed
- Move `OpusPlayer` to https://github.com/nugu-developers/silvertray-iOS (#314)

## [0.10.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.10.0)
Released on 2020-04-24

#### Fixed
- Fix bug where `client` value in `context` is null. (#291)
- Fixes a error that recognized text is not displayed in DM state. (#294)
* Fixes a `EXC_BAD_ACCESS` crash in `PlaySyncManager.swift` (#299)
* Fixes a `EXC_BAD_ACCESS` crash in `StreamDataRouter.swift` (#299)

#### Updated
- Update `ASRAgent` to support server side EPD (#288) (#294)
- Include all of the context when sending `Display.ElementSelected` event.  #(286)
- Include all of the capability interface's version when sending any event. #(286)
- Modify `Content-Type` header for upstream attachment. (#287) (#299)
- Modify `payload` type from `String` to `Data` in `Downstream.Directive` (#292)
- Modify type of `DirectiveHandleInfo.preFetch` and `DirectiveHandleInfo.directiveHandler` (#292)
- Modify comparison logic for resuming `AudioPlayerAgent`'s media player. (#292)
- Develop media caching feature (#269) (#293) 
- Modify `AudioStreamDelegate` in `NuguClient` to start and stop `AudioProvidable` synchronously. (#300)
- Remove `timeoutInMilliseconds` in `ASRExpectSpeech` (#303)
- Update `NuguUIKit` (#296) (#302)
- Move `Keyword` enum from `KeenSense` to `SampleApp` (#301)

#### Added
- Add `SoundAgent` (upgrade capability-agent) (#292)

## [0.9.2](https://github.com/nugu-developers/nugu-ios/releases/tag/0.9.2)
Released on 2020-04-06

#### Fixed
- Fixes a error that recognized text is not displayed in DM state. (#289)

## [0.9.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.9.1)
Released on 2020-04-02

#### Fixed
- Fixes a crash issue in `NuguApiProvider` (#284)

## [0.9.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.9.0)
Released on 2020-04-01

#### Fixed
- Fix memory leak issues. (#257)

#### Updated
- Update `DisplayAgent` to version 1.2 (#187)(#212) (#187)(#242) (#272)
- Update `ASRAgent` to version 1.1 (#248)
- Update `TextAgent` to support `Text.TextSource` directive. (#246)
- Apply device-gateway v2 APIs. (#247) (#259) (#268) (#264) (#271) (#268) (#274)
- Update `SystemAgent` to version 1.1 (#256)(#261)
- Update `AudioPlayerAgent` to 1.1 (#252)(#253)
- Update `AudioPlayerAgent` to 1.2 (#262)(#280)
- Update blocking policy (#250) (#266)
- Update `AudioPlayerAgent` to support TTS attachment (#275)
- Update `TextAgent` to version 1.1 (#270)
- Adopt `ReferrerDialogRequestIdD` in capability-agents (#273)
- Apply context policy v1.2.9 (#240) 

#### Added
- Add test-case for capability-agents (#241) (#254)

#### Removed
- Remove `address` property from `ServerPolicy` (#267)
- Remove `SpeakerAgent` (#276)

## [0.8.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.8.0)
Released on 2020-02-27

#### Fixed
- Fix `TTSAgent` bug where `completion` is not called. (#136)
- Fix event payload in `TTSAgent` (#140)
- Fix `DisplayAgent` bug where deallocated observer is not called. (#167)
- Fix a bug where `TTSState` does not set properly. (#173)
- Fix `TextAgent` bug in initializer (#195)

#### Updated
- Update `DisplayAgent` to version 1.1 (#153)
- Update `ExtensionAgent` to version 1.1 (#179) 
- Separate `NuguCore` and `NuguAgents` (#196) 
- Update `SystemAgent` for sending extra error code (#105) (#124) 
- Improve `JadeMarble` and `KeenSense` for API Stability (#130) (#131)
- Refactor related to `ContextManager` (#91) (#133)
- Update `LocationAgent` by changed location Interface (#19) (#138)
- Update `TimeUUID` version from 1 to 2. (#183) 
- Move variables related `NattyLog` to global variables (#151) (#152)
- Move `EndPointDetector` to `NuguCore` (#180) 
- Move `DialogStateAggregator` from `NuguCore` to `NuguClientKit` (#177)
- Update `LoginError` to be more detailed (#197) 
- Refactoring `MediaPlayable` (#122) (#123)
- Refactoring `FocusChannelConfigurable` (#156) (#158) 
- Refactoring `AuthorizationManager`. (#145) (#176) 

#### Added
- Adds `CHANGELOG.md` (#18) (#125)
- Adds `PULL_REQUEST_TEMPLATE.md` (#154) (#159)
- Add `DownStreamDataTimeoutPreprocessor` to drop the timed out messages (#118)
- Add `cancelAssociation` parameter to `TTS.stop` to call `PlaySyncManager.releaseSyncImmediately` properly. (#161)
- Generate 'Device-Uniqud-Id' in `NuguLoginKit` (#104) (#163) 
- Add `.travis.yml` for Travis-CI (#204)
- Add test-case for `LocationAgent`, `SystemAgent`, `ExtensionAgent`, `TextAgent`  (#210)(#211) (#221)(#222)

#### Removed
- Remove `NuguInterface` (#196)
- Remove `PermissionAgent` (#60) (#135)
- Remove `CapabilityConfigurable` protocol (#169) 

## [0.7.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.7.1)
Released on 2020-02-20

#### Fixed
- Fix `TTSAgent` bug where `completion` is not called. (#136)

## [0.7.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.7.0)
Released on 2019-11-29

#### Fixed
- Fix to release audio stream when Tyche engine initialize failed. (#114)

#### Updated
- Removes `lottie-ios` dependency. (#76)
- Remove related `Nugu-Info.plist`. (#109)
- Adds `TimeIntervallic` protocol and `NuguTimeInterval` structure. (#111)
- Adds `DownStreamDataInterpreter` to decode downloaded data. (#113)
- Add a `focusShouldRelease()` function to `FocusManageable` to notify that audio-session was completed. (#119)

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
- Fixes a bug that `KeywordDetector` should change it's state when it stopped.

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

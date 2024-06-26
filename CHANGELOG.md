# Change Log
All notable changes to this project will be documented in this file.
`NUGU SDK for iOS` adheres to [Semantic Versioning](https://semver.org/).

---
## [1.4.0](https://github.com/nugu-developers/nugu-ios/releases/tag/1.4.0)
Released on 2021-07-26
### SDK
#### Fixed
- Send `dialog_request_id` when loading `NuguDisplayWebView` (#883)
- Apply `RxSwift` version 6 (#881)
- Send stop / start event instead resume event (#884)
- Fix the state change from `.playing` to `.playing` in `RoutineAgent` (#885)

#### Added
- Add `TabExtension` to `DisplayAgent` (upgrade to v1.8) (#880)
- Add `ignoreSendingResumeEvent` variable (#882)

#### Update
- Supports `Swift package manager` (#886)
- Refactor `NuguClientKit` and `MainViewController` (#888)

#### Removed
- Remove useless `preserved_path` statement in podspec files (#892)

## [1.3.0](https://github.com/nugu-developers/nugu-ios/releases/tag/1.3.0)
Released on 2021-06-28
### SDK
#### Fixed
- Fix to optional `try` (#863)
- Do not remove voiceChrome from superview if `isHidden` value of `VoiceChromePresenter` is false (#869)
- Fix memory issue in NuguOAuthClient (#867) (#872)
- Cancel `URLSessionDataTask` for server side event when it does not needed anymore. (#871)

#### Added
- Add `NuguThemeController` to `NuguClientKit` (#853)
- Support AudioDisplayView dark mode (#854)
- Add routine related javascript methods to `NuguServiceWebView` (#858)
- Add `UserInterfaceUtil` to `NuguUtils`

#### Update
- Add place holder image and default (failure) image to 'DisplayTitleView` (#847)
- Ugrade target version from 10.0 to 12.0 (#848)
- Change `TycheKeywordDetector`'s notification mechanism from `Delegate pattern` to `Observer pattern` (#849)
- Remain last server policy to use next time. (#851) 
- Notify `ServerInitiatedDirectiveReceiverState` (#860)
- Update `RoutineState` (#862)

#### Removed
- Remove codes supporting lower than iOS 12.0 version (#852)  
- Remove outdated version codes (#855) 


## [1.2.0](https://github.com/nugu-developers/nugu-ios/releases/tag/1.2.0)
Released on 2021-05-25
### SDK
#### Fixed
- Fix Nudge-recommended chips issue
- Apply Swift 5.5
- Fix lylics issue

#### Added
- Add `AlertAgent`

#### Update
- Update Cookie settings in` NuguServiceWebView`

## [1.1.0](https://github.com/nugu-developers/nugu-ios/releases/tag/1.1.0)
Released on 2021-04-27
### SDK
#### Fixed
- Fix `AVMediaPlayerItem` Observation defeat

#### Added
- Add landscape mode of `AudioPlayerView` and `DisplayWebView`
- Add `NudgeAgent`

## [1.0.0](https://github.com/nugu-developers/nugu-ios/releases/tag/1.0.0)
Released on 2021-03-30
### Sample Application
#### Fixed
- Remove `refreshToken` validation when login anonymously. (#735)
- Log out when auth error has occurred in `getUserInfo` api (#787)
- Remove `pod_end_error.wav` from sample application (#793)
- Resolve performSegue crash issue (#794)

#### Update
- Use NotificationCenter rather than Delegate set. (#702) (#712)
- Migrate audio session manager to `NuguClientKit` (#707)
- Rename extended function of `NuguOAuthClient` (#720)
- Apply Builder pattern on `NuguClient` (#743)
- Use `NuguServiceWebView` in `GuideWebViewController` for `close(reason: wake_up)` javascript support (#756) (#772)
- Add `deviceUniqueId` variable to `NuguServiceCookie` (#778)

#### Removed
- Remove `watermarkLabel` and `textInputTextField` to minimize sample application. (#749)
- Move `UITapGestureRecognizer` from `Application` to `VoiceChromePresenter` for convenience. (#738)
- Put the resources for signal processing into the frameworks (#752)
- Migrate `ASRBeepPlayer` into `VoiceChromePresenter` of `NuguClientKit` (#760)
- Migrate `NuguDisplayPlayerController` into `NuguClientKit` as `ControlCenterManager` (#759)
- Remove calling `startReceiveServerInitiatedDirective` and `stopReceiveServerInitiatedDirective` function from `SampleApp`. (#802)

### SDK
#### Fixed
- Fix to handle error for login (#780)
- Resolve lyrics view related issues (#785)
- Hide progressview in bar type audio player when isSeekable is false (#786)
- Change max text line of `AudioPlayer2View` (#788)
- Set `isScrolling` value as false when automatic scrolling ends (#789)
- Add `MarqueeLabel` to `NuguUIKit` (#791)
- Make `AudioDisplayView`'s `setFullMode()` as public method, and set bar mode as it's initial mode (#792)
- Resolve `NuguDisplayWebView` memory leak issue (#796)
- Fixes a typo in `AuthorizationInfo.availableServerInitiatedDirective` property. (#802)
- Fixes a bug when casting 'Any' to 'Error'. (#803) (#804))

#### Added
- Add `UtilityAgent` 1.0 (upgrade capability-agent) (#695)
- Add `MessageAgent` 1.4 (upgrade capability-agent) (#713) (#766)

#### Update
- Use NotificationCenter rather than Delegate set. (#702) (#712) (#710) (#730) (#750)
- Include full context for sending `ASR.ListenTimeout`. (#705)
- Add `NuguToast.Duration` (#708)
- Migrate audio session manager to `NuguClientKit` (#707)
- Simplify BoundStreams (#719) (#751)
- Handle `InteractionControl` field from `Text.TextRedirect`. (#716)
- Rename extended function of `NuguOAuthClient` (#720)
- Move `UITapGestureRecognizer` from `Application` to `VoiceChromePresenter` for convenience. (#738) (#768)
- Apply Builder pattern on `NuguClient` (#743) (#755)
- Add `WebTheme` options in 'NuguLoginKit' (#741)
- Put the resources for signal processing into the frameworks (#752)
- Migrate `ASRBeepPlayer` into `VoiceChromePresenter` of `NuguClientKit` (#760)
- Migrate `NuguDisplayPlayerController` into `NuguClientKit` as `ControlCenterManager` (#759)
- Add `deviceUniqueId` variable to `NuguServiceCookie` (#778)
- Prepare version 1.0.0 of `NuguAgent` (#784)

#### Removed
- Remove APIs used `deprecated` attribute (#801)

## [0.30.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.30.1)
Released on 2021-03-25
### Sample Application
#### Fixed
- Close voice chrome when any object (including button or web page) has been touched (#800)

### SDK
#### Fixed
- Close voice chrome when any object (including button or web page) has been touched (#800)
- Remove guideTextLabel's text during session has been activated (#798)

## [0.30.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.30.0)
Released on 2021-03-23
### Sample Application
#### Update
- Implement `PermissionAgent`. (#790)
> Not essential changes to reflect.
> Use `PermissionAgent` to request permissions exactly when `NUGU Play` needs it.

### SDK
#### Added
- Implement `PermissionAgent`. (#790)

#### Fixed
- Check `InteractionControl` when handling `PhoneCall.SendCandidates` directive. (#795)
- Remove guideTextLabel's text during session has been activated #798

## [0.29.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.29.1)
Released on 2021-03-19
### SDK
#### Update
- Save the offset of the `MediaPlayer` only if it is not nil. (#777)

## [0.29.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.29.0)
Released on 2021-03-10
### Sample Application
#### Update
- `ASRAgent` 1.5 (upgrade capability-agent) (#767)

### SDK
#### Update
- `ASRAgent` 1.5 (upgrade capability-agent) (#767)
- Upgrade `AudioPlayerAgent` to 1.6 #774

## [0.28.4](https://github.com/nugu-developers/nugu-ios/releases/tag/0.28.4)
Released on 2021-03-09
### Sample Application
#### Fixed
- Resolve control center issue (#758)

#### Update
- Add `togglePlayAndPauseCommand` target for a wired earset (#754)

### SDK
#### Fixed
- Release `PlayerItemObservers` during `MediaAVPlayerItem` deinitializing (#765)

#### Update
- Separate Audio hardware issue and format issue (#773)

## [0.28.3](https://github.com/nugu-developers/nugu-ios/releases/tag/0.28.3)
Released on 2021-02-22
### Sample Application
#### Fixed
- Fix crash in UserDefaults when setting a nil value. (#734)

### SDK
#### Fixed
- Support dynamic allocation of resource server URL. (#733)
- Add "+" excluded character set for percentEncoding (#744)
- Remove `WKWebsiteDataStore` configuration in NUGU SDK (#745)

## [0.28.2](https://github.com/nugu-developers/nugu-ios/releases/tag/0.28.2)
Released on 2021-02-01
### SDK
#### Fixed
Use `ResourceBundle` images in `NuguUIKit` (#718)

#### Update
- Update browser for authentication (#699)

## [0.28.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.28.1)
Released on 2021-01-06
### SDK
#### Added
- Revert removed url variables in `NuguServiceWebView` (#697)

#### Fixed
- Handle exception on creating "AVAudioInputNode". (#696)

#### Update
- Modify protection level of `DialogStateAggregator.isChipsRequestInProgress` for backward compatibility. (#698)

## [0.28.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.28.0)
Released on 2020-12-30
### Sample Application
#### Added
- Add `NuguDisplayWebView` to `NuguUIKit` and move `AudioPlayerView` from `SampleApp` to `NuguUIKit` (#655) (#673) (#683)
> Not essential changes to reflect.
> For more information, See the [NuguDisplayWebView 를 직접 사용하기](https://developers-doc.nugu.co.kr/nugu-sdk/platform/ios/nugu-display-template-server#nugudisplaywebview)
- Add Display views presenters (#693)
> Not essential changes to reflect.
> For more information, See the [DisplayWebViewPresenter 를 사용하기](https://developers-doc.nugu.co.kr/nugu-sdk/platform/ios/nugu-display-template-server#displaywebviewpresenter)
- Add `MicInputProviderDelegate` (#680)
> Not essential changes to reflect.  
- Add `NuguClient.requestTextInput` function to improve convenience. (#675)
> Not essential changes to reflect.  
- Provide sdk configurations by config file and `OAuth Discovery` API (#690)
> Not essential changes to reflect.
> For more information, See the [Configuration 파일 설정하기](https://developers-doc.nugu.co.kr/nugu-sdk/platform/ios/start#configuration)

#### Fixed
- Refactor NuguDisplayPlayerController and Fix duration-vanishing issue. (#677) (#679)

#### Update
- Make observer possible to be removed properly. (#668)
> Not essential changes to reflect.  

### SDK
#### Added
- Add `NuguDisplayWebView` to `NuguUIKit` and move `AudioPlayerView` from `SampleApp` to `NuguUIKit` (#655) (#673) (#683
- Add Display views presenters (#693)
- Add `MicInputProviderDelegate` (#680)
- Add `NuguClient.requestTextInput` function to improve convenience. (#675)
- Provide sdk configurations by config file and `OAuth Discovery` API (#690) 

#### Fixed
- Pass error when the auth-token is missing. (#662)
- Refactor NuguDisplayPlayerController and Fix duration-vanishing issue. (#677) (#679)
- Do not stop the prefetched player when handling the `TTS.Stop` directive. (#667)

#### Update
- Make observer possible to be removed properly. (#668)
- `AudioPlayerAgent` 1.5 (upgrade capability-agent) (#670)
- Apply interaction control when handling `Display.ControlScroll` directive. (#681)
- Update API documentation. (#682) (#687)
- Handle `ASR.CancelRecognize` directive. (#686)

## [0.27.5](https://github.com/nugu-developers/nugu-ios/releases/tag/0.27.5)
Released on 2020-12-07
### Sample Application
#### Fixed
- Call `AudioPlayerAgentDelegate.audioPlayerAgentDidChange(duration:)` when duration of `AVAsset` is loaded.  (#669)

### SDK
#### Fixed
- Call `AudioPlayerAgentDelegate.audioPlayerAgentDidChange(duration:)` when duration of `AVAsset` is loaded.  (#669)

## [0.27.4](https://github.com/nugu-developers/nugu-ios/releases/tag/0.27.4)
Released on 2020-12-07
### SDK
#### Fixed
- Fix crash issues. (#666) 

## [0.27.3](https://github.com/nugu-developers/nugu-ios/releases/tag/0.27.3)
Released on 2020-12-04
### SDK
#### Fixed
- Fix `NuguServiceWebView` javascript handling bug (parsing error) (#664) 

## [0.27.2](https://github.com/nugu-developers/nugu-ios/releases/tag/0.27.2)
Released on 2020-12-03
### Sample Application
#### Fixed
- Call `closeWindow` delegate even if `reason` field is empty (#654)

### SDK
#### Fixed
- Check "duration" status before accessing AVURLAsset.duration property (#652) 
- Call `closeWindow` delegate even if `reason` field is empty (#654)
- Fixes a bug where `displayAgentDidClear` called abnormally when `LayerType` is `Media`. (#661)   
- Request background focus when `MediaPlayer.PlaySuspended` event is requested. (#657)

#### Update
- Add `header` parameter in `requestSendCandidates` function (#656) 

## [0.27.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.27.1)
Released on 2020-11-27
### SDK
#### Update
- Add `init` function to initialize with `UIView`. (#651)

## [0.27.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.27.0)
Released on 2020-11-27
### Sample Application
#### Added
- Add `VoiceChromePresenter` (#629)
> Not essential changes to reflect.
> Application only needs to apply the changes of  [`MainViewController`](https://github.com/nugu-developers/nugu-ios/pull/629/files#diff-7468829fbd38fb482c72def9b95c04abe8d927db4e1b5ffd789187e8f36f13f3)    

### SDK
#### Added
- Add `VoiceChromePresenter` (#629)

#### Fixed
- Request focus synchronously when handling `ASR.ExpectSpeech`. (#643)

#### Update
- `TextAgent` 1.5 (upgrade capability-agent) (#634)

## [0.26.3](https://github.com/nugu-developers/nugu-ios/releases/tag/0.26.3)
Released on 2020-11-25
### SDK
#### Fixed
- Add NuguUtils scheme (#641)

## [0.26.2](https://github.com/nugu-developers/nugu-ios/releases/tag/0.26.2)
Released on 2020-11-24
### Sample Application
#### Added
- Separate NuguUtils to share and dynamic access (#627)
> Drag and drop `NuguUtils` framework to "Frameworks, Libraries, and Embedded Content" section in application targets’ General settings tab.(For more information, See the  [Carthage](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application))

### SDK
#### Update
- Pass only 1 `sessionId` for `playServiceId` in the context of `SessionAgent`. (#633)
- Make sure that the `StreamDataDelegate` functions are called first to satisfy the statistical requirements. (#636)

#### Fixed
- Fixes a bug when canceling and resuming timers for layer. (#630)
- Ignore user interaction when playback paused (#630)
- Skip attachment when last data appended. (#635)

#### Added
- Separate NuguUtils to share and dynamic access (#627)

## [0.26.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.26.1)
Released on 2020-11-17
### SDK
#### Fixed
- Fixes a build error. (#623)

## [0.26.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.26.0)
Released on 2020-11-17
### Sample Application
#### Update
- Modify the structure of `Upstream` to be similar to Downstream. (#621)

### SDK
#### Update
- Modify the structure of `Upstream` to be similar to Downstream. (#621)
- Add `directiveSequencerWillPrefetch` function to `DirectiveSequencerDelegate` (#620)

#### Fixed
- Fixes a bug where `playServiceId` is missing when sending `TTS` event. (#619)

## [0.25.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.25.0)
Released on 2020-11-12
### Sample Application
#### Update
- Pass `Downstream.Header` to function parameter of agent delegate. (#613)

### SDK
#### Update
- Pass `Downstream.Header` to function parameter of agent delegate. (#613)

## [0.24.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.24.1)
Released on 2020-11-10
### SDK
#### Fixed
- Fix parsing error in `MediaPlayerAgent` (#606)

## [0.24.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.24.0)
Released on 2020-11-10
### Sample Application
#### Update
- Implements a `FocusManager` feature to prevent `AudioPlayerAgent` playing temporarily.  (#604)

### SDK
#### Fixed
- Fix parsing error in `MediaPlayerAgent` (#603)

#### Update
- Start a timer to stop `MediaPlayer` when playback is temporarily paused. (#602)
- Implements a `FocusManager` feature to prevent `AudioPlayerAgent` playing temporarily.  (#604)

## [0.23.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.23.1)
Released on 2020-11-09
### SDK
#### Fixed
- Modify the delegate function to be called asynchronously to avoid deadlock. (#600)

## [0.23.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.23.0)
Released on 2020-11-06
### Sample Application
#### Fixed
- Fixes a bug where `startWakeUpDetector` does not called. (#582)

#### Update
- Pass `Downstream.Header` instead of `DialogRequestId` to function parameter of agent delegate. (#593)

### SDK
#### Fixed
- Make `KeywordSource` not possible to be set simultaniouly. (#581)
- Assign and release focus synchronously. (#580)
- Fixes a bug where prefetch `AudioPlayer.Play`. (#577)
- Make computed properties of `AudioPlayerAgent` and `TTSAgent` to be thread safe. (#583)

#### Update
- Extends decodable public struct to conform `Codable` (#592) (#593) (#584) (#586)
- `ASRAgent` 1.4 (upgrade capability-agent) (#590)
- Pass `Downstream.Header` instead of `DialogRequestId` to function parameter of agent delegate. (#593)
- `MediaPlayer` 1.1 (upgrade capability-agent) #596

#### Removed
- Remove `phoneCallAgentRequestState()` delegate method (#576) 

## [0.22.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.22.0)
Released on 2020-10-29
### Sample Application
#### Fixed
- Set audiosession as playback when carplay is connected and play media (#563)

### SDK
#### Fixed
- Separate image resource bundle of  when using cocoapods (#561)
- Add `TTSPlayer` and `AudioPlayer` to fix timing issues. (#560) (#571)

#### Update
- `DisplayAgent` 1.6 (upgrade capability-agent) (#564)
- `TTSAgent` 1.3 (upgrade capability-agent) (#570)
- `PhoneCallAgent` 1.2 (upgrade capability-agent)  (#573)
- Revert "Update logic related authorization (showTidInfo, authorize)" (#574)
- Refactor the capabilily agent function to send events consistently. (#572) 

## [0.21.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.21.1)
Released on 2020-10-21
### Sample Application
#### Fixed
- Set chips after voicechrome state change (#555) 

### SDK
#### Update
- Add `BackgroundFocusHolder` (#556) 
- Remove useless api during passing string to library (#559)

## [0.21.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.21.0)
Released on 2020-10-14
### SDK
#### Fixed
- Fix crash issues. (#543) (#544) (#553)

## [0.20.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.20.0)
Released on 2020-10-07
### SDK
#### Fixed
- Change `NuguServiceWebView`'s domain property as public static var (configurable) (#540)
- Add API references document. (#538)
- Fix typo and decoding & encoding issue in `MediaPlayerAgent` (#541)
- Update `MediaPlayerAgent` for `NuguClientKit` (#539)

## [0.19.4](https://github.com/nugu-developers/nugu-ios/releases/tag/0.19.4)
Released on 2020-09-28
### Sample Application
#### Fixed
- Revert 'updating control center even if playerItem is nil' (https://github.com/nugu-developers/nugu-ios/pull/442) because of unexpected side effects (#534)
- Modify `DisplayView` and `AudioDisplayView` to make them weak references. (#533)

### SDK
#### Fixed
- Update logic related authorization (showTidInfo, authorize) (#536)

## [0.19.3](https://github.com/nugu-developers/nugu-ios/releases/tag/0.19.3)
Released on 2020-09-25
### Sample Application
#### Fixed
- Modify `ASRBeepPlayer` to make it thread safe. (#532)

### SDK
#### Fixed
- Fixes a bug where the progress report event does not send. (#529) 
- Modify `FocusManager.channelInfos` to make it thread safe. (#530)

## [0.19.2](https://github.com/nugu-developers/nugu-ios/releases/tag/0.19.2)
Released on 2020-09-25
### SDK
#### Fixed
- Remove `EXCLUDED_ARCHS` build setting for `JadeMarble`

## [0.19.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.19.1)
Released on 2020-09-24
### Sample Application
#### Fixed
- Stop recognition and mic when interruption has begun (#528)

#### Update
- Include 400 error as autherror also (#528)

### SDK
#### Fixed
- Fix a bug that incorrectly assigns focus. (#526)

## [0.19.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.19.0)
Released on 2020-09-23
### Sample Application
#### Fixed
- Fix sample application display issues (#480)
- Fix sample app (#510)

#### Update
- Change NuguVoiceChrome's UI (#484)
- Add `sessionActivated` parameter to `DialogStateDelegate.dialogStateDidChange` (#481)
- Update `SystemAgentExceptionCode` in `SystemAgent` (#488) (#492)
- Change voice chrome dismiss and show logic (#493) (#517)
- Apply text agent change to Sample app (#499)
- Remove unnecessary UI changing codes (#500) 
- Update `NuguUserInfo` due to API changes (#501)
- Update `showTidInfo` function in `NuguLoginKit` (#507)
- Apply detail error description (#506)
- Add `dialogRequestId` parameter to Agent's delegate. (#504)
- Replace supportServerInitiatedDirective with scopes (#513)
- Pass `ASRInitiator` instead of `ASROption` to start recognition. (#520)
- `ChipsAgent` 1.1 (upgrade capability-agent)
- Pass token of chips and listitems (#522)
- Stop recognition after `Text.TextInput` event sent.  (#524)

### SDK
#### Fixed
- Send end_stream after receiving end_stream from server. (#476)
- Fixes a crash when encoding json string. (#489)
- Use `Single.timer` instead of `Completable.delaySubscription` to prevent crash. (#490) 
- Remove custom module map for `NuguCore` (#515)
- Fix crash in `MicInputProvider.stop()`. (#519)

#### Update
- Call `FocusManagerDelegate.focusShouldRelease` minimally. (#475)
- Add "audio/mp3" and "audio/x-m4a" to supportedMimeTypeForCaching (#479)
- Change NuguVoiceChrome's UI (#523)  (#477)  (#484) (#523)
- Add `sessionActivated` parameter to `DialogStateDelegate.dialogStateDidChange` (#481)
- `PhoneCallAgent` 1.1 (upgrade capability-agent) (#486) 
- Update `SystemAgentExceptionCode` in `SystemAgent` (#488) 
- `TextAgent` 1.3 (upgrade capability-agent)  (#487)
- Update `NuguUserInfo` due to API changes (#501)
- Update `showTidInfo` function in `NuguLoginKit` (#507)
- Add `dialogRequestId` parameter to Agent's delegate. (#504)
- Pass `ASRInitiator` instead of `ASROption` to start recognition. (#520)
- `ChipsAgent` 1.1 (upgrade capability-agent)

## [0.18.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.18.0)
Released on 2020-08-26
#### Fixed
[SampleApp] Fixes a crash issue (#461)
[SampleApp] Separate stopRecognize() from dismissVoiceChrome() (#464)
[NuguCore] Fix crash issues (#457) (#469)
[NuguAgents] Modify `postBack` to `postback` in payload of `Display.ElementSelected` event. (#460)
[NuguClientKit] Fixes a bug where passing the wrong `DialogState`. (#455)
[NuguClientKit] Sort `ChipsAgentItem` in chronological order. (#458)

#### Update
[SampleApp] Modify focus channel priority of `ASRBeepPlayer` (#459) (#463)
[SampleApp] Request focus when before sending text input event. (#465)
[SampleApp] Update sound resources (#472)
[NuguUIKit] Add nugu button flip animation (#456)
[NuguAgents] `AudioPlayerAgent` 1.4(upgrade capability-agent) (#401) (#452) 
[NuguAgents] Add `directiveCancelPolicy` to `TTSAgentProtocol` (#454)
[NuguAgents] Modify focus channel priority of `SoundAgent` (#459) (#463)
[NuguAgents] Upgrade displayAgent from v1.4 to v1.5 (#468)

## [0.17.0](https://github.com/nugu-developers/nugu-ios/releases/tag/0.17.0)
Released on 2020-08-12
#### Added
- [NuguAgents] Add `InteractionControlManager` to keep the voice chrome when processing multi-turn (#443)

#### Fixed
- [SampleApp] Fix `AVAudioSession` issues. (#436)
- [NuguAgents] Fix audio focus issues. (#437) (#438) (#450)
- [NuguAgents] Cancel directive when message id does not match. (#444)
- [NuguCore] Fix layer synchronization issues. (#449) (#451)

#### Update
- [NuguAgents] Add `includeDialogAttribute` parameter to `TextAgentProtocol.requestTextInput` function. (#445)
- [NuguClientKit] Move `chips` parameter from `DialogState.listening` to `DialogStateDelegate.dialogStateDidChange` (#446)

## [0.16.1](https://github.com/nugu-developers/nugu-ios/releases/tag/0.16.1)
Released on 2020-08-05
#### Fixed
- [JadeMarble] Pass the audio pcm data as UInt8 to Tyche EPD engine. (#435)
- [NuguServiceKit] Add reason parameter in `closeWindow` delegate of `NuguServiceWebJavascriptDelegate` (#433)

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

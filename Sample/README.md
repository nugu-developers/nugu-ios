# Nugu Sample App

## Run
### CocoaPods
To run SampleApp-iOS, installation with [CocoaPods](https://cocoapods.org) is required.
```bash
$ pod install
```
### Copy voice recognition model files and add to targets
Voice recognition model files downloaded from [NUGU Developers](https://developers.nugu.co.kr) should be copied and added to SampleApp-iOS target
- Wake-up Model files
> skt_trigger_search_tinkerbell.raw  
> skt_trigger_am_tinkerbell.raw  
> skt_trigger_search_aria.raw  
> skt_trigger_am_aria.raw
- EPD Model file
> skt_epd_model.raw

## Log-in difference by partnership type
> Type1: Able to use Built-in/Open play/Private play after NUGU platform membership certification. (NUGU android/iOS Application linked)

> Type2: Able to use only Private play by skipping NUGU platform membership certification.

- SampleApp-iOS shows both Type1/Type2 login ways.
- NUGU platform certification flows are different by their partnership type and has its own method for login in [NuguLoginKit](https://github.com/nugu-developers/nugu-login-kit-ios).

## Change SampleApp.swift's variables appropriately
Put appropriate custom values (Issued from [NUGU Developers](https://developers.nugu.co.kr)) to SampleApp's variables 

- Example for Type1
```swift
static var loginMethod: LoginMethod? = .type1
static var deviceUniqueId: String? = "{Unique-id per device}"
static var clientId: String? = "{Client-id}" // Client-id is need for oauth-authorization
static var clientSecret: String? = "{Client-secret}" // Client-secret is need for oauth-authorization
static var redirectUri: String? = "{Redirect-uri}" // Redirect-uri is need for oauth-authorization
```
- Example for Type2
```swift
static var loginMethod: LoginMethod? = .type2
static var deviceUniqueId: String? = "{Unique-id per device}"
static var clientId: String? = "{Client-id}" // Client-id is need for oauth-authorization
static var clientSecret: String? = "{Client-secret}" // Client-secret is need for oauth-authorization
```



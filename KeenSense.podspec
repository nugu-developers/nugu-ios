Pod::Spec.new do |s|
  s.name = 'KeenSense'
  s.version = '1.10.2'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Key Word Detector for NUGU'
  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.authors = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version }
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.ios.deployment_target = '12.0'
  s.swift_version = '5'

  s.source_files = 'KeenSense/Sources/**/*.swift'
  s.vendored_frameworks = 'TycheWakeupCommon.xcframework', 'TycheWakeup.xcframework'
  s.resource = 'KeenSense/Resources/*'
  s.libraries = 'c++'

  s.dependency 'NuguUtils', s.version.to_s
  s.dependency 'TycheSDK', s.version.to_s
  
  s.dependency 'NattyLog', '~> 1'
  
  s.xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-DDEPLOY_OTHER_PACKAGE_MANAGER'
  }
end

Pod::Spec.new do |s|
  s.name = 'KeenSense'
  s.version = '0.10.0'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Key Word Detector for NUGU'
  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.authors = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version }
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.ios.deployment_target = '10.0'

  s.swift_version = '5.0'

  s.source_files = 'KeenSense/Sources/**/*.swift', 'KeenSense/Libraries/include/*.h'
  s.public_header_files = 'KeenSense/Libraries/include/*.h'
  s.vendored_libraries = 'KeenSense/Libraries/libTycheWakeupCommon.a', 'KeenSense/Libraries/libTycheWakeup.a', 'KeenSense/Libraries/libTycheWakeupSpeex.a'
  s.preserve_paths = 'KeenSense/Libraries/**'
  s.libraries = 'c++'
  s.xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_ROOT)/KeenSense/KeenSense/Libraries/**'}

  s.dependency 'NattyLog', '~> 1'
  
end

Pod::Spec.new do |s|
  s.name = 'JadeMarble'
  s.version = '1.3.2'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'End Point Detector for NUGU ASR'
  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.authors = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version }
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.ios.deployment_target = '12.0'
  s.swift_version = '5'

  s.source_files = 'JadeMarble/Sources/**/*.swift', 'JadeMarble/Libraries/**/*.h'
  s.public_header_files = 'JadeMarble/Libraries/include/*.h'
  s.vendored_frameworks = 'JadeMarble/Libraries/TycheCommon.xcframework', 'JadeMarble/Libraries/TycheEpd.xcframework', 'JadeMarble/Libraries/TycheSpeex.xcframework'
  s.resources = 'JadeMarble/Resources/*'
  s.preserve_paths = 'JadeMarble/Libraries/**'
  s.libraries = 'c++'
  s.xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_ROOT)/JadeMarble/JadeMarble/Libraries/**' }

  s.dependency 'NattyLog', '~> 1'
  
end

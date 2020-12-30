Pod::Spec.new do |s|
  s.name = 'NuguClientKit'
  s.version = '0.28.0'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Nugu Client Kit'
  s.description = <<-DESC
Default Instances for Nugu service
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version.to_s }
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.ios.deployment_target = '10.0'

  # Nugu does not yet support Apple Silicon
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.swift_version = '5.1'
  
  s.source_files = 'NuguClientKit/Sources/**/*', 'NuguClientKit/Sources-ObjC/*.{h,m}', 'NuguClientKit/NuguClientKit.h'
  s.public_header_files = 'NuguClientKit/Sources-ObjC/*.h', 'NuguClientKit/NuguClientKit.h'

  s.dependency 'NuguCore', '~> 0'
  s.dependency 'NuguAgents', '~> 0'
  s.dependency 'KeenSense', '~> 0'
  s.dependency 'NuguLoginKit', '~> 0'
  s.dependency 'NuguUIKit', '~> 0'
  s.dependency 'NuguUtils', '~> 0'
  s.dependency 'NuguServiceKit', '~> 0'

  s.dependency 'NattyLog', '~> 1'
end

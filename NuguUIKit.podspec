Pod::Spec.new do |s|
  s.name = 'NuguUIKit'
  s.version = '1.1.1'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'UI Set of Nugu Service'
  s.description = <<-DESC
  Provides set of UI components such as NuguButton, NuguVoiceChrome for using Nugu Service
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  # Nugu does not yet support Apple Silicon
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  s.swift_version = '5.1'

  s.resources = 'NuguUIKit/Resources/**/*.{json}', 'NuguUIKit/Sources/**/*.{xib}'
  s.resource_bundles = { 'NuguUIKit-Images' => ['NuguUIKit/Resources/*.xcassets'] }

  s.source_files = 'NuguUIKit/Sources/**/*.{swift}'

  s.dependency 'lottie-ios', '~> 3'
  s.dependency 'NuguAgents', s.version.to_s
  s.dependency 'NuguUtils', s.version.to_s
  s.dependency 'NattyLog', '~> 1'
end

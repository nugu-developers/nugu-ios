Pod::Spec.new do |s|
  s.name = 'NuguUIKit'
  s.version = '0.10.0'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'UI Set of Nugu Service'
  s.description = <<-DESC
  Provides set of UI components such as NuguButton, NuguVoiceChrome for using Nugu Service
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  
  s.swift_version = '5.1'

  s.resources = 'NuguUIKit/Resources/**/*.{json,xcassets}'
  s.source_files = 'NuguUIKit/Sources/**/*'

  s.dependency 'lottie-ios', '~> 3'
end

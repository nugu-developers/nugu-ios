Pod::Spec.new do |s|
  s.name = 'NuguAgents'
  s.version = '0.9.2'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Nugu Agents'
  s.description = <<-DESC
Default Agent Implementations for Nugu service
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version.to_s }
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '6.0'
  s.macos.deployment_target = '10.15.0'

  s.swift_version = '5.1'
  
  s.source_files = 'NuguAgents/Sources/**/*', 'NuguAgents/Interface/**/*'
  s.tvos.exclude_files = 'NuguAgents/Sources/CapabilityAgents/AutomaticSpeechRecognition/**/*'
  s.watchos.exclude_files = 'NuguAgents/Sources/CapabilityAgents/AutomaticSpeechRecognition/**/*'
  s.macos.exclude_files = 'NuguAgents/Sources/CapabilityAgents/AutomaticSpeechRecognition/**/*'
  
  s.dependency 'NuguCore', '~> 0'
  s.dependency 'NattyLog', '~> 1'

  s.ios.dependency 'JadeMarble', '~> 0'
end

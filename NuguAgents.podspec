Pod::Spec.new do |s|
  s.name = 'NuguAgents'
  s.version = '1.10.2'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Nugu Agents'
  s.description = <<-DESC
Default Agent Implementations for Nugu service
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version.to_s }
  s.resource_bundles = {"NuguUtils" => ["NuguUtils/PrivacyInfo.xcprivacy"]}
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.ios.deployment_target = '12.0'
  s.swift_version = '5'

  s.source_files = 'NuguAgents/Sources/**/*'
  
  s.dependency 'NuguCore', s.version.to_s
  s.dependency 'NuguUtils', s.version.to_s
  s.dependency 'SilverTray', s.version.to_s
  s.dependency 'NattyLog', '~> 1'
  s.ios.dependency 'JadeMarble', s.version.to_s
  
  s.xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-DDEPLOY_OTHER_PACKAGE_MANAGER'
  }

  # s.subspec 'iOS_Specific' do |iOS|
  #   iOS.subspec 'ASR' do |asr|
  #     asr.ios.source_files = 'NuguAgents/Sources/CapabilityAgents/AutomaticSpeechRecognition/**/*'

  #     asr.ios.dependency 'JadeMarble', '~> 0'
  #     asr.ios.dependency 'NuguCore', '~> 0'
  #     asr.ios.dependency 'NattyLog', '~> 1'
  #   end
  # end

  # s.subspec 'Common' do |common|
  #   common.source_files = 'NuguAgents/Sources/**/*'
  #   common.exclude_files = 'NuguAgents/Sources/CapabilityAgents/AutomaticSpeechRecognition/**/*'

  #   common.dependency 'NuguCore', '~> 0'
  #   common.dependency 'NattyLog', '~> 1'
  #   common.dependency 'SilverTray', '~> 1'

  #   #common.tvos.deployment_target = '13.0'
  #   #common.watchos.deployment_target = '6.0'
  #   #common.macos.deployment_target = '10.15.0'
  # end
end

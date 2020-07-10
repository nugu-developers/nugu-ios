Pod::Spec.new do |s|
  s.name = 'NuguClientKit'
  s.version = '0.15.0'
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

  s.swift_version = '5.1'
  
  s.source_files = 'NuguClientKit/Sources/**/*'

  s.dependency 'NuguCore', '~> 0'
  s.dependency 'NuguAgents', '~> 0'
  s.dependency 'KeenSense', '~> 0'

  s.dependency 'NattyLog', '~> 1'
end

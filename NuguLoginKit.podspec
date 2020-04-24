Pod::Spec.new do |s|
  s.name = 'NuguLoginKit'
  s.version = '0.10.0'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Supported login for Nugu Service'
  s.description = <<-DESC
Framework for login using OAuth 2.0
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version.to_s }
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.ios.deployment_target = '10.0'
  
  s.swift_version = '5.1'

  s.source_files = 'NuguLoginKit/Sources/**/*'
end

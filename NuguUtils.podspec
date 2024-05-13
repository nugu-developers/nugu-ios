Pod::Spec.new do |s|
  s.name = 'NuguUtils'
  s.version = '1.10.2'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Supported login for Nugu Service'
  s.description = <<-DESC
Framework for login using OAuth 2.0
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version.to_s }
  s.resource_bundles = {"NuguUtils" => ["NuguUtils/PrivacyInfo.xcprivacy"]}
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.ios.deployment_target = '12.0'
  s.swift_version = '5'

  s.source_files = 'NuguUtils/Sources/**/*'

  s.dependency 'RxSwift', '~> 6'
  
  s.xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-DDEPLOY_OTHER_PACKAGE_MANAGER'
  }
end


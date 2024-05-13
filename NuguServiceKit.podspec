Pod::Spec.new do |s|
  s.name = 'NuguServiceKit'
  s.version = '1.10.2'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Customized Webview for Nugu Service'
  s.description = <<-DESC
  Provides NuguServiceWebView with customized cookie and javascript delegate for using webView in Nugu Service
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5'
  
  s.source_files = 'NuguServiceKit/Sources/**/*'

  s.dependency 'NuguUtils', s.version.to_s
  s.dependency 'NattyLog', '~> 1'

  s.xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-DDEPLOY_OTHER_PACKAGE_MANAGER'
  }
end

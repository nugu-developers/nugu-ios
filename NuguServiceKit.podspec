Pod::Spec.new do |s|
  s.name = 'NuguServiceKit'
  s.version = '1.2.2'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Customized Webview for Nugu Service'
  s.description = <<-DESC
  Provides NuguServiceWebView with customized cookie and javascript delegate for using webView in Nugu Service
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  # Nugu does not yet support Apple Silicon
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  s.swift_version = '5.1'

  s.dependency 'NuguUtils', s.version.to_s
  s.dependency 'NattyLog', '~> 1'

  s.source_files = 'NuguServiceKit/Sources/**/*'
end

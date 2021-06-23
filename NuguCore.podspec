Pod::Spec.new do |s|
  s.name = 'NuguCore'
  s.version = '1.2.2'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Nugu'
  s.description = <<-DESC
Nugu framework for AI Service
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'SK Telecom Co., Ltd.' => 'nugu_dev_sdk@sk.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version }
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.ios.deployment_target = '10.0'
  # s.tvos.deployment_target = '13.0'
  # s.watchos.deployment_target = '6.0'
  # s.macos.deployment_target = '10.15.0'

  # Nugu does not yet support Apple Silicon
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.swift_version = '5.1'

  s.source_files = 'NuguCore/Sources/**/*'

  s.dependency 'NuguUtils', s.version.to_s
  s.dependency 'NattyLog', '~> 1.0'
  s.dependency 'RxSwift', '~> 5'

end

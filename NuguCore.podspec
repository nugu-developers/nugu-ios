Pod::Spec.new do |s|
  s.name = 'NuguCore'
  s.version = '0.10.0'
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

  s.swift_version = '5.1'

  s.source_files = 'NuguCore/Interface/**/*', 'NuguCore/Sources/**/*', 'NuguCore/Sources-ObjC/*.{h,m}', 'NuguCore/Libraries/**/*.h'
  s.public_header_files = 'NuguCore/Libraries/**/*.h', 'NuguCore/Sources-ObjC/*.h'
  s.vendored_libraries = 'NuguCore/Libraries/**/*.a'
  s.preserve_paths = 'NuguCore/Libraries/**'
  s.libraries = 'c++'
  s.xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_ROOT)/NuguCore/NuguCore/Libraries/**' }

  s.dependency 'NattyLog', '~> 1.0'
  s.dependency 'RxSwift', '~> 5'

end

Pod::Spec.new do |s|
  s.name = 'NuguCore'
  s.version = '0.17.0'
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

  s.swift_version = '5.1'

  s.source_files = 'NuguCore/Interface/**/*', 'NuguCore/Sources/**/*', 'NuguCore/Sources-ObjC/*.{h,m}', 'NuguCore/NuguCore.h'
  s.private_header_files = 'NuguCore/Sources-ObjC/*.h', 'NuguCore/NuguCore.h'
  s.module_map = 'NuguCore/NuguCore.modulemap'

  s.dependency 'NattyLog', '~> 1.0'
  s.dependency 'RxSwift', '~> 5'

end

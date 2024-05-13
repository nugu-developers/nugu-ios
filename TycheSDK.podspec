Pod::Spec.new do |s|
  s.name = 'TycheSDK'
  s.version = '1.10.2'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Tyche wrapper'
  s.description = <<-DESC
play encoded data using AVAudioEngine
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'childc' => 'skimdcc@gmail.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version }
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.ios.deployment_target = '12.0'
  # s.tvos.deployment_target = '13.0'
  # FIXME: OpusDecoder.o does not valid.
  # s.watchos.deployment_target = '6.0'
  # s.macos.deployment_target = '10.15.0'

  s.source_files = 'TycheSDK/include/*.h', 'TycheSDK/shim.c'
  s.public_header_files = 'TycheSDK/include/*.h'
  s.preserve_paths = 'TycheSDK/include/**'
  
  s.xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-DDEPLOY_OTHER_PACKAGE_MANAGER'
  }
  
end

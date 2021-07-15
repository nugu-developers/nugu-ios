Pod::Spec.new do |s|
  s.name = 'SilverTray'
  s.version = '1.4.0-beta.2'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Data chunk player'
  s.description = <<-DESC
play encoded data using AVAudioEngine
                       DESC

  s.homepage = 'https://github.com/nugu-developers/nugu-ios'
  s.author = { 'childc' => 'skimdcc@gmail.com' }
  s.source = { :git => 'https://github.com/nugu-developers/nugu-ios.git', :tag => s.version }
  s.documentation_url = 'https://developers.nugu.co.kr'

  s.swift_version = '5'

  s.ios.deployment_target = '12.0'
  # s.tvos.deployment_target = '13.0'
  # FIXME: OpusDecoder.o does not valid.
  # s.watchos.deployment_target = '6.0'
  # s.macos.deployment_target = '10.15.0'

  s.source_files = 'SilverTray/Classes/**/*', 'SilverTray/Libraries/**/*.h'
  s.public_header_files = 'SilverTray/Classes/**/*.h', 'SilverTray/Libraries/**/*.h'
  s.vendored_frameworks = 'SilverTray/Libraries/Opus/Binary/OpusCodec.xcframework'
  s.preserve_paths = 'SilverTray/Libraries/**'
  s.libraries = 'c++'

  s.xcconfig = {
    'OTHER_LDFLAGS' => '-Xlinker -w',
    'SWIFT_INCLUDE_PATHS' => '$(PODS_ROOT)/SilverTray/SilverTray/Libraries/**'
  }
  
end

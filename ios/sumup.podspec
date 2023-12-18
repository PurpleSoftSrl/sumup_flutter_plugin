#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sumup.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sumup'
  s.version          = '0.8.1'
  s.summary          = 'Flutter wrapper to use the Sumup SDK.'
  s.description      = <<-DESC
  Flutter wrapper to use the Sumup SDK. With this plugin, your app can easily connect to a Sumup terminal, login and accept card payments on Android and iOS.
                       DESC
  s.homepage         = 'https://purplesoft.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Purplesoft S.r.l' => 'developers@purplesoft.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'SumUpSDK', '4.3.4'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
  s.static_framework = true
end

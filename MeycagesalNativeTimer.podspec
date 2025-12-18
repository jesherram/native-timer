require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'MeycagesalNativeTimer'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url'] rescue 'https://github.com/jesherram/native-timer'
  s.author = package['author']
  s.source = { :git => 'https://github.com/jesherram/native-timer.git', :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}', 'ios/LiveActivitiesKit/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.public_header_files = 'ios/LiveActivitiesKit/*.h'

  s.ios.deployment_target = '14.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
  
  # Frameworks condicionais - ActivityKit apenas para iOS 16.2+
  s.weak_frameworks = 'WidgetKit', 'SwiftUI', 'ActivityKit'
end

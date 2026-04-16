require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'Jesushr0013NativeTimer'
  s.module_name = 'MeycagesalNativeTimer'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url'] rescue 'https://github.com/jesherram/native-timer'
  s.author = package['author']
  s.source = { :git => 'https://github.com/jesherram/native-timer.git', :tag => s.version.to_s }
  s.source_files = 'ios/Core/**/*.{swift,h,m,c,cc,mm,cpp}', 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'

  s.ios.deployment_target = '15.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
  
  # Solo ActivityKit como weak_framework - SwiftUI ya NO se linkea en este target
  s.weak_frameworks = 'ActivityKit'
end

Pod::Spec.new do |s|
  s.name = 'NativeTimerKit'
  s.version = '1.0.0'
  s.summary = 'A Swift framework for creating dynamic Live Activities layouts for Native Timer'
  s.license = 'MIT'
  s.homepage = 'https://github.com/meycagesal/native-timer'
  s.author = { 'Meycagesal' => 'info@meycagesal.com' }
  s.source = { :git => 'https://github.com/meycagesal/native-timer.git', :tag => s.version.to_s }
  s.source_files = 'ios/LiveActivitiesKit/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.public_header_files = 'ios/LiveActivitiesKit/*.h'

  s.ios.deployment_target = '15.0'
  s.swift_version = '5.1'
  
  # Frameworks condicionais - ActivityKit apenas para iOS 16.2+
  s.weak_frameworks = 'WidgetKit', 'SwiftUI', 'ActivityKit'
end

Pod::Spec.new do |s|
  s.name = 'NativeTimerKit'
  s.version = '1.0.0'
  s.summary = 'A Swift framework for creating dynamic Live Activities layouts for Native Timer'
  s.license = 'MIT'
  s.homepage = 'https://github.com/jesherram/native-timer'
  s.author = { 'Meycagesal' => 'info@meycagesal.com' }
  s.source = { :git => 'https://github.com/jesherram/native-timer.git', :tag => s.version.to_s }
  s.source_files = 'ios/LiveActivitiesKit/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.public_header_files = 'ios/LiveActivitiesKit/*.h'

  s.ios.deployment_target = '15.0'
  s.swift_version = '5.1'
  
  # Frameworks condicionais - ActivityKit apenas para iOS 16.2+
  # SwiftUICore es necesario como weak_framework porque Xcode 16+ lo separa de SwiftUI
  # y en iOS 16.x no existe como framework independiente
  s.weak_frameworks = 'WidgetKit', 'SwiftUI', 'ActivityKit', 'SwiftUICore'
  
  # Linker flags para asegurar weak linking de SwiftUICore
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -weak_framework SwiftUICore'
  }
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -weak_framework SwiftUICore'
  }
end

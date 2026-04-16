Pod::Spec.new do |s|
  s.name = 'NativeTimerKit'
  s.version = '1.0.0'
  s.summary = 'A Swift framework for creating dynamic Live Activities layouts for Native Timer'
  s.license = 'MIT'
  s.homepage = 'https://github.com/jesherram/native-timer'
  s.author = { 'Meycagesal' => 'info@meycagesal.com' }
  s.source = { :git => 'https://github.com/jesherram/native-timer.git', :tag => s.version.to_s }
  s.source_files = 'ios/LiveActivities/**/*.{swift,h,m,c,cc,mm,cpp}'

  s.ios.deployment_target = '15.0'
  s.dependency 'Jesushr0013NativeTimer'
  s.swift_version = '5.1'
  
  # Live Activities requiere SwiftUI - weak linking para compatibilidad con iOS < 16.1
  s.weak_frameworks = 'WidgetKit', 'SwiftUI', 'ActivityKit', 'SwiftUICore'
  
  # Linker flags para asegurar weak linking de SwiftUICore
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -weak_framework SwiftUICore'
  }
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -weak_framework SwiftUICore'
  }
end

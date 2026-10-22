Pod::Spec.new do |s|
  s.name = 'LSToast'
  s.version = '1.0.0'
  s.summary = 'A UIKit toast that keeps your dialogs, input focus and popup queues intact.'
  s.description = 'Window-scoped, touch-through toast messages built on an automatically installed LSTPopView dependency. Includes replacement-safe handles, timed dismissal and a complete UIKit demo with an automatically installed popup dependency.'
  s.homepage = 'https://github.com/LoSenTrad/LSToast'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = 'LoSenTrad'
  s.source = { :git => 'https://github.com/LoSenTrad/LSToast.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/LSToast/**/*.swift'
  s.frameworks = 'UIKit', 'Foundation', 'QuartzCore'
  s.dependency 'LSTPopView', '~> 0.3.10'
  s.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) LSTOAST_COCOAPODS' }
  s.preserve_paths = 'NOTICE'
end

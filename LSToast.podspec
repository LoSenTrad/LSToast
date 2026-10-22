Pod::Spec.new do |s|
  s.name = 'LSToast'
  s.version = '2.0.0'
  s.summary = 'A UIKit toast that keeps your dialogs, input focus and popup queues intact.'
  s.description = 'Window-scoped, touch-through toast messages built exclusively on the automatically installed native LSTPopViewSwift dependency. Includes replacement-safe handles, timed dismissal and a complete UIKit demo. Requires the Swift 6.2 compiler or newer.'
  s.homepage = 'https://github.com/LoSenTrad/LSToast'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = 'LoSenTrad'
  s.source = { :git => 'https://github.com/LoSenTrad/LSToast.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/LSToast/**/*.swift'
  s.frameworks = 'UIKit', 'Foundation', 'QuartzCore'
  s.dependency 'LSTPopViewSwift', '~> 0.1.0'
  s.preserve_paths = 'NOTICE'
end

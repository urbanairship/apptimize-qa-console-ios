Pod::Spec.new do |s|
  s.name             = 'ApptimizeQAConsole'
  s.version          = '1.0.0'
  s.summary          = 'Apptimize QA Console'
  s.description      = 'Preview variants in different combinations from all of your active feature flags and experiments.'
  s.homepage         = 'http://apptimize.com/'
  s.author           = 'Apptimize, Inc.'
  s.license          = { :type => 'Apache', :file => 'LICENSE.md' }
  s.source           = { :git => 'https://github.com/urbanairship/apptimize-qa-console-ios.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.dependency 'Apptimize', '>= 3'
  s.swift_version    = '5.0'
  s.source_files     = 'Sources/ApptimizeQAConsole/**/*'
end


Pod::Spec.new do |s|
  s.name = 'BasisTheoryElements'
  s.ios.deployment_target = '13.0'
  s.version = '4.5.0'
  s.source = { :git => 'https://github.com/Basis-Theory/ios-elements.git', :tag => '4.5.0' }
  s.authors = 'BasisTheory'
  s.license = 'Apache'
  s.homepage = 'https://github.com/Basis-Theory/ios-elements'
  s.summary = 'BasisTheory iOS Elements SDK'
  s.source_files = 'BasisTheoryElements/Sources/BasisTheoryElements**/*.swift'
  s.dependency 'BasisTheory', '0.6.1'
  s.swift_version = '5.5'
  s.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'COCOAPODS=1' }
  s.resource_bundles = { 
    'BasisTheoryElements_BasisTheoryElements' => [
      'BasisTheoryElements/Sources/BasisTheoryElements/Resources/Assets.xcassets'
      ] 
  }
end

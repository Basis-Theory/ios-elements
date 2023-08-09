Pod::Spec.new do |s|
  s.name = 'BasisTheoryElements'
  s.ios.deployment_target = '13.0'
  s.version = '2.7.0'
  s.source = { :git => 'https://github.com/Basis-Theory/basistheory-ios.git', :tag => '2.7.0' }
  s.authors = 'BasisTheory'
  s.license = 'Apache'
  s.homepage = 'https://github.com/Basis-Theory/basistheory-ios'
  s.summary = 'BasisTheory SDK for Elements'
  s.source_files = 'BasisTheoryElements/Sources/BasisTheoryElements**/*.swift'
  s.dependency 'BasisTheory', '0.6.1'
  s.dependency 'DatadogSDK', '~> 1.16'
  s.swift_version = '5.5'
end

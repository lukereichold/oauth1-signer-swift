# run `pod lib lint MastercardOAuth.podspec' to validate before submitting

Pod::Spec.new do |s|
  s.name             = 'MastercardOAuth'
  s.version          = '0.4.0'
  s.summary          = 'Zero dependency library for generating a Mastercard API compliant OAuth signature in Swift'

  s.description      = <<-DESC
Zero dependency library for generating a Mastercard API compliant OAuth signature in Swift.
                       DESC

  s.homepage         = 'https://developer.mastercard.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'git' => 'luke@reikam.com' }
  s.source           = { :git => 'https://github.com/lukereichold/oauth1-signer-swift.git', :tag => s.version.to_s }
  s.swift_version    = '4.2'
  s.ios.deployment_target = '11.0'

  s.source_files = 'mc-oauth1-signer/Classes/**/*'
  s.frameworks = 'Foundation', 'Security'

end

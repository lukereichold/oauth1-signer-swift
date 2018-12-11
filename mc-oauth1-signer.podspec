#
# Be sure to run `pod lib lint mc-oauth1-signer.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name             = 'mc-oauth1-signer'
  s.version          = '0.2.0'
  s.summary          = 'Zero dependency library for generating a Mastercard API compliant OAuth signature in Swift'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Zero dependency library for generating a Mastercard API compliant OAuth signature in Swift.
                       DESC

  s.homepage         = 'https://github.com/lukereichold/oauth1-signer-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'git' => 'luke@reikam.com' }
  s.source           = { :git => 'https://github.com/lukereichold/oauth1-signer-swift.git', :tag => s.version.to_s }
  s.swift_version    = '4.2'
  s.ios.deployment_target = '11.0'

  s.source_files = 'mc-oauth1-signer/Classes/**/*'
  
  # s.resource_bundles = {
  #   'mc-oauth1-signer' => ['mc-oauth1-signer/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'Foundation', 'Security'
  # s.dependency 'AFNetworking', '~> 2.3'
end

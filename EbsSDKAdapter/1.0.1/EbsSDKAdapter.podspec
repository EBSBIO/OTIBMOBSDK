#
# Be sure to run `pod lib lint EbsSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#


Pod::Spec.new do |s|
  s.name             = 'EbsSDKAdapter'
  s.version          = '1.0.1'
  s.summary          = 'SDK для взаимодействия с МП Биометрия.'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  SDK ЕБС обеспечивает:
  1.	Проверку наличия мобильного приложения для идентификации (МП ЕБС).
  2.	Формирование запроса на прохождение биометрической верификации в ЕБС.
  3.	Взаимодействие пользовательского приложения и МП ЕБС для биометрической верификации.
                       DESC

  s.homepage         = 'https://github.com/EBSBIO/OTIBMOBSDK'
  s.license          =  { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'UBS' => 'sergey.rybchinsky@waveaccess.ru' }
  s.source           = { :git => 'https://github.com/EBSBIO/OTIBMOBSDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'
  s.source_files = 'EbsSDKAdapter/*.swift'
  s.frameworks = 'UIKit'
end

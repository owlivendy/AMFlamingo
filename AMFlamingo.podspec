Pod::Spec.new do |s|
  s.name             = 'AMFlamingo'
  s.version          = '0.1.0'
  s.summary          = 'AMFlamingo is an iOS UI component library providing common UI extension functionalities.'
  s.description      = <<-DESC
AMFlamingo is an iOS UI component library providing common UI extension functionalities:
- UIView Extensions: Flow layout support, Nib loading support
- UIButton Extensions: Customizable image position, Customizable text position
                       DESC

  s.homepage         = 'https://github.com/owlivendy/AMFlamingo'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'owlivendy' => 'owlivendy@gmail.com' }
  s.source           = { :git => 'https://github.com/owlivendy/AMFlamingo.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'Sources/AMFlamingo/**/*'
  
  s.dependency 'SnapKit', '~> 5.6.0'
end 
Pod::Spec.new do |s|
  s.name             = 'AMFlamingo'
  s.version          = '0.1.0'
  s.summary          = 'AMFlamingo is an iOS UI component library providing common UI extension functionalities.'
  s.description      = <<-DESC
AMFlamingo is an iOS UI component library providing common UI extension functionalities:
- UIView Extensions: Flow layout support, Nib loading support
- UIButton Extensions: Customizable image position, Customizable text position
                       DESC

  s.homepage         = 'https://github.com/your-username/AMFlamingo'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'your-username' => 'your-email@example.com' }
  s.source           = { :git => 'https://github.com/your-username/AMFlamingo.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.5'

  s.source_files = 'Sources/AMFlamingo/**/*'
  
  s.dependency 'SnapKit', '~> 5.0.0'
end 
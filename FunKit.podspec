Pod::Spec.new do |s|

  s.name         = "FunKit"
  s.version      = "0.0.2"
  s.summary      = "A Functional Toolkit for Swift."

  s.description  = <<-DESC
FunKit integrates railway-oriented programming with promises, providing a novel way to build Swift applications.
DESC

  s.homepage     = "https://github.com/Weebly/FunKit"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = "jacob berkman"

  s.platform     = :ios, "10.0"

  s.source       = { :git => "https://github.com/Weebly/FunKit.git", :tag => "v#{s.version}" }

  s.source_files  = "FunKit/*.swift"
  # s.public_header_files = "Classes/**/*.h"

end

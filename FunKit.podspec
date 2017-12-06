Pod::Spec.new do |s|

  s.name         = "FunKit"
  s.version      = "0.0.1"
  s.summary      = "A Functional Toolkit for Swift."

  s.description  = <<-DESC
FunKit integrates railway-oriented programming with promises, providing a novel way to build Swift applications.
It remains to be seen whether or not this is a good thing.
DESC

  s.homepage     = "https://github.com/Weebly/FunKit"
  s.license      = { :type => "BSD", :file => "LICENSE" }

  s.author             = { "jacob berkman" => "jberkman@weebly.com" }

  s.platform     = :ios, "11.0"

  s.source       = { :git => "https://github.com/Weebly/FunKit.git", :tag => "#{s.version}" }

  s.source_files  = "FunKit/*.swift"
  # s.public_header_files = "Classes/**/*.h"

end

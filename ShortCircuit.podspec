Pod::Spec.new do |s|

  s.name = "ShortCircuit"
  s.version = "0.2.0"
  s.summary = "Circuit Breaker Pattern framework written in Swift"

  s.description = <<-DESC
		Circuit Breaker Pattern framework written in Swift with multiple data source adapters for storage options for device and server
		DESC

  s.homepage = "httsp://github.com/RestlessThinker/ShortCircuit"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Louie Penaflor" => "http://restlessthinker.com" }
  s.social_media_url = "http://twitter.com/RestlessThinker"

  s.osx.deployment_target = "10.9"
  s.ios.deployment_target = "8.0"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  s.source = { :git => "https://github.com/RestlessThinker.com/ShortCircuit.git", :tag => "#{s.version}" }
  s.source_files = "ShortCircuit/*.swift"

end

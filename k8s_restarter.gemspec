require_relative 'lib/k8s_restarter/version'

Gem::Specification.new do |spec|
  spec.name          = "k8s_restarter"
  spec.version       = K8sRestarter::VERSION
  spec.authors       = ["Alexander Olofsson"]
  spec.email         = ["ace@haxalot.com"]

  spec.summary       = 'Automatically restart stuck Kubernetes workloads'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/ananace/ruby-k8s-restarter'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  spec.files         = Dir['{bin,lib}/**/*.rb']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.add_dependency 'k8s-ruby', '~> 0.13'
  spec.add_dependency 'logging'
end

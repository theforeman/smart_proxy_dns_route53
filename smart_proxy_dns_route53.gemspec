require File.expand_path('../lib/smart_proxy_dns_route53/dns_route53_version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'smart_proxy_dns_route53'
  s.version     = Proxy::Dns::Route53::VERSION
  s.date        = Date.today.to_s
  s.license     = 'GPLv3'
  s.authors     = ['Foreman developers']
  s.email       = ['foreman-dev@googlegroups.com']
  s.homepage    = 'https://github.com/theforeman/smart_proxy_dns_route53'

  s.summary     = "Route 53 DNS provider plugin for Foreman's smart proxy"
  s.description = "Route 53 DNS provider plugin for Foreman's smart proxy"

  s.files       = Dir['{config,lib,bundler.d}/**/*'] + ['README.md', 'LICENSE']
  s.test_files  = Dir['test/**/*']

  s.add_dependency 'route53', '>= 0.4.0'

  s.add_development_dependency('rake', '< 11')
  s.add_development_dependency('mocha')
  s.add_development_dependency('test-unit')
end

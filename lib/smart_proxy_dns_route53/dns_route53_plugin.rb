require 'smart_proxy_dns_route53/dns_route53_version'
require 'smart_proxy_dns_route53/dns_route53_configuration'

module Proxy::Dns::Route53
  class Plugin < ::Proxy::Provider
    plugin :dns_route53, ::Proxy::Dns::Route53::VERSION

    requires :dns, '>= 1.13'

    default_settings :aws_access_key => nil, :aws_secret_key => nil

    load_classes ::Proxy::Dns::Route53::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::Dns::Route53::PluginConfiguration
  end
end

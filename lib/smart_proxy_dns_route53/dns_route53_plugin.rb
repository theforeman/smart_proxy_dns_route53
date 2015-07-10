require 'smart_proxy_dns_route53/dns_route53_version'

module Proxy::Dns::Route53
  class Plugin < ::Proxy::Provider
    plugin :dns_route53, ::Proxy::Dns::Route53::VERSION,
           :factory => proc { |attrs| ::Proxy::Dns::Route53::Record.record(attrs) }

    requires :dns, '>= 1.10'

    after_activation do
      require 'smart_proxy_dns_route53/dns_route53_main'
    end
  end
end

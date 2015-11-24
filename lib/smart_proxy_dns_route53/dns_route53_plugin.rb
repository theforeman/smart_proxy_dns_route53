require 'smart_proxy_dns_route53/dns_route53_version'

module Proxy::Dns::Route53
  class Plugin < ::Proxy::Provider
    plugin :dns_route53, ::Proxy::Dns::Route53::VERSION

    requires :dns, '>= 1.11'

    validate_presence :aws_access_key, :aws_secret_key

    after_activation do
      require 'smart_proxy_dns_route53/dns_route53_main'
      require 'smart_proxy_dns_route53/route53_dependencies'
    end
  end
end

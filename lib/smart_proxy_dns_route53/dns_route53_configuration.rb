module ::Proxy::Dns::Route53
  class PluginConfiguration
    def load_classes
      require 'smart_proxy_dns_plugin_template/dns_plugin_template_main'
    end

    def load_dependency_injection_wirings(container_instance, settings)
      container_instance.dependency :dns_provider, (lambda do
        ::Proxy::Dns::Route53::Record.new(
            settings[:aws_access_key],
            settings[:aws_secret_key],
            settings[:dns_ttl])
      end)
    end
  end
end

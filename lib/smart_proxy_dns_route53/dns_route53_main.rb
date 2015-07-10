require 'dns/dns'
require 'resolv'
require 'route53'

module Proxy::Dns::Route53
  class Record < ::Proxy::Dns::Record
    include Proxy::Log
    include Proxy::Util

    attr_reader :aws_access_key, :aws_secret_key

    def self.record(attrs = {})
      new(attrs.merge(
        :aws_access_key => ::Proxy::Dns::Route53::Plugin.settings.aws_access_key,
        :aws_secret_key => ::Proxy::Dns::Route53::Plugin.settings.aws_secret_key
      ))
    end

    def initialize options = {}
      @aws_access_key = options[:aws_access_key]
      @aws_secret_key = options[:aws_secret_key]
      raise "dns_route53 provider needs AWS access and secret key options" unless aws_access_key && aws_secret_key
      super(options)
    end

    def create
      case @type
        when "A"
          if ip = dns_find(@fqdn)
            raise(Proxy::Dns::Collision, "#{@fqdn} is already used by #{ip}") unless ip == @value
          else
            zone = get_zone(@fqdn)
            new_record = Route53::DNSRecord.new(@fqdn, 'A', @ttl, [@value], zone)
            resp = new_record.create
            raise "AWS Response Error: #{resp}" if resp.error?
            true
          end
        when "PTR"
          if name = dns_find(@value)
            raise(Proxy::Dns::Collision, "#{@value} is already used by #{name}") unless name == @fqdn
          else
            zone = get_zone(@value)
            new_record = Route53::DNSRecord.new(@value, 'PTR', @ttl, [@fqdn], zone)
            resp = new_record.create
            raise "AWS Response Error: #{resp}" if resp.error?
            true
          end
      end
    end

    def remove
      case @type
        when "A"
          zone = get_zone(@fqdn)
          recordset = zone.get_records
          recordset.each do |rec|
            if rec.name == @fqdn + '.'
              resp = rec.delete
              raise "AWS Response Error: #{resp}" if resp.error?
              return true
            end
          end
          raise Proxy::Dns::NotFound, "Could not find forward record #{@fqdn}"
        when "PTR"
          zone = get_zone(@value)
          recordset = zone.get_records
          recordset.each do |rec|
            if rec.name == @value + '.'
              resp = rec.delete
              raise "AWS Response Error: #{resp}" if resp.error?
              return true
            end
          end
          raise Proxy::Dns::NotFound, "Could not find reverse record #{@value}"
      end
    end

    private

    def conn
      @conn ||= Route53::Connection.new(@aws_access_key, @aws_secret_key)
    end

    def resolver
      @resolver ||= Resolv::DNS.new
    end

    def dns_find key
      if match = key.match(/(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/)
        resolver.getname(match[1..4].reverse.join(".")).to_s
      else
        resolver.getaddress(key).to_s
      end
    rescue Resolv::ResolvError
      false
    end

    def get_zone(fqdn)
      domain = fqdn.split('.', 2).last + '.'
      conn.get_zones(domain)[0]
    end
  end
end

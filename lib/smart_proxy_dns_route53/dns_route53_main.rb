require 'dns/dns'
require 'dns_common/dns_common'
require 'resolv'
require 'route53'

module Proxy::Dns::Route53
  class Record < ::Proxy::Dns::Record
    include Proxy::Log
    include Proxy::Util

    attr_reader :aws_access_key, :aws_secret_key

    def initialize(a_server = nil, a_ttl = nil)
      @aws_access_key = Proxy::Dns::Route53::Plugin.settings.aws_access_key
      @aws_secret_key = Proxy::Dns::Route53::Plugin.settings.aws_secret_key
      super(a_server, a_ttl || ::Proxy::Dns::Plugin.settings.dns_ttl)
    end

    def create_a_record(fqdn, ip)
      if found = dns_find(fqdn)
        raise(Proxy::Dns::Collision, "#{fqdn} is already used by #{ip}") unless found == ip
      else
        zone = get_zone(fqdn)
        new_record = Route53::DNSRecord.new(fqdn, 'A', ttl, [ip], zone)
        resp = new_record.create
        raise "AWS Response Error: #{resp}" if resp.error?
        true
      end
    end

    def create_ptr_record(fqdn, ip)
      if found = dns_find(ip)
        raise(Proxy::Dns::Collision, "#{ip} is already used by #{found}") unless found == fqdn
      else
        zone = get_zone(ip)
        new_record = Route53::DNSRecord.new(ip, 'PTR', ttl, [fqdn], zone)
        resp = new_record.create
        raise "AWS Response Error: #{resp}" if resp.error?
        true
      end
    end

    def remove_a_record(fqdn)
      zone = get_zone(fqdn)
      recordset = zone.get_records
      recordset.each do |rec|
        if rec.name == fqdn + '.'
          resp = rec.delete
          raise "AWS Response Error: #{resp}" if resp.error?
          return true
        end
      end
      raise Proxy::Dns::NotFound, "Could not find forward record #{fqdn}"
    end

    def remove_ptr_record(ip)
      zone = get_zone(ip)
      recordset = zone.get_records
      recordset.each do |rec|
        if rec.name == ip + '.'
          resp = rec.delete
          raise "AWS Response Error: #{resp}" if resp.error?
          return true
        end
      end
      raise Proxy::Dns::NotFound, "Could not find reverse record #{ip}"
    end

    private

    def conn
      @conn ||= Route53::Connection.new(aws_access_key, aws_secret_key)
    end

    def resolver
      @resolver ||= Resolv::DNS.new
    end

    def get_zone(fqdn)
      domain = fqdn.split('.', 2).last + '.'
      conn.get_zones(domain)[0]
    end
  end
end

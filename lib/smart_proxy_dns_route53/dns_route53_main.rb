require 'dns/dns'
require 'dns_common/dns_common'
require 'resolv'
require 'route53'

module Proxy::Dns::Route53
  class Record < ::Proxy::Dns::Record
    include Proxy::Log
    include Proxy::Util

    attr_reader :aws_access_key, :aws_secret_key

    def initialize(aws_access_key, aws_secret_key, ttl = nil)
      @aws_access_key = aws_access_key
      @aws_secret_key = aws_secret_key
      super(nil, ttl)
    end

    def create_a_record(fqdn, ip)
      case a_record_conflicts(fqdn, ip) #returns -1, 0, 1
      when 1 then
        raise(Proxy::Dns::Collision, "#{fqdn} is already used by #{ip}")
      when 0 then
        return nil
      else
        zone = get_zone(fqdn)
        new_record = Route53::DNSRecord.new(fqdn, 'A', ttl, [ip], zone)
        resp = new_record.create
        raise "AWS Response Error: #{resp}" if resp.error?
        true
      end
    end

    def create_ptr_record(fqdn, ptr)
      case ptr_record_conflicts(fqdn, ptr_to_ip(ptr)) #returns -1, 0, 1
      when 1 then
        raise(Proxy::Dns::Collision, "#{ptr} is already in use")
      when 0 then
        return nil
      else
        zone = get_zone(ptr)
        new_record = Route53::DNSRecord.new(ptr, 'PTR', ttl, [fqdn], zone)
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

    def get_zone(name)
      zones = conn.get_zones
      name_arr = name.split('.')
      (1 ... name_arr.size).each do |i|
        search_domain = name_arr.last(name_arr.size - i).join('.') + "."
        zone_select = zones.select { |z| z.name == search_domain }
        return zone_select.first if zone_select.any?
      end
    end
  end
end

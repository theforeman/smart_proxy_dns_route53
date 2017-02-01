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

    def do_create(name, value, type)
      name += '.'
      value += '.' if ['PTR', 'CNAME'].include?(type)

      zone = get_zone(name)
      new_record = Route53::DNSRecord.new(name, type, ttl, [value], zone)
      resp = new_record.create
      raise "AWS Response Error: #{resp}" if resp.error?
      true
    end

    def do_remove(name, type)
      name += '.'

      zone = get_zone(name)
      recordset = zone.get_records
      records = recordset.select {|rec| rec.name == name && rec.type == type}
      raise Proxy::Dns::NotFound.new("Could not find record '#{name}' of type #{type}") if records.empty?

      records.each do |rec|
        resp = rec.delete
        raise "AWS Response Error: #{resp}" if resp.error?
      end

      true
    end

    private

    def conn
      @conn ||= Route53::Connection.new(aws_access_key, aws_secret_key)
    end

    def resolver
      @resolver ||= Resolv::DNS.new
    end

    def get_zone(name)
      zone = conn.get_zones(name)
      raise Proxy::Dns::Error.new("Could not find zone '#{name}'") if zone.nil? || zone.empty?
      zone.first
    end
  end
end

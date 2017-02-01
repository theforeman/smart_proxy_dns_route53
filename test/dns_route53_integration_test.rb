require 'test_helper'

require 'smart_proxy_dns_route53/dns_route53_plugin'
require 'smart_proxy_dns_route53/dns_route53_main'

require 'dns/dependency_injection'

module Proxy::Dns
  module DependencyInjection
    include Proxy::DependencyInjection::Accessors
    def container_instance
      Proxy::DependencyInjection::Container.new do |c|
				c.dependency :dns_provider, (lambda do
					::Proxy::Dns::Route53::Record.new(
							ENV['AWS_ACCESS_KEY'],
							ENV['AWS_SECRET_KEY'])
        end)
      end
    end
  end
end

require 'dns/dns_api'
require 'rack/test'
require 'resolv'

TestRecord = Struct.new(:ip, :type) do
  alias_method :fqdn, :ip
end

class DnsRoute53IntegrationTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    @app = Proxy::Dns::Api.new
  end

  def setup
    omit_if(%w[AWS_ACCESS_KEY AWS_SECRET_KEY AWS_FORWARD_ZONE AWS_REVERSE_V4_ZONE AWS_REVERSE_V6_ZONE].any? { |e| !ENV.has_key?(e) })
    clean_zones
    @record = nil
  end

  def test_create_a_record
    post '/', :fqdn => "test.#{forward_zone}", :value => '192.168.33.33', :type => 'A'
    assert_equal 200, last_response.status
    assert_equal '192.168.33.33', record(forward_zone, "test.#{forward_zone}.", 'A').ip
    assert_equal 'A', @record.type
  end

  def test_create_ptr_v4_record
    post '/', :fqdn => "test.#{forward_zone}.", :value => "33.#{reverse_v4_zone}", :type => 'PTR'
    assert_equal 200, last_response.status
    assert_equal "test.#{forward_zone}.", record(reverse_v4_zone, "33.#{reverse_v4_zone}.", 'PTR').fqdn
    assert_equal 'PTR', @record.type
  end

  def test_create_ptr_v6_record
    post '/', :fqdn => "test.#{forward_zone}.", :value => "1.#{reverse_v6_zone(true)}", :type => 'PTR'
    assert_equal 200, last_response.status
    assert_equal "test.#{forward_zone}.", record(reverse_v6_zone, "1.#{reverse_v6_zone(true)}.", 'PTR').fqdn
    assert_equal 'PTR', @record.type
  end

  def test_create_aaaa_record
    omit 'AAAA support not implemented'
    post '/', :fqdn => "test.#{forward_zone}", :value => '2001:db8::1', :type => 'AAAA'
    assert_equal 200, last_response.status
    assert_equal '2001:db8::1', record(forward_zone, "test.#{forward_zone}.", 'AAAA').ip
    assert_equal 'AAAA', @record.type
  end

  def test_create_cname_record
    omit 'CNAME support not implemented'
    post '/', :fqdn => "test.#{forward_zone}", :value => 'test1.com', :type => 'CNAME'
    assert_equal 200, last_response.status
    assert_equal 'test1.com.', record(forward_zone, "test.#{forward_zone}.", 'CNAME').fqdn
    assert_equal 'CNAME', @record.type
  end

  def test_delete_a_record
    create_record forward_zone, "test.#{forward_zone}.", 'A', '3600', ['1.2.3.4']
    delete "/test.#{forward_zone}"
    assert_equal 200, last_response.status
    assert_nil record(forward_zone, "test.#{forward_zone}.", 'A')
  end

  def test_delete_ptr_record
    create_record reverse_v4_zone, "33.#{reverse_v4_zone}.", 'PTR', '3600', ['test.example.com.']
    delete "/33.#{reverse_v4_zone}"
    assert_equal 200, last_response.status
    assert_nil record(reverse_v4_zone, "33.#{reverse_v4_zone}.", 'PTR')
  end

  def test_delete_aaaa_record
    omit 'AAAA support not implemented'
    create_record forward_zone, "test.#{forward_zone}.", 'AAAA', '3600', ['2001:db8::1']
    delete "/test.#{forward_zone}/AAAA"
    assert_equal 200, last_response.status
    assert_nil record(forward_zone, "test.#{forward_zone}.", 'AAAA')
  end

  def test_delete_explicit_cname_record
    omit 'CNAME support not implemented'
    create_record forward_zone, "test.#{forward_zone}.", 'CNAME', '3600', ['test.example.com.']
    delete "/test.#{forward_zone}/CNAME"
    assert_equal 200, last_response.status
    assert_nil record(forward_zone, "test.#{forward_zone}.", 'CNAME')
  end

  private

  def forward_zone
    ENV['AWS_FORWARD_ZONE'].chomp('.')
  end

  def reverse_v4_zone
    ENV['AWS_REVERSE_V4_ZONE'].chomp('.')
  end

  def reverse_v6_zone(pad = false)
    zone = ENV['AWS_REVERSE_V6_ZONE'].chomp('.')
    if pad
      zeros = '0.' * ((62 - (reverse_v6_zone.length - 'ip6.arpa'.length)) / 2)
      "#{zeros}#{zone}"
    else
      zone
    end
  end

  def conn
    @conn ||= Route53::Connection.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_KEY'])
  end

  def clean_zones
    [forward_zone, reverse_v4_zone, reverse_v6_zone].each do |zone_name|
      zone = conn.get_zones(zone_name)
      raise "Cannot find AWS zone #{zone_name}" if zone.nil?
      zone.first.get_records.each do |record|
        next if %w[SOA NS].include?(record.type)
        raise "AWS error while deleting #{record}: #{response}" if (response = record.delete).error?
      end
    end
  end

  def record(zone_name, name, type)
    zone = conn.get_zones(zone_name)
    raise "Cannot find AWS zone #{zone_name}" if zone.nil?
    record = zone.first.get_records.find { |rec| rec.name == name && rec.type == type }
    @record = record.nil? ? nil : TestRecord.new(record.values.first, record.type)
  end

  def create_record(zone_name, *record)
    zone = conn.get_zones(zone_name)
    raise "Cannot find AWS zone #{zone_name}" if zone.nil?
    response = Route53::DNSRecord.new(*(record.push(zone.first))).create
    raise "Failed to create test record #{record}: #{response}" if response.error?
    record
  end
end

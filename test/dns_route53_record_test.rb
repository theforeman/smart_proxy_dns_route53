require 'test_helper'

require 'smart_proxy_dns_route53/dns_route53_plugin'
require 'smart_proxy_dns_route53/dns_route53_main'

class DnsRoute53RecordTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Route53::Record.new('foo', 'bar', 86400)
  end

  def test_provider_initialization
    assert_equal 'foo', @provider.aws_access_key
    assert_equal 'bar', @provider.aws_secret_key
    assert_equal 86400, @provider.ttl
  end

  def test_do_create_success
    zone = mock()
    @provider.expects(:get_zone).with('test.example.com.').returns(zone)

    dnsrecord = mock(:create => mock(:error? => false))
    Route53::DNSRecord.expects(:new).with('test.example.com.', 'A', 86400, ['10.1.2.3'], zone).returns(dnsrecord)

    assert @provider.do_create('test.example.com', '10.1.2.3', 'A')
  end

  def test_do_create_failure
    zone = mock()
    @provider.expects(:get_zone).with('test.example.com.').returns(zone)

    dnsrecord = mock(:create => mock(:error? => true))
    Route53::DNSRecord.expects(:new).with('test.example.com.', 'A', 86400, ['10.1.2.3'], zone).returns(dnsrecord)

    assert_raise RuntimeError do
      @provider.do_create('test.example.com', '10.1.2.3', 'A')
    end
  end

	def test_remove_not_found
    records = []
    @provider.expects(:get_zone).with('test.example.com.').returns(mock(:get_records => records))
		assert_raise ::Proxy::Dns::NotFound do
      @provider.do_remove('test.example.com', 'A')
    end
	end

	def test_remove_ignores_incorrect_records
    records = [
      mock(:name => 'test.example.com.', :type => 'AAAA'),
      mock(:name => 'other.example.com.')
    ]
    @provider.expects(:get_zone).with('test.example.com.').returns(mock(:get_records => records))
		assert_raise ::Proxy::Dns::NotFound do
      @provider.do_remove('test.example.com', 'A')
    end
	end

	def test_remove_single_record
    records = [mock(:name => 'test.example.com.', :type => 'A', :delete => mock(:error? => false))]
    @provider.expects(:get_zone).with('test.example.com.').returns(mock(:get_records => records))
    assert @provider.do_remove('test.example.com', 'A')
	end

	def test_remove_multiple_records
    records = [
      mock(:name => 'test.example.com.', :type => 'A', :delete => mock(:error? => false)),
      mock(:name => 'test.example.com.', :type => 'A', :delete => mock(:error? => false))
    ]
    @provider.expects(:get_zone).with('test.example.com.').returns(mock(:get_records => records))
    assert @provider.do_remove('test.example.com', 'A')
	end

  def test_get_zone_forward
    conn = mock()
    conn.expects(:get_zones).with('example.com.').returns([:zone])
    @provider.expects(:conn).returns(conn)
    assert_equal :zone, @provider.send(:get_zone, 'test.example.com.')
  end

  def test_get_zone_reverse
    conn = mock()
    conn.expects(:get_zones).with('2.1.10.in-addr.arpa.').returns([:zone])
    @provider.expects(:conn).returns(conn)
    assert_equal :zone, @provider.send(:get_zone, '3.2.1.10.in-addr.arpa.')
  end
end

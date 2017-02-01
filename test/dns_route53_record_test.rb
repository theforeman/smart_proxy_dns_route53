require 'test_helper'

require 'smart_proxy_dns_route53/dns_route53_plugin'
require 'smart_proxy_dns_route53/dns_route53_main'

class DnsRoute53RecordTest < Test::Unit::TestCase
  def setup
    @provider = Proxy::Dns::Route53::Record.new('foo', 'bar', 86400)
  end

  # Test that correct initialization works
  def test_provider_initialization
    assert_equal 'foo', @provider.aws_access_key
    assert_equal 'bar', @provider.aws_secret_key
    assert_equal 86400, @provider.ttl
  end

  # Test A record creation
  def test_create_a
    @provider.expects(:dns_find).returns(false)

    zone = mock()
    @provider.expects(:get_zone).with('test.example.com').returns(zone)

    dnsrecord = mock(:create => mock(:error? => false))
    Route53::DNSRecord.expects(:new).with('test.example.com', 'A', 86400, ['10.1.1.1'], zone).returns(dnsrecord)

    assert @provider.create_a_record(fqdn, ip)
  end

  # Test A record creation fails if the record exists
  def test_create_a_conflict
    @provider.expects(:dns_find).returns('10.2.2.2')
    assert_raise(Proxy::Dns::Collision) { @provider.create_a_record(fqdn, ip) }
  end

  # Test PTR record creation
  def test_create_ptr
    @provider.expects(:dns_find).returns(false)

    zone = mock()
    @provider.expects(:get_zone).with('10.1.1.1').returns(zone)

    dnsrecord = mock(:create => mock(:error? => false))
    Route53::DNSRecord.expects(:new).with('10.1.1.1', 'PTR', 86400, ['test.example.com'], zone).returns(dnsrecord)

    assert @provider.create_ptr_record(fqdn, ip)
  end

  # Test PTR record creation fails if the record exists
  def test_create_ptr_conflict
    @provider.expects(:dns_find).returns('else.example.com')
    assert_raise(Proxy::Dns::Collision) { @provider.create_ptr_record(fqdn, ip) }
  end

  # Test A record removal
  def test_remove_a
    zone = mock(:get_records => [mock(:name => 'test.example.com.', :delete => mock(:error? => false))])
    @provider.expects(:get_zone).with('test.example.com').returns(zone)
    assert @provider.remove_a_record(fqdn)
  end

  # Test A record removal fails if the record doesn't exist
  def test_remove_a_not_found
    @provider.expects(:get_zone).with('test.example.com').returns(mock(:get_records => []))
    assert_raise(Proxy::Dns::NotFound) { assert @provider.remove_a_record(fqdn) }
  end

  # Test PTR record removal
  def test_remove_ptr
    # FIXME: record name seems incorrect for rDNS
    zone = mock(:get_records => [mock(:name => '10.1.1.1.', :delete => mock(:error? => false))])
    @provider.expects(:get_zone).with('10.1.1.1').returns(zone)
    assert @provider.remove_ptr_record(ip)
  end

  # Test PTR record removal fails if the record doesn't exist
  def test_remove_ptr_not_found
    @provider.expects(:get_zone).with('10.1.1.1').returns(mock(:get_records => []))
    assert_raise(Proxy::Dns::NotFound) { assert @provider.remove_ptr_record(ip) }
  end

  def test_get_zone_forward
    zone = stub(:name => 'example.com.')
    conn = mock(:get_zones => [zone])
    @provider.expects(:conn).returns(conn)
    assert_equal zone, @provider.send(:get_zone, 'test.example.com.')
  end

  def test_get_zone_reverse
    zone = stub(:name => '2.1.10.in-addr.arpa.')
    conn = mock(:get_zones => [zone])
    @provider.expects(:conn).returns(conn)
    assert_equal zone, @provider.send(:get_zone, '3.2.1.10.in-addr.arpa.')
  end

  def test_get_zone_reverse_v6
    zone = stub(:name => '8.b.d.0.1.0.0.2.ip6.arpa.')
    conn = mock(:get_zones => [zone])
    @provider.expects(:conn).returns(conn)
    assert_equal zone, @provider.send(:get_zone, '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa.')
  end

  def test_get_zone_longest_match
    zone = stub(:name => 'sub.example.com.')
    other = stub(:name => 'example.com.')
    conn = mock(:get_zones => [other, zone])
    @provider.expects(:conn).returns(conn)
    assert_equal zone, @provider.send(:get_zone, 'host.sub.example.com.')
  end

  private

  def fqdn
    'test.example.com'
  end

  def ip
    '10.1.1.1'
  end
end

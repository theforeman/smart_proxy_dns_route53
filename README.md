# SmartProxyDnsRoute53

This plugin adds a new DNS provider for managing records in Amazon's Route53 service.

## Installation

See [How_to_Install_a_Smart-Proxy_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Smart-Proxy_Plugin)
for how to install Smart Proxy plugins

This plugin is compatible with Smart Proxy 1.10 or higher.

## Configuration

To enable this DNS provider, edit `/etc/foreman-proxy/settings.d/dns.yml` and set:

    :use_provider: dns_route53

You will need an active Amazon Web Services account and to create a new IAM account with access to manage Route53 for the Smart Proxy plugin to work.

Configuration options for this plugin are in `/etc/foreman-proxy/settings.d/dns_route53.yml` and include:

* `:aws_access_key: "ABCDEF123456"` - set to be the Access Key ID of the IAM account
* `:aws_secret_key: "ABCDEF123456!@#$"` - set to be the Secret Access Key of the IAM account

## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) *year* *your name*

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


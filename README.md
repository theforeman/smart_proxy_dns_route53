# Route 53 smart proxy plugin

This plugin adds a new DNS provider for managing records in Amazon's Route 53 service.

## Installation

See [How_to_Install_a_Smart-Proxy_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Smart-Proxy_Plugin)
for how to install Smart Proxy plugins

## Compatibility

| Smart Proxy Version | Plugin Version |
| ------------------- | --------------:|
| >= 1.10, < 1.11     | ~> 1.0         |
| >= 1.11, < 1.13     | ~> 2.0         |
| >= 1.13, < 1.15     | ~> 3.0         |
| >= 1.15             | ~> 4.0         |

## Configuration

To enable this DNS provider, edit `/etc/foreman-proxy/settings.d/dns.yml` and set:

    :use_provider: dns_route53

You will need an active Amazon Web Services account and to create a new IAM account with access to manage Route 53 for the Smart Proxy plugin to work.

Configuration options for this plugin are in `/etc/foreman-proxy/settings.d/dns_route53.yml` and include:

* `:aws_access_key: "ABCDEF123456"` - set to be the Access Key ID of the IAM account
* `:aws_secret_key: "ABCDEF123456!@#$"` - set to be the Secret Access Key of the IAM account

### IAM policy

The IAM account must have the following actions associated via a policy:

* `route53:ListHostedZones` (all resources)
* `route53:ChangeResourceRecordSets` (on all zones being managed)
* `route53:ListResourceRecordSets` (on all zones being managed)

An example policy document follows:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1485852222000",
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Stmt1485852222001",
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/Z1HNC9XBMDGFH9",
                "arn:aws:route53:::hostedzone/Z2MCBLVJI24XOO",
                "arn:aws:route53:::hostedzone/Z5H8WZ62ARI5V"
            ]
        }
    ]
}
```

## Contributing

Fork and send a Pull Request. Thanks!

### Integration test

The integration test runs against the AWS Route 53 API, so requires IAM credentials. To run it locally, set up an IAM policy with actions described above, _plus_ the `route53:GetHostedZone` action.

Three zones must also be set up - a forward, reverse IPv4 and reverse IPv6 zone. The names do not matter. *All records will be deleted* in these zones when running the test, so do not use the zones for any other purpose.

Export the following environment variables:

* `AWS_ACCESS_KEY`, `AWS_SECRET_KEY` - per regular plugin configuration
* `AWS_FORWARD_ZONE`, `AWS_REVERSE_V4_ZONE`, `AWS_REVERSE_V6_ZONE` - zone names that will be under complete control of the test suite

## Copyright

Copyright (c) 2015 Daniel Maraio, Sol Cates, Red Hat Inc. and other contributors

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


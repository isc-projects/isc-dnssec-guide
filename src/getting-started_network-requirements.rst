Network Requirements
====================

From a network perspective, DNS and DNSSEC packets are very similar,
DNSSEC packets are just bigger, which means DNS is more likely to use
TCP. You should test for the following two items, to make sure your
network is ready for DNSSEC:

1. *DNS over TCP*: Verify network connectivity over TCP port 53, this
   may mean updating firewall policies or Access Control List (ACL) on
   routers. See `??? <#dns-uses-tcp>`__ more details.

2. *Large UDP packets*: Some network equipment such as firewalls may
   make assumptions about the size of DNS UDP packets and incorrectly
   reject DNS traffic that appears "too big". You should verify that the
   responses your nameserver generates are being seen by the rest of the
   world. See `??? <#whats-edns0-all-about>`__ for more details.

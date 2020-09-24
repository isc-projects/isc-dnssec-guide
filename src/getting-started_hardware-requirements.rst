Hardware Requirement
====================

Recursive Server Hardware
-------------------------

Enabling DNSSEC validation on a recursive server makes it a validating
resolver. The job of a validating resolver is to fetch additional
information that can be used to computationally verify the answer set.
Below are the areas that should be considered for possible hardware
enhancement for a validating resolver:

1. *CPU*: a validating resolver executes cryptographic functions on many
   of the answers returned, this usually leads to increased CPU usage,
   unless your recursive server has built-in hardware to perform
   cryptographic computations.

2. *System memory*: DNSSEC leads to larger answer sets, and will occupy
   more memory space.

3. *Network interfaces*: although DNSSEC does increase the amount of DNS
   traffic overall, it is unlikely that you need to upgrade your network
   interface card (NIC) on the name server, unless you have some truly
   out-dated hardware.

One of the factors to consider is the destinations of your current DNS
traffic. If your current users spend a lot of time visiting ``.gov`` web
sites, then you should expect a bigger jump in all of the above
categories when validation is enabled, because ``.gov`` is more than 90%
signed. This means, more than 90% of the time, your validating resolver
will be doing what is described in
`??? <#how-does-dnssec-change-dns-lookup>`__. However, if your users
only care about resources in the ``.com`` domain which, as of mid-2020,
is under 1.5% signed [1]_, then your recursive name server is unlikely
to experience significant load increase after enabling DNSSEC
validation.

Authoritative Server Hardware
-----------------------------

On the authoritative server side, DNSSEC is enabled on a zone-by-zone
basis. When a zone is DNSSEC-enabled, it is also known as "signed".
Below are the areas that you should consider for possible hardware
enhancements for an authoritative server with signed zones:

1. *CPU*: DNSSEC signed zone requires periodic re-signing, which is a
   cryptographic function that is CPU intensive. If your DNS zone is
   dynamic or changes frequently, it also adds to higher CPU loads.

2. *System storage*: A signed zone is definitely larger than an unsigned
   zone. How much larger? See
   `??? <#your-zone-before-and-after-dnssec>`__ for a comparison
   example. Roughly speaking, you could expect your zone file to grow at
   least three times as large, usually more.

3. *System memory*: Larger DNS zone files take up not only more storage
   space on the file system, but also more space when they are loaded
   into system memory.

4. *Network interfaces*: While your authoritative name servers will
   begin sending back larger responses, it is unlikely that you need to
   upgrade your network interface card (NIC) on the name server, unless
   you have some truly out-dated hardware.

One of the factors to consider, but you really have no control over, is
how many users who query your domain name have DNSSEC enabled. It was
estimated in late 2014, that roughly 10% to 15% of the Internet DNS
queries were DNSSEC aware. Estimates by
`APNIC <https://www.apnic.net/>`__ suggest that in 2020 about `one
third <https://stats.labs.apnic.net/dnssec>`__ of all queries are
validating queries, although the fractions varies widely on a
per-country basis. This means that more DNS queries for your domain will
take advantage the additional security features, which result in the
increased system load and possibly network traffic.

.. [1]
   https://rick.eng.br/dnssecstat

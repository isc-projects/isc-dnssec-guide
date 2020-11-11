.. _easy-start-guide-for-authoritative-servers:

Easy Start Guide for Signing Authoritative Zones
================================================

This section provides the minimum amount of information to setup a
working DNSSEC-enabled authoritative name server. A DNSSEC-enabled zone
(or "signed" zone) contains additional resource records that are used to
verify the authenticity of its zone information.

To convert a traditional (insecure) DNS zone to a secure one, we need to
create various additional records (DNSKEY, RRSIG, NSEC or NSEC3), and
upload verifiable information (such as DS record) to the parent zone to
complete the chain of trust. For more information about DNSSEC resource
records, please see `??? <#what-does-dnssec-add-to-dns>`__.

.. note::

   In this chapter we assume all configuration files, key files, and
   zone files are stored in
   /etc/bind
   . And most of the times we show examples of running various commands
   as the root user. This is arguably not the best setup, but we don't
   want to distract you from what's important here: learning how to sign
   a zone. There are many best practices for deploying a more secure
   BIND installation, with techniques such as jailed process and
   restricted user privileges, but we are not going to cover any of
   those in this document. We are trusting you, a responsible DNS
   administrator, to take the necessary precautions to secure your
   system.

For our examples below, we will be working with the assumption that
there is an existing insecure zone ``example.com`` that we will be
converting to a secure version.

.. _signing-easy-start-policy-enable:

Enable Automated DNSSEC Zone Maintenance and Key Generation
-----------------------------------------------------------

To sign your zone, you need to add the following statement to its
``zone`` clause in the configuration file:

::

   options {
       directory "/etc/bind";
       recursion no;
       ...
   };

   zone "example.com" in {
       ...
       dnssec-policy default;
       ...
   };

The ``dnssec-policy`` statement causes the zone to be signed and turns
on automatic maintenance for the zone. This includes re-signing the zone
as signatures expire and replacing keys on a periodic basic. The value
``default`` selects the default policy, which contain values suitable
for most situations. We will cover the creation of your own policy in
`??? <#signing-custom-policy>`__ but for the moment we will accept the
default values.

When you are done updating the configuration file, tell ``named`` to
reload the configuration file:

::

   # rndc reconfig

And that's it - BIND will sign your zone.

At this point, before you go away and merrily add ``dnssec-policy``
statements to all your zones, we should mention that like a number of
BIND configuration options, its scope depends on where it is placed. In
the example above, we placed it in a ``zone`` clause, so it applied only
to the zone in question. If we had placed it in a ``view`` clause, it
would have applied to all zones in the view; and if we had placed it in
the ``options`` clause, it would have applied to all zones served by
this instance of BIND.

.. _signing-verification:

Verification
------------

When BIND was reconfigured, it started the process of signing the zone.
The first thing it did was to generate a key for the zone and include it
in the published zone. This is marked by messages similar to the
following appearing in the log file:

::

   07-Apr-2020 16:02:55.045 zone example.com/IN (signed): reconfiguring zone keys
   07-Apr-2020 16:02:55.045 reloading configuration succeeded
   07-Apr-2020 16:02:55.046 keymgr: DNSKEY example.com/ECDSAP256SHA256/10376 (CSK) created for policy default
   07-Apr-2020 16:02:55.046 Fetching example.com/ECDSAP256SHA256/10376 (CSK) from key repository.
   07-Apr-2020 16:02:55.046 DNSKEY example.com/ECDSAP256SHA256/10376 (CSK) is now published
   07-Apr-2020 16:02:55.046 DNSKEY example.com/ECDSAP256SHA256/10376 (CSK) is now active
   07-Apr-2020 16:02:55.048 zone example.com/IN (signed): next key event: 07-Apr-2020 18:07:55.045

It then started signing the zone. How long this takes depends on the
size of your zone, the speed of the server, and how much activity is
taking place. We can check what is happening by using ``rndc``. Just
enter the command

::

   # rndc signing -list example.com

While the signing is in progress, the output will be something like:

::

   Signing with key 10376/ECDSAP256SHA256

and when it is finished:

::

   Done signing with key 10376/ECDSAP256SHA256

When you see the second message, your zone is signed.

Before moving on to the next step of coordinating with your parent zone,
let's make sure everything looks good using ``delv``. What we want to do
is to simulate what a validating resolver would check, by telling
``delv`` to use a specific trust anchor.

First of all, we need to make a copy of the key created by BIND. This
will be in the directory you set with the ``directory`` statement in
your configuration file's ``options`` clause and will be named something
like ``Kexample.com.+013.10376.key``:

::

   # cp /etc/bind/Kexample.com.+013+10376.key /tmp/example.key

The original key file looks like this (actual key shortened for display,
and comments omitted):

::

   # cat /etc/bind/Kexample.com.+013+10376.key

   ...
   example.com. 3600 IN DNSKEY 257 3 13 6saiq99qDB...dqp+o0dw==

We want to edit the copy to be in the ``trust-anchors`` format, so that
it looks like this:

::

   # cat /tmp/example.key
   trust-anchors {
       example.com. static-key 257 3 13 "6saiq99qDB...dqp+o0dw==";
   };

Now we can run the ``delv`` command and point it to using this
trusted-key file to validate the answer it receives from the
authoritative name server 192.168.1.13:

::

   $ delv @192.168.1.13 -a /tmp/example.key +root=example.com example.com. SOA +multiline
   ; fully validated
   example.com.        600 IN SOA ns1.example.com. admin.example.com. (
                   2020040703 ; serial
                   1800       ; refresh (30 minutes)
                   900        ; retry (15 minutes)
                   2419200    ; expire (4 weeks)
                   300        ; minimum (5 minutes)
                   )
   example.com.        600 IN RRSIG SOA 13 2 600 (
                   20200421150255 20200407140255 10376 example.com.
                   jBsz92zwAcGMNV/yu167aKQZvFyC7BiQe1WEnlogdLTF
                   oq4yBQumOhO5WX61LjA17l1DuLWcd/ASwlUZWFGCYQ== )

.. _signing-easy-start-upload-to-parent-zone:

Upload to Parent Zone
---------------------

Everything is done on our name server, now we need to generate some
information to be uploaded to the parent zone to complete the chain of
trust. The formats and the upload methods are actually dictated by your
parent zone's administrator, so contact your registrar or parent zone
administrator to find out what the actual format should be, and how to
deliver or upload the information to your parent zone.

What about your zone between the time you signed it and the time your
parent zone accepts the upload? Well, to the rest of the world, your
zone still appears to be insecure. That is because when a validating
resolver attempts to validate your domain name, it will eventually come
across your parent zone, and your parent zone will indicate that you are
not yet signed (as far as it knows). The validating resolver will then
give up attempting to validate your domain name, and fall back to the
insecure DNS. Basically, before you complete this final step with your
parent zone, your zone is still insecure.

.. note::

   Before uploading to your parent zone, verify that your newly signed
   zone has propagated to all of your name servers (usually zone
   transfers). If some of your name servers still have unsigned zone
   data while the parent tells the world it should be signed, validating
   resolvers around the world will not resolve your domain name.

Here are some examples of what you may upload to your parent zone, with
the DNSKEY/DS data shortened for display. Note that no matter what
formats may be required, the end result will be the parent zone
publishing DS record(s) based on the information you upload. Again,
contact your parent zone administrator(s) to find out what is the
correct format for you.

1. DS Record Format:

   ::

      example.com. 3600 IN DS 10376 13 2 B92E22CAE0...33B8312EF0

2. DNSKEY Format:

   ::

      example.com. 3600 IN DNSKEY 257 3 13 6saiq99qDB...dqp+o0dw==

The DS record format may be generated from the DNSKEY using the
``dnssec-dsfromkey`` tool which is covered in
`??? <#parent-ds-record-format>`__. For more details and examples on how
to work with your parent zone, please see
`??? <#working-with-parent-zone>`__

.. _signing-easy-start-so-what-now:

So... What Now?
---------------

Congratulations, your zone is signed, your secondary servers have
received the new zone data, and the parent zone has accepted your upload
and published your DS record. Your zone is now officially
DNSSEC-enabled. What happens next? Well, that is basically it - BIND
takes care of everything. As for updating your zone file, you can
continue to update them the same way you have been prior to signing your
zone, the normal work flow of editing zone file and using the ``rndc``
command to reload the zone still works the same, and although you are
editing the unsigned version of the zone, BIND will generate the signed
version automatically.

Curious as to what all these commands did to your zone file? Read on to
`Your Zone, Before and After
DNSSEC <#your-zone-before-and-after-dnssec>`__ and find out. If you are
interested in how you can roll this out to your existing primary and
secondary name servers, check out `??? <#recipes-inline-signing>`__ in
`??? <#dnssec-recipes>`__.

Your Zone, Before and After DNSSEC
----------------------------------

When we assigned the default DNSSEC policy to the zone, we provided the
minimal amount of information to essentially convert a traditional DNS
zone into a DNSSEC-enabled zone. This is what the zone looked like
before we started:

::

   $ dig @192.168.1.13 example.com. AXFR +multiline +onesoa

   ; <<>> DiG 9.16.0 <<>> @192.168.1.13 example.com AXFR +multiline +onesoa
   ; (1 server found)
   ;; global options: +cmd
   example.com.        600 IN SOA ns1.example.com. admin.example.com. (
                   2020040700 ; serial
                   1800       ; refresh (30 minutes)
                   900        ; retry (15 minutes)
                   2419200    ; expire (4 weeks)
                   300        ; minimum (5 minutes)
                   )
   example.com.        600 IN NS ns1.example.com.
   ftp.example.com.    600 IN A 192.168.1.200
   ns1.example.com.    600 IN A 192.168.1.1
   web.example.com.    600 IN CNAME www.example.com.
   www.example.com.    600 IN A 192.168.1.100

Below shows the test zone ``example.com`` after we have reloaded the
server configuration. As you can see, the zone grew in size, and the
number of records multiplied:

::

   # dig @192.168.1.13 example.com. AXFR +multiline +onesoa

   ; <<>> DiG 9.16.0 <<>> @192.168.1.13 example.com AXFR +multiline +onesoa
   ; (1 server found)
   ;; global options: +cmd
   example.com.        600 IN SOA ns1.example.com. admin.example.com. (
                   2020040703 ; serial
                   1800       ; refresh (30 minutes)
                   900        ; retry (15 minutes)
                   2419200    ; expire (4 weeks)
                   300        ; minimum (5 minutes)
                   )
   example.com.        300 IN RRSIG NSEC 13 2 300 (
                   20200413050536 20200407140255 10376 example.com.
                   drtV1rJbo5OMi65OJtu7Jmg/thgpdTWrzr6O3Pzt12+B
                   oCxMAv3orWWYjfP2n9w5wj0rx2Mt2ev7MOOG8IOUCA== )
   example.com.        300 IN NSEC ftp.example.com. NS SOA RRSIG NSEC DNSKEY TYPE65534
   example.com.        600 IN RRSIG NS 13 2 600 (
                   20200413130638 20200407140255 10376 example.com.
                   2ipmzm1Ei6vfE9OLowPMsxLBCbjrCpWPgWJ0ekwZBbux
                   MLffZOXn8clt0Ql2U9iCPdyoQryuJCiojHSE2d6nrw== )
   example.com.        600 IN RRSIG SOA 13 2 600 (
                   20200421150255 20200407140255 10376 example.com.
                   jBsz92zwAcGMNV/yu167aKQZvFyC7BiQe1WEnlogdLTF
                   oq4yBQumOhO5WX61LjA17l1DuLWcd/ASwlUZWFGCYQ== )
   example.com.        0 IN RRSIG TYPE65534 13 2 0 (
                   20200413050536 20200407140255 10376 example.com.
                   Xjkom24N6qeCJjg9BMUfuWf+euLeZB169DHvLYZPZNlm
                   GgM2czUDPio6VpQbUw6JE5DSNjuGjgpgXC5SipC42g== )
   example.com.        3600 IN RRSIG DNSKEY 13 2 3600 (
                   20200421150255 20200407140255 10376 example.com.
                   maK75+28oUyDtci3V7wjTsuhgkLUZW+Q++q46Lea6bKn
                   Xj77kXcLNogNdUOr5am/6O6cnPeJKJWsnmTLISm62g== )
   example.com.        0 IN TYPE65534 \# 5 ( 0D28880001 )
   example.com.        3600 IN DNSKEY 257 3 13 (
                   6saiq99qDBb5b4G4cx13cPjFTrIvUs3NW44SvbbHorHb
                   kXwOzeGAWyPORN+pwEV/LP9+FHAF/JzAJYdqp+o0dw==
                   ) ; KSK; alg = ECDSAP256SHA256 ; key id = 10376
   example.com.        600 IN NS ns1.example.com.
   ftp.example.com.    600 IN RRSIG A 13 3 600 (
                   20200413130638 20200407140255 10376 example.com.
                   UYo1njeUA49VhKnPSS3JO4G+/Xd2PD4m3Vaacnd191yz
                   BIoouEBAGPcrEM2BNrgR0op1EWSus9tG86SM1ZHGuQ== )
   ftp.example.com.    300 IN RRSIG NSEC 13 3 300 (
                   20200413130638 20200407140255 10376 example.com.
                   rPADrAMAPIPSF3S45OSY8kXBTYMS3nrZg4Awj7qRL+/b
                   sOKy6044MbIbjg+YWL69dBjKoTSeEGSCSt73uIxrYA== )
   ftp.example.com.    300 IN NSEC ns1.example.com. A RRSIG NSEC
   ftp.example.com.    600 IN A 192.168.1.200
   ns1.example.com.    600 IN RRSIG A 13 3 600 (
                   20200413130638 20200407140255 10376 example.com.
                   Yeojg7qrJmxL6uLTnALwKU5byNldZ9Ggj5XjcbpPvujQ
                   ocG/ovGBg6pdugXC9UxE39bCDl8dua1frjDcRCCZAA== )
   ns1.example.com.    300 IN RRSIG NSEC 13 3 300 (
                   20200413130638 20200407140255 10376 example.com.
                   vukgQme6k7JwCf/mJOOzHXbE3fKtSro+Kc10T6dHMdsc
                   oM1/oXioZvgBZ9cKrQhIAUt7r1KUnrUwM6Je36wWFA== )
   ns1.example.com.    300 IN NSEC web.example.com. A RRSIG NSEC
   ns1.example.com.    600 IN A 192.168.1.1
   web.example.com.    600 IN RRSIG CNAME 13 3 600 (
                   20200413130638 20200407140255 10376 example.com.
                   JXi4WYypofD5geUowVqlqJyHzvcRnsvU/ONhTBaUCw5Y
                   XtifKAXRHWrUL1HIwt37JYPLf5uYu90RfkWLj0GqTQ== )
   web.example.com.    300 IN RRSIG NSEC 13 3 300 (
                   20200413130638 20200407140255 10376 example.com.
                   XF4Hsd58dalL+s6Qu99bG80PQyMf7ZrHEzDiEflRuykP
                   DfBRuf34z27vj70LO1lp2ZiX4BB1ahcEK2ae9ASAmA== )
   web.example.com.    300 IN NSEC www.example.com. CNAME RRSIG NSEC
   web.example.com.    600 IN CNAME www.example.com.
   www.example.com.    600 IN RRSIG A 13 3 600 (
                   20200413050536 20200407140255 10376 example.com.
                   mACKXrDOF5JMWqncSiQ3pYWA6abyGDJ4wgGCumjLXhPy
                   0cMzJmKv2s7G6+tW3TsA6BK3UoMfv30oblY2Mnl4/A== )
   www.example.com.    300 IN RRSIG NSEC 13 3 300 (
                   20200413050536 20200407140255 10376 example.com.
                   1YQ22odVt0TeP5gbNJwkvS684ipDmx6sEOsF0eCizhCv
                   x8osuOATdlPjIEztt+rveaErZ2nsoLor5k1nQAHsbQ== )
   www.example.com.    300 IN NSEC example.com. A RRSIG NSEC
   www.example.com.    600 IN A 192.168.1.100

But this is a really messy way to tell if your zone is properly setup
with DNSSEC. Fortunately, there are tools to help us with that. Read on
to `??? <#how-to-test-authoritative-server>`__ to learn more.

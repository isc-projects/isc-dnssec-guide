.. _dnssec_signing:

Signing
=======

.. _easy_start_guide_for_authoritative_servers:

Easy Start Guide for Signing Authoritative Zones
------------------------------------------------

This section provides the basic information to set up a
working DNSSEC-enabled authoritative name server. A DNSSEC-enabled (or
"signed") zone contains additional resource records that are used to
verify the authenticity of its zone information.

To convert a traditional (insecure) DNS zone to a secure one, we need to
create some additional records (DNSKEY, RRSIG, and NSEC or NSEC3), and
upload verifiable information (such as a DS record) to the parent zone to
complete the chain of trust. For more information about DNSSEC resource
records, please see :ref:`what_does_dnssec_add_to_dns`.

.. note::

   In this chapter, we assume all configuration files, key files, and
   zone files are stored in `/etc/bind`, and most examples show
   commands run as the root user. This may not be ideal, but the point is
   not to distract from what is important here: learning how to sign
   a zone. There are many best practices for deploying a more secure
   BIND installation, with techniques such as jailed process and
   restricted user privileges, but those are not covered
   in this document. We trust you, a responsible DNS
   administrator, to take the necessary precautions to secure your
   system.

For the examples below, we are working with the assumption that
there is an existing insecure zone ``example.com`` that we are
converting to a secure zone.

.. _signing_easy_start_policy_enable:

Enabling Automated DNSSEC Zone Maintenance and Key Generation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To sign a zone, you need to add the following statement to its
``zone`` clause in the BIND 9 configuration file:

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
as signatures expire and replacing keys on a periodic basis. The value
``default`` selects the default policy, which contains values suitable
for most situations. We cover the creation of your own policy in
:ref:`signing-custom-policy`, but for the moment we are accepting the
default values.

When the configuration file is updated, tell ``named`` to
reload the configuration file:

::

   # rndc reconfig

And that's it - BIND signs your zone.

At this point, before you go away and merrily add ``dnssec-policy``
statements to all your zones, we should mention that like a number of
BIND configuration options, its scope depends on where it is placed. In
the example above, we placed it in a ``zone`` clause, so it applied only
to the zone in question. If we had placed it in a ``view`` clause, it
would have applied to all zones in the view; and if we had placed it in
the ``options`` clause, it would have applied to all zones served by
this instance of BIND.

.. _signing_verification:

Verification
~~~~~~~~~~~~

The BIND 9 reconfiguration starts the process of signing the zone.
First, it generates a key for the zone and includes it
in the published zone. The log file shows messages such as these:

::

   07-Apr-2020 16:02:55.045 zone example.com/IN (signed): reconfiguring zone keys
   07-Apr-2020 16:02:55.045 reloading configuration succeeded
   07-Apr-2020 16:02:55.046 keymgr: DNSKEY example.com/ECDSAP256SHA256/10376 (CSK) created for policy default
   07-Apr-2020 16:02:55.046 Fetching example.com/ECDSAP256SHA256/10376 (CSK) from key repository.
   07-Apr-2020 16:02:55.046 DNSKEY example.com/ECDSAP256SHA256/10376 (CSK) is now published
   07-Apr-2020 16:02:55.046 DNSKEY example.com/ECDSAP256SHA256/10376 (CSK) is now active
   07-Apr-2020 16:02:55.048 zone example.com/IN (signed): next key event: 07-Apr-2020 18:07:55.045

It then starts signing the zone. How long this process takes depends on the
size of the zone, the speed of the server, and how much activity is
taking place. We can check what is happening by using ``rndc``,
entering the command:

::

   # rndc signing -list example.com

While the signing is in progress, the output is something like:

::

   Signing with key 10376/ECDSAP256SHA256

and when it is finished:

::

   Done signing with key 10376/ECDSAP256SHA256

When the second message appears, your zone is signed.

Before moving on to the next step of coordinating with the parent zone,
let's make sure everything looks good using ``delv``. We want to
simulate what a validating resolver will check, by telling
``delv`` to use a specific trust anchor.

First, we need to make a copy of the key created by BIND. This
is in the directory you set with the ``directory`` statement in
your configuration file's ``options`` clause, and is named something
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

Now we can run the ``delv`` command and instruct it to use this
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

.. _signing_easy_start_upload_to_parent_zone:

Uploading Information to the Parent Zone
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once everything is complete on our name server, we need to generate some
information to be uploaded to the parent zone to complete the chain of
trust. The formats and the upload methods are actually dictated by your
parent zone's administrator, so contact your registrar or parent zone
administrator to find out what the actual format should be, and how to
deliver or upload the information to the parent zone.

What about your zone between the time you signed it and the time your
parent zone accepts the upload? To the rest of the world, your
zone still appears to be insecure, because if a validating
resolver attempts to validate your domain name via
your parent zone, your parent zone will indicate that you are
not yet signed (as far as it knows). The validating resolver will then
give up attempting to validate your domain name, and fall back to the
insecure DNS. Until you complete this final step with your
parent zone, your zone remains insecure.

.. note::

   Before uploading to your parent zone, verify that your newly signed
   zone has propagated to all of your name servers (usually via zone
   transfers). If some of your name servers still have unsigned zone
   data while the parent tells the world it should be signed, validating
   resolvers around the world cannot resolve your domain name.

Here are some examples of what you may upload to your parent zone, with
the DNSKEY/DS data shortened for display. Note that no matter what
formats may be required, the end result is the parent zone
publishing DS record(s) based on the information you upload. Again,
contact your parent zone administrator(s) to find out what is the
correct format for you.

1. DS record format:

   ::

      example.com. 3600 IN DS 10376 13 2 B92E22CAE0...33B8312EF0

2. DNSKEY format:

   ::

      example.com. 3600 IN DNSKEY 257 3 13 6saiq99qDB...dqp+o0dw==

The DS record format may be generated from the DNSKEY using the
``dnssec-dsfromkey`` tool, which is covered in
:ref:`parent_ds_record_format`. For more details and examples on how
to work with your parent zone, please see
:ref:`working_with_parent_zone`.

.. _signing_easy_start_so_what_now:

So... What Now?
~~~~~~~~~~~~~~~

Congratulations! Your zone is signed, your secondary servers have
received the new zone data, and the parent zone has accepted your upload
and published your DS record. Your zone is now officially
DNSSEC-enabled. What happens next? That is basically it - BIND
takes care of everything else. As for updating your zone file, you can
continue to update it the same way as prior to signing your
zone; the normal work flow of editing a zone file and using the ``rndc``
command to reload the zone still works as usual, and although you are
editing the unsigned version of the zone, BIND generates the signed
version automatically.

Curious as to what all these commands did to your zone file? Read on to
:ref:`your_zone_before_and_after_dnssec` and find out. If you are
interested in how to roll this out to your existing primary and
secondary name servers, check out :ref:`recipes_inline_signing` in
:ref:`dnssec_recipes`.

.. _your_zone_before_and_after_dnssec:

Your Zone, Before and After DNSSEC
----------------------------------

When we assigned the default DNSSEC policy to the zone, we provided the
minimal amount of information to convert a traditional DNS
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

Below shows the test zone ``example.com`` after reloading the
server configuration. Clearly, the zone grew in size, and the
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

But this is a really messy way to tell if the zone is set up properly
with DNSSEC. Fortunately, there are tools to help us with that. Read on
to :ref:`how_to_test_authoritative_server` to learn more.

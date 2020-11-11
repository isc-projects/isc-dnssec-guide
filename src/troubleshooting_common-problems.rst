.. _troubleshooting-common-problems:

Common Problems
===============

.. _troubleshooting-security-lameness:

Security Lameness
-----------------

Similar to Lame Delegation in traditional DNS, this refers to the
symptom when the parent zone holds a set of DS records that point to
something that does not exist in the child zone. The resulting symptom
is that the entire child zone may "disappear", being marked as bogus by
validating resolvers.

Below is an example attempting to resolve the A record for a test domain
name www.example.net. From the user's perspective, as described in
`??? <#how-do-i-know-i-have-a-validation-problem>`__, only SERVFAIL
message is returned. On the validating resolver, we could see the
following messages in syslog:

::

   named[126063]: validating example.net/DNSKEY: no valid signature found (DS)
   named[126063]: no valid RRSIG resolving 'example.net/DNSKEY/IN': 10.53.0.2#53
   named[126063]: broken trust chain resolving 'www.example.net/A/IN': 10.53.0.2#53

This gives us a hint that it is a broken trust chain issue. Let's take a
look at the DS records that are published for the zone. We have
highlighted in the key tag ID returned, and shortened the keys for
display:

::

   $ dig @10.53.0.3 example.net. DS

   ; <<>> DiG 9.16.0 <<>> @10.53.0.3 example.net DS
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 59602
   ;; flags: qr rd ra ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags:; udp: 4096
   ; COOKIE: 7026d8f7c6e77e2a010000005e735d7c9d038d061b2d24da (good)
   ;; QUESTION SECTION:
   ;example.net.           IN  DS

   ;; ANSWER SECTION:
   example.net.        256 IN  DS  14956 8 2 9F3CACD...D3E3A396

   ;; Query time: 0 msec
   ;; SERVER: 10.53.0.3#53(10.53.0.3)
   ;; WHEN: Thu Mar 19 11:54:36 GMT 2020
   ;; MSG SIZE  rcvd: 116

Next, we query for the DNSKEY and RRSIG of example.net, to see if
there's anything wrong. Since we are having trouble validating, we
flipped on the ``+cd`` option to disable checking for now to get the
results back, even though they do not pass the validation tests. The
``+multiline`` option tells ``dig`` to print the type, algorithm type,
and key id for DNSKEY records. Again, key tag ID's are highlighted, and
some long strings are shortened for display:

::

   $ dig @10.53.0.3 example.net. DNSKEY +dnssec +cd +multiline

   ; <<>> DiG 9.16.0 <<>> @10.53.0.3 example.net DNSKEY +cd +multiline +dnssec
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 42980
   ;; flags: qr rd ra cd; QUERY: 1, ANSWER: 4, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags: do; udp: 4096
   ; COOKIE: 4b5e7c88b3680c35010000005e73722057551f9f8be1990e (good)
   ;; QUESTION SECTION:
   ;example.net.       IN DNSKEY

   ;; ANSWER SECTION:
   example.net.        287 IN DNSKEY 256 3 8 (
                   AwEAAbu3NX...ADU/D7xjFFDu+8WRIn
                   ) ; ZSK; alg = RSASHA256 ; key id = 35328
   example.net.        287 IN DNSKEY 257 3 8 (
                   AwEAAbKtU1...PPP4aQZTybk75ZW+uL
                   6OJMAF63NO0s1nAZM2EWAVasbnn/X+J4N2rLuhk=
                   ) ; KSK; alg = RSASHA256 ; key id = 27247
   example.net.        287 IN RRSIG DNSKEY 8 2 300 (
                   20811123173143 20180101000000 27247 example.net.
                   Fz1sjClIoF...YEjzpAWuAj9peQ== )
   example.net.        287 IN RRSIG DNSKEY 8 2 300 (
                   20811123173143 20180101000000 35328 example.net.
                   seKtUeJ4/l...YtDc1rcXTVlWIOw= )

   ;; Query time: 0 msec
   ;; SERVER: 10.53.0.3#53(10.53.0.3)
   ;; WHEN: Thu Mar 19 13:22:40 GMT 2020
   ;; MSG SIZE  rcvd: 962

Here is our problem: the parent zone is telling the world that
``example.net`` is using the key 14956, but the authoritative server is
saying: no no no, I am using keys 27247 and 35328. There might be
several causes for this mismatch; one possibility is that a malicious
attacker has compromised one side and change the data. The more likely
scenario is that the DNS administrator for the child zone did not upload
the correct key information to the parent zone.

.. _troubleshooting-incorrect-time:

Incorrect Time
--------------

In DNSSEC, every record will come with at least one RRSIG, and RRSIG
contains two timestamps indicating when it starts becoming valid, and
when it expires. If the validating resolver's current system time does
not fall within the RRSIG two timestamps, the following error messages
occur in BIND debug log.

First, the example below shows the log messages when the RRSIG has
expired. This could mean the validating resolver system time is
incorrectly set too far in the future, or the zone administrator has not
kept up with RRSIG maintenance.

::

   validating example.com/DNSKEY: verify failed due to bad signature (keyid=19036): RRSIG has expired

The logs below show RRSIG validity period has not begun. This could mean
validation resolver system is incorrectly set too far in the past, or
the zone administrator has incorrectly generated signatures for this
domain name.

::

   validating example.com/DNSKEY: verify failed due to bad signature (keyid=4521): RRSIG validity period has not begun

.. _troubleshooting-unable-to-load-keys:

Unable to Load Keys
-------------------

This is a simple yet common issue. If the keys files were present but
not readable by ``named``, the syslog messages are clear, as shown
below:

::

   named[32447]: zone example.com/IN (signed): reconfiguring zone keys
   named[32447]: dns_dnssec_findmatchingkeys: error reading key file Kexample.com.+008+06817.private: permission denied
   named[32447]: dns_dnssec_findmatchingkeys: error reading key file Kexample.com.+008+17694.private: permission denied
   named[32447]: zone example.com/IN (signed): next key event: 27-Nov-2014 20:04:36.521

However, if no keys are found, the error is not as obvious. Below shows
the syslog messages after executing ``rndc
  reload``, with the key files missing from the key directory:

::

   named[32516]: received control channel command 'reload'
   named[32516]: loading configuration from '/etc/bind/named.conf'
   named[32516]: reading built-in trusted keys from file '/etc/bind/bind.keys'
   named[32516]: using default UDP/IPv4 port range: [1024, 65535]
   named[32516]: using default UDP/IPv6 port range: [1024, 65535]
   named[32516]: sizing zone task pool based on 6 zones
   named[32516]: the working directory is not writable
   named[32516]: reloading configuration succeeded
   named[32516]: reloading zones succeeded
   named[32516]: all zones loaded
   named[32516]: running
   named[32516]: zone example.com/IN (signed): reconfiguring zone keys
   named[32516]: zone example.com/IN (signed): next key event: 27-Nov-2014 20:07:09.292

This happens to look exactly the same as if the keys were present and
readable, and ``named`` loaded the keys and signed the zone. It will
even generate the internal (raw) files:

::

   # cd /etc/bind/db
   # ls
   example.com.db  example.com.db.jbk  example.com.db.signed

If ``named`` really loaded the keys and signed the zone, you should see
the following files:

::

   # cd /etc/bind/db
   # ls
   example.com.db  example.com.db.jbk  example.com.db.signed  example.com.db.signed.jnl

So, unless you see the ``*.signed.jnl`` file, your zone has not been
signed.

.. _troubleshooting-invalid-trust-anchors:

Invalid Trust Anchors
---------------------

In most cases, you will never need to explicitly configure trust
anchors. ``named`` is supplied with the current root trust anchor and,
with the default setting of ``dnssec-validation``, will update it on the
infrequent occasions on which it is changed.

iHowever, in some circumstances you may need to explicitly configure
your own trust anchor. As we have seen in the section
`??? <#trust-anchors>`__, whenever a DNSKEY is received by the
validating resolver, it is actually compared to the list of keys the
resolver has explicitly trusted to see if further action is needed. If
the two keys match, the validating resolver stops performing further
verification and returns the answer(s) as validated.

But what if the key file on the validating resolver is misconfigured or
missing? Below we show some examples of log messages when things are not
working properly.

First of all, if the key you copied is malformed, BIND will not even
start up and you will likely find this error message in syslog:

::

   named[18235]: /etc/bind/named.conf.options:29: bad base64 encoding
   named[18235]: loading configuration: failure

If the key is a valid base64 string, but the key algorithm is incorrect,
or if the wrong key is installed, the first thing you will notice is
that pretty much all of your DNS lookups result in SERVFAIL, even when
you are looking up domain names that have not been DNSSEC-enabled. Below
shows an example of querying a recursive server 10.53.0.3:

::

   $ dig @10.53.0.3 www.example.com. A

   ; <<>> DiG 9.16.0 <<>> @10.53.0.3 www.example.org A +dnssec
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 29586
   ;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags: do; udp: 4096
   ; COOKIE: ee078fc321fa1367010000005e73a58bf5f205ca47e04bed (good)
   ;; QUESTION SECTION:
   ;www.example.org.       IN  A

``delv`` shows similar result:

::

   $ delv @192.168.1.7 www.example.com. +rtrace
   ;; fetch: www.example.com/A
   ;; resolution failed: SERVFAIL

The next symptom you will see is in the DNSSEC log messages:

::

   managed-keys-zone: DNSKEY set for zone '.' could not be verified with current keys
   validating ./DNSKEY: starting
   validating ./DNSKEY: attempting positive response validation
   validating ./DNSKEY: no DNSKEY matching DS
   validating ./DNSKEY: no DNSKEY matching DS
   validating ./DNSKEY: no valid signature found (DS)

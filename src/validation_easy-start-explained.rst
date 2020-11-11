Validation Easy Start Explained
===============================

In `??? <#easy-start-guide-for-recursive-servers>`__, we used one line
of configuration to turn on DNSSEC validation, the act of chasing down
signatures and keys, making sure they are authentic. Now we are going to
take a closer look at what it actually does, and some other options.

.. _dnssec-validation-explained:

dnssec-validation
-----------------

::

   options {
       dnssec-validation auto;
   };

This “auto” line enables automatic DNSSEC trust anchor configuration
using the ``managed-keys`` feature. In this case, no manual key
configuration is needed. There are three possible choices for the
``dnssec-validation`` option:

-  *yes*: DNSSEC validation is enabled, but a trust anchor must be
   manually configured. No validation will actually take place until you
   have manually configured at least one trusted key.

-  *no*: DNSSEC validation is disabled, and recursive server will behave
   in the "old fashioned" way of performing insecure DNS lookups.

-  *auto*: DNSSEC validation is enabled, and a default trust anchor
   (included as part of BIND) for the DNS root zone is used. This is the
   default, being what BIND will do if you don't include a
   ``dnssec-validation`` line in your configuration file.

Let's discuss the difference between <yes> and <auto>. If you set it to
<yes> the trust anchor will need to be manually defined and maintained
using the ``trust-anchors`` statement (with either the ``static-key`` or
``static-ds`` modifier) in the configuration file; if you set it to
<auto> (the default, and as shown in the example), then no further
action should be required as BIND includes a copy [1]_ of the root key.
When set to <auto>, BIND will automatically keep the keys (also known as
trust anchors, which we will look at in `??? <#trust-anchors>`__)
up-to-date without intervention from the DNS administrator.

We recommend using the default <auto> unless you have a good reason for
requiring a manual trust anchor. To learn more about trust anchors,
please refer to `??? <#trusted-keys-and-managed-keys>`__.

How Does DNSSEC Change DNS Lookup (Revisited)?
----------------------------------------------

So by now you've enabled validation on your recursive name server, and
verified that it works. What exactly changed? In
`??? <#how-does-dnssec-change-dns-lookup>`__ we looked at the very high
level, simplified 12-steps of DNSSEC validation process. Let's revisit
that process now and see what your validating resolver is doing in more
detail. Again, we are using the example to lookup the A record for the
domain name ``www.isc.org`` (`??? <#dnssec-12-steps>`__):

1.  The validating resolver queries the ``isc.org`` name servers for the
    A record of ``www.isc.org``. This query has the ``DNSSEC
        OK`` (``do``) bit set to 1, notifying the remote authoritative
    server that DNSSEC answers are desired.

2.  As the zone ``isc.org`` is signed, and its name servers are
    DNSSEC-aware, it responds with the answer to the A record query plus
    the RRSIG for the A record.

3.  The validating resolver queries for the DNSKEY for ``isc.org``.

4.  The ``isc.org`` name server responds with the DNSKEY and RRSIG
    records. The DNSKEY is used to verify the answers received in #2.

5.  The validating resolver queries the parent (``.org``) for the DS
    record for ``isc.org``.

6.  The ``.org`` name server is also DNSSEC-aware, so responds with the
    DS and RRSIG records. The DS record is used to verify the answers
    received in #4.

7.  The validating resolver queries for the DNSKEY for ``.org``.

8.  The ``.org`` name server responds with DNSKEY and RRSIG. The DNSKEY
    is used to verify the answers received in #6.

9.  The validating resolver queries the parent (root) for the DS record
    for ``.org``.

10. The root name server, being DNSSEC-aware, responds with DS and RRSIG
    records. The DS record is used to verify the answers received in #8.

11. The validating resolver queries for the DNSKEY for root.

12. The root name server responds with DNSKEY and RRSIG. The DNSKEY is
    used to verify the answers received in #10.

After step #12, the validating resolver takes the DNSKEY received and
compares to the key or keys it has configured, to decide whether or not
the received key can be trusted. We will talk about these locally
configured keys, or trust anchors, in `??? <#trust-anchors>`__.

As you can see here, with DNSSEC, every response includes not just the
answer, but a digital signature (RRSIG) as well. This is so the
validating resolver can verify the answer received, and that's what we
will look at in the next section, `How are Answers
Verified? <#how-are-answers-verified>`__.

How are Answers Verified?
-------------------------

.. note::

   Keep in mind as you read this section, that although words like
   encryption
   and
   decryption
   are used from time to time, DNSSEC does not provide you with privacy.
   Public key cryptography is used to provide data authenticity (who
   sent it) and data integrity (it did not change during transit), but
   any eavesdropper can still see your DNS requests and responses in
   clear text, even when DNSSEC is enabled.

So how exactly are DNSSEC answers verified? Before we can talk about how
they are verified, let's first see how verifiable information is
generated. On the authoritative server, each DNS record (or message) is
run through a hash function, then this hashed value is encrypted by a
private key. This encrypted hash value is the digital signature.

.. figure:: ../img/signature-generation.png
   :alt: Signature Generation
   :width: 80.0%

   Signature Generation

When the validating resolver queries for the resource record, it
receives both the plain-text message and the digital signature(s). The
validating resolver knows the hash function used (listed in the digital
signature record itself), so it can take the plain-text message and run
it through the same hash function to produce a hashed value, let's call
it hash value X. The validating resolver can also obtain the public key
(published as DNSKEY records), decrypt the digital signature, and get
back the original hashed value produced by the authoritative server,
let's call it hash value Y. If hash values X and Y are identical, and
the time is correct (more on what this means below), the answer is
verified, meaning we know this answer came from the authoritative server
(authenticity), and the content remained intact during transit
(integrity).

.. figure:: ../img/signature-verification.png
   :alt: Signature Verification
   :width: 80.0%

   Signature Verification

Take the A record ``ftp.isc.org`` for example, the plain text is:

::

   ftp.isc.org.     4 IN A  149.20.1.49

The digital signature portion is:

::

   ftp.isc.org.      300 IN RRSIG A 13 3 300 (
                   20200401191851 20200302184340 27566 isc.org.
                   e9Vkb6/6aHMQk/t23Im71ioiDUhB06sncsduoW9+Asl4
                   L3TZtpLvZ5+zudTJC2coI4D/D9AXte1cD6FV6iS6PQ== )

When a validating resolver queries for the A record ``ftp.isc.org``, it
receives both the A record and the RRSIG record. It runs the A record
through a hash function (in this example, it would be SHA256 as
indicated by the number 13, signifying ECDSAP256SHA256) and produces
hash value X. The resolver also fetches the appropriate DNSKEY record to
decrypt the signature, and the result of the decryption is hash value Y.

But wait! There's more! Just because X equals Y doesn't mean everything
is good. We still have to look at the time. Remember we mentioned a
little earlier that we need to check if the time is correct? Well, look
at the two highlighted timestamps in our example above, the two
timestamps are:

-  Signature Expiration: 20200401191851

-  Signature Inception: 20200302184340

This tells us that this signature was generated UTC March 2nd, 2020, at
6:43:40 PM (20200302184340), and it is good until UTC April 1st, 2020,
7:18:51 PM (20200401191851). And the validating resolver's current
system time needs to fall between these two timestamps. Otherwise the
validation fails, because it could be an attacker replaying an old
captured answer set from the past, or feeding us a crafted one with
incorrect future timestamps.

If the answer passes both hash value check and timestamp check, it is
validated, and the authenticated data (``ad``) bit is set, and response
is sent to the client; if it does not verify, a SERVFAIL is returned to
the client.

.. [1]
   BIND technically includes two copies of the root key, one is in
   ``bind.keys.h`` and is built into the executable, and one is in
   ``bind.keys`` as a ``trust-anchors`` statement. The two copies of the
   key are identical.

How Does DNSSEC Change DNS Lookup?
==================================

Traditional (insecure) DNS lookup is simple: a recursive name server
receives a query from a client to lookup the name ``www.isc.org``. The
recursive name server tracks down the authoritative name server(s)
responsible, sends the query to one of the authoritative name servers,
and waits for the authoritative name server to respond with the answer.

With DNSSEC validation enabled, a validating recursive name server
(a.k.a. a *validating resolver*) will ask for additional resource
records in its query, hoping the remote authoritative name servers will
respond with more than just the answer to the query, but some proof to
go along with the answer as well. If DNSSEC responses are received, the
validating resolver will perform cryptographic computation to verify the
authenticity (origin of the data) and integrity (data was not altered
during transit) of the answers, and even ask the parent zone as part of
the verification. It will repeat this process of get-key, validate,
ask-parent, parent, and its parent, and its parent, all the way until
the validating resolver reaches a key that it trusts. In the ideal,
fully deployed world of DNSSEC, all validating resolvers only need to
trust one key: the root key.

The following example shows the DNSSEC validating process of looking up
the name ``www.isc.org`` at a very high level:

1.  Upon receiving a DNS query from a client to resolve ``www.isc.org``,
    the validating resolver follows standard DNS protocol to track down
    the name server for ``isc.org``, sends it a DNS query to ask for the
    A record of ``www.isc.org``. But since this is a DNSSEC-enabled
    resolver, the outgoing query has a bit set indicating it wants
    DNSSEC answers, hoping the name server who receives it speaks DNSSEC
    and can honor this secure request.

2.  The ``isc.org`` name server is DNSSEC-enabled, so responds with both
    the answer (in this case, an A record) and a digital signature for
    verification purpose.

3.  In order for the validating resolver to be able to verify the
    digital signature, it requires cryptographic keys. So it asks the
    ``isc.org`` name server for those keys.

4.  The ``isc.org`` name server responds with the cryptographic keys
    (and digital signatures of the keys) used to generate the digital
    signature that was sent in #2. At this point, the validating
    resolver can use this information to verify the answers received in
    #2.

    Let's take a quick break here and look at what we've got so far...
    how could we trust this answer? If a clever attacker had taken over
    the ``isc.org`` name server(s), or course she would send matching
    keys and signatures. We need to ask someone else to have confidence
    that we are really talking to the real ``isc.org`` name server. This
    is a critical part of DNSSEC: at some point, the DNS administrators
    at ``isc.org`` had uploaded some cryptographic information to its
    parent, ``.org``; maybe through a secure web form, maybe it was
    through an email exchange, or perhaps it was done in person. No
    matter the case, at some point some verifiable information about the
    child (``isc.org``) was sent to the parent (``.org``) for
    safekeeping.

5.  The validating resolver asks the parent (``.org``) for the
    verifiable information it keeps on its child, ``isc.org``.

6.  Verifiable information is sent from the ``.org`` server. At this
    point, validating resolver compares this to the answer it received
    in #4, and the two of them should match, proving the authenticity of
    ``isc.org``.

    Let's examine this process. You might be thinking to yourself, well,
    what if the clever attacker that took over ``isc.org`` also
    compromised the ``.org`` servers? Of course all this information
    would match! That's why we will turn our attention now to the
    ``.org`` servers, interrogate it for its cryptographic keys, and
    move on one level up to ``.org``'s parent, root.

7.  The validating resolver asks ``.org`` authoritative name servers for
    its cryptographic keys, for the purpose of verifying the answers
    received in #6.

8.  The ``.org`` name server responds with the answer (in this case,
    keys and signatures). At this point, the validating resolver can
    verify the answers received in #6.

9.  The validating resolver asks root (``.org``'s parent) for verifiable
    information it keeps on its child, ``.org``.

10. The root name server sends back the verifiable information it keeps
    on ``.org``. The validating resolver now takes this information and
    uses it to verify the answers received in #8.

    So up to this point, both ``isc.org`` and ``.org`` check out. But
    what about root? What if this attacker is really clever and somehow
    tricked us into thinking she's the root name server? Of course she
    would send us all matching information! So we repeat the
    interrogation process and ask for the keys from the root name
    server.

11. The validating resolver asks root name server for its cryptographic
    keys in order to verify the answer(s) received in #10.

12. The root name server sends its keys; at this point, the validating
    resolver can verify the answer(s) received in #10.

Chain of Trust
--------------

But what about the root server itself? Who do we go to verify root's
keys? There's no parent zone for root. In security, you have to trust
someone, and in the perfectly protected world of DNSSEC (we'll talk
about the current imperfect state later and ways to work around it),
each validating resolver would only have to trust one entity, that is
the root name server. The validating resolver already has the root key
on file (and we'll talk about later how we got the root key file). So
after the answer in #12 is received, the validating resolver compares it
to the key it already has on file. Providing one of the keys in the
answer matches the one on file, we can trust the answer from root. Thus
we can trust ``.org``, and thus we can trust ``isc.org``. This is known
as "chain of trust" in DNSSEC.

We will revisit this 12-step process again later in
`??? <#how-does-dnssec-change-dns-lookup-revisited>`__ with more
technical details.

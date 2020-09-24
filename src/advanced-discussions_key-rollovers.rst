.. _advanced-discussions-key-management:

Rollovers
=========

Key Rollovers
-------------

A key rollover is where one key in a zone is replaced by a new one.
There are arguments for and against regularly rolling keys. In essence
these are:

Pros:

1. Regularly changing the key hinders attempts at determination of the
   private part of the key by cryptanalysis of signatures.

2. It gives us practice at changing a key; should it ever need to be
   changed in an emergency, we would not be doing it for the first time.

Cons:

1. A lot of effort is required to hack a key, and there are probably
   easier ways of obtaining it, e.g. by breaking into the systems on
   which it is stored.

2. Rolling the key adds complexity to the system. We are more likely to
   have an interruption to our service than if we had not rolled it.

Whether or not you roll the key is up to you. How serious would the
damage be if a key were compromised without you knowing about it? How
serious would a key roll failure be?

Before going any further, it is worth noting that if you sign your zone
with either of the fully-automatic methods, you don't really need to
concern yourself with the details of a key rollover: BIND takes care of
it all for you. If you are doing a manual key roll or are setting up the
keys for a semi-automatic key rollover, you do need to concern yourself
with the various steps involved and the timing details.

Rolling a key is not as simple as replacing the DNSKEY statement in the
zone. That is an essential part of it, but timing is everything. For
example, suppose that we run the ``example.com`` zone and that a friend
queries for the AAAA record of ``www.example.com``. As part of the
resolution process (described in
`??? <#how-does-dnssec-change-dns-lookup>`__), their recursive server
looks up the keys for the ``example.com`` zone and uses them to verify
the signature associated with the AAAA record. We'll assume that the
records validated successfully, so all is well so they can use the
address to visit example.com's web site.

Let's assume that immediately after the lookup, we want to roll the ZSK
for ``example.com``. Our first attempt at this is to remove the old
DNSKEY record and signatures, add new DNSKEY record, and re-sign the
zone with it. So one minute our server is serving the old DNSKEY and
records signed with the old key, and the next minute it is serving the
new key and records signed with it. We've achieved our goal - we are
serving a zone signed with the new keys and to check this is really the
case, we booted up our laptop and looked up the AAAA record
``ftp.example.com``. The lookup succeeded so all must be well. Or is it?
Just to be sure, we called our friend and asked them to check. They
tried to lookup ``ftp.example.com`` but got a SERVFAIL response from
their recursive server. So what's going on?

The answer, in one word, is "caching". When they looked up
``www.example.com``, as well as retrieving the AAAA record, their
recursive server retrieved and cached a lot of other records. It cached
the NS records for ``com`` and ``example.com``. It looked up and cached
the AAAA (and A) records for those nameservers (this action possibly
causing the lookup and caching of more NS and AAAA/A records). Most
importantly for this example, it also looked up and cached the DNSKEY
records for the root, ``com`` and ``example.com`` zones. When a query
was made for ``ftp.example.com``, it had already most of the information
we needed. It knew what nameservers served ``example.com`` and their
addresses, so went directly to one of those to get the AAAA record for
``ftp.example.com`` and its associated signature. But when it came to
validate the signature, it used the cached copy of the DNSKEY, and that
is when our friend had the problem. Their recursive server had a copy of
the old DNSKEY in its cache, but the AAAA record for ``ftp.example.com``
was signed with the new key. So not surprisingly, the signature didn't
validate.

So just how should we roll the keys for ``example.com``? A clue to the
answer is to note that the problem came about because the DNSKEY records
were cached by the recursive server. What would have happened had out
user flushed the DNSKEY records from the recursive server's cache before
making the query? That would have worked; those records would have to be
retrieved from ``example.com``'s nameservers at the same time that we
retrieved the AAAA record for ``ftp.example.com``. So we would have
obtained the new key along with the AAAA record and associated signature
created with the new key. All would have been well.

As it is obviously impossible for us to notify all recursive server
operators to flush our DNSKEY records every time we roll a key, we have
to use another solution. That solution is to take our time and to wait
for the recursive servers to remove old records from caches when they
reach their TTL. How exactly we do this depends on whether we are trying
to roll a ZSK, a KSK or a CSK.

ZSK Rollover Methods
~~~~~~~~~~~~~~~~~~~~

The ZSK can be rolled in one of the following two ways:

1. *Pre-publication*: Publish the new ZSK into zone data before it is
   actually used. Wait at least one TTL so the world's recursive servers
   know about both keys, then stop using the old key and generate new
   RRSIG using the new key. Wait at least another TTL, so the cached old
   key data is expunged from world's recursive servers, before removing
   the old key.

   The benefit of the Pre-publication approach is it does not
   dramatically increase the zone size, but the duration of the rollover
   is longer. If insufficient time has passed after the new ZSK is
   published, some resolvers may only have the old ZSK cached when the
   new RRSIG records are published, and validation may fail. This is the
   method that was described in `??? <#recipes-zsk-rollover>`__

2. *Double Signature*: Publish the new ZSK and new RRSIG, essentially
   double the size of the zone. Wait at least one TTL before removing
   the old ZSK and old RRSIG.

   The benefit of the Double Signature approach is that it is easier to
   understand and execute, but suffers from increased zone size
   (essentially double) during a rollover event.

KSK Rollover Methods
~~~~~~~~~~~~~~~~~~~~

Rolling the KSK requires interaction with the parent zone, so
operationally this may be more complex than rolling ZSKs. There are
three methods of rolling the KSK:

1. *Double-KSK*: the new KSK is added to the DNSKEY RRset which is then
   signed with both the old and new key. After waiting for the old RRset
   to expire from caches, the DS record in the parent zone is changed.
   After waiting a further interval for this change to be reflected in
   caches, the old key is removed from the RRset.

   Basically, the new KSK is added first at the child zone and being
   used to sign DNSKEY, then the DS record is changed, followed by the
   removal of the old KSK. Double-KSK limits the interaction with the
   parent zone to a minimum, but for the duration of the rollover, the
   size of the DNSKEY RRset is increased.

2. *Double-DS*: the new DS record is published. After waiting for this
   change to propagate into caches, the KSK is changed. After a further
   interval during which the old DNSKEY RRset expires from caches, the
   old DS record is removed.

   Double-DS is the reverse of Double-KSK: the new DS is published at
   the parent first, then the KSK at the child is updated, then remove
   the old DS at the parent. The benefit is that the size of the DNSKEY
   RRset is kept to a minimum, but interactions with the parent zone is
   increased to two events. This is the method that is described in
   `??? <#recipes-ksk-rollover>`__.

3. *Double-RRset*: the new KSK is added to the DNSKEY RRset which is
   then signed with both the old and new key, and the new DS record
   added to the parent zone. After waiting a suitable interval for the
   old DS and DNSKEY RRsets to expire from caches, the old DNSKEY and DS
   record are removed.

   Double-RRset is the fastest way to roll the KSK (shortest rollover
   time), but has the drawbacks of both of the other methods: a larger
   DNSKEY RRset and two interactions with the parent.

CSK Rollover Methods
~~~~~~~~~~~~~~~~~~~~

Rolling the CSK is more complex than rolling either the ZSK or KSK, as
the timing constraints relating to both the parent zone and the caching
of records by downstream recursive servers have to be taken into
account. There are numerous methods that are a combination of ZSK
rollover and KSK rollover methods. BIND 9 Automatic signing uses a
combination of ZSK Pre-Publication and Double-KSK rollover.

.. _advanced-discussions-emergency-rollovers:

Emergency Key Rollovers
-----------------------

Keys are generally rolled at a regular schedule (that is, if you choose
to roll them at all). But sometimes, you may have to rollover keys
out-of-schedule due to a security incident. The aim of an emergency
rollover is re-sign the zone with a new key as soon as possible, because
when a key is suspected of being compromised, the malicious attacker (or
anyone who has access to the key) could impersonate you, and trick other
validating resolvers into believing that they are receiving authentic,
validated answers.

During an emergency rollover, you would follow the same operational
procedures as described in `??? <#recipes-rollovers>`__, with the added
task of reducing the TTL of current active (possibly compromised) DNSKEY
RRset, in attempt to phase out the compromised key faster before the new
key takes effect. The time frame should be significantly reduced from
the 30-days-apart example, since you probably don't want to wait up to
60 days for the compromised key to be removed from your zone.

Another method is to always carry a spare key with you at all times. You
could always have a second key (pre)published (and hopefully this one
was not compromised the same time as the first key), so if the active
key is compromised, you could save yourself some time to immediately
activate the spare key, and all the validating resolvers should already
have this spare key cached, thus saving you some time.

With KSK emergency rollover, you would have to also consider factors
related to your parent zone, such as how quickly they can remove the old
DS record and published the new ones.

As usual, there is a lot more to consider when it comes to emergency key
rollovers. For more in-depth considerations, please check out `RFC
7583 <https://tools.ietf.org/html/rfc7583>`__.

.. _advanced-discussions-DNSKEY-algorithm-rollovers:

Algorithm Rollovers
-------------------

From time to time new digital signature algorithms with improved
security are introduced, and it may be desirable for administrators to
roll over DNSKEYs to a new algorithm, e.g. from RSASHA1 (algorithm 5 or
7) to RSASHA256 (algorithm 8). The algorithm rollover must be done with
care in a stepwise fashion to avoid breaking DNSSEC validation.

If you are managing DNSSEC by using the ``dnssec-policy`` configuration,
``named`` will handle the rollover for you. Just change the algorithm
for the relevant keys, and ``named`` will use the new algorithm when the
key is next rolled. It will perform a smooth transition to the new
algorithm, ensuring that the zone remains valid throughout rollover.

If you are other methods to sign the zone, you need to do more work. As
with other key rollovers, when the zone is a primary zone, an algorithm
rollover can be accomplished using dynamic updates or automatic key
rollovers. For secondary zones, only automatic key rollovers are
possible, but the ``dnssec-settime`` utility can be used to control the
timing of such.

In any case the first step is to put DNSKEYs using the new algorithm in
place. You must generate the ``K*`` files for the new algorithm and put
them in the zone's key directory where ``named`` can access them. Take
care to set appropriate ownership and permissions on the keys. If the
``auto-dnssec`` zone option is set to ``maintain``, ``named`` will
automatically sign the zone with the new keys based on their timing
metadata when the ``dnssec-loadkeys-interval`` elapses or you issue the
``rndc loadkeys`` command. Otherwise for primary zones, you can use
``nsupdate`` to add the new DNSKEYs to the zone. This will cause named
to use them to sign the zone. For secondary zones, e.g. on a
bump-in-the-wire inline signing server, ``nsupdate`` cannot be used.

Once the zone has been signed by the new DNSKEYs (and you have waited
for at least one TTL), you must inform the parent zone and any trust
anchor repositories of the new KSKs, e.g. you might place DS records in
the parent zone through your DNS registrar's website.

Before starting to remove the old algorithm from a zone, you must allow
the maximum TTL on its DS records in the parent zone to expire. This
will assure that any subsequent queries will retrieve the new DS records
for the new algorithm. After the TTL has expired, you can remove the DS
records for the old algorithm from the parent zone and any trust anchor
repositories. You must then allow another maximum TTL interval to elapse
so that the old DS records disappear from all resolver caches.

The next step is to remove the DNSKEYs using the old algorithm from your
zone. Again this can be accomplished using ``nsupdate`` to delete the
old DNSKEYs (primary zones only) or by automatic key rollover when
``auto-dnssec`` is set to ``maintain``. You can cause the automatic key
rollover to take place immediately by using the ``dnssec-settime``
utility to set the *Delete* date on all keys to any time in the past.
(See ``dnssec-settime -D <date/offset>`` option.)

After adjusting the timing metadata, the ``rndc
  loadkeys`` command will cause ``named`` to remove the DNSKEYs and
RRSIGs for the old algorithm from the zone. Note also that with the
``nsupdate`` method, removing the DNSKEYs also causes ``named`` to
remove the associated RRSIGs automatically.

Once you have verified that the old DNSKEYs and RRSIGs have been removed
from the zone, the final (optional) step is to remove the key files for
the old algorithm from the key directory.

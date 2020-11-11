What does DNSSEC Add to DNS?
============================

.. note::

   Public Key Cryptography works on the concept of a pair of keys, one
   is made available to the world publicly, and one is kept in secrecy
   privately. Not surprisingly, they are known as public key and private
   key. If you are not familiar with the concept, think of it as a
   cleverly designed lock, where one key locks, and one key unlocks. In
   DNSSEC, we give out the unlocking public key to the rest of the
   world, while keeping the locking key private. To learn how this is
   used to secure DNS messages, take a look at
   `??? <#how-are-answers-verified>`__.

DNSSEC introduces six new resource record types:

-  RRSIG (digital signature)

-  DNSKEY (public key)

-  DS (parent-child)

-  NSEC (proof of nonexistence)

-  NSEC3 (proof of nonexistence)

-  NSEC3PARAM (proof of nonexistence)

-  CDS (child-parent signaling)

-  CDNSKEY (child-parent signaling)

This guide will not dissect into the anatomy of each resource record
type, the details are left for the readers to research and explore.
Below is a short introduction on each of the new record types:

-  *RRSIG*: With DNSSEC enabled, just about every DNS answer (A, PTR,
   MX, SOA, DNSKEY, etc.) will come with at least one RRSIG, or resource
   record signature. These signatures are used by recursive name
   servers, also known as validating resolvers, to verify the answers
   received. To learn how digital signatures are generated and used, see
   `??? <#how-are-answers-verified>`__.

-  *DNSKEY*: DNSSEC relies on public key cryptography for data
   authenticity and integrity. There are several keys used in DNSSEC,
   some private, some public. The public keys are published to the world
   as part of the zone data, and they are stored in the DNSKEY record
   type.

   In general, keys in DNSSEC are used for one or both of the following
   roles: as a Zone Signing Key (ZSK), used to protect all zone data; or
   as a Key Signing Key (KSK), used to protect the zone's keys. A key
   that is used for both roles is referred to as a Combined Signing Key
   (CSK). We will talk about keys in more detail in
   `??? <#advanced-discussions-key-generation>`__.

-  *DS*: One of the critical components of DNSSEC is that the parent
   zone can "vouch" for its child zone. The DS record is verifiable
   information (generated from one of the child's public keys) that a
   parent zone publishes about its child as part of the chain of trust.
   To learn more about the Chain of Trust, see
   `??? <#chain-of-trust>`__.

-  *NSEC, NSEC3, NSEC3PARAM*: These resource records all deal with a
   very interesting problem: proving that something does not exist. We
   will look at these record types in more detail in
   `??? <#advanced-discussions-proof-of-nonexistence>`__.

-  *CDS, CDNSKEY*: The CDS and CDNSKEY resource records apply to
   operational matters and are a way to signal to the parent zone that
   the DS records it holds for the child zone should be updated. This is
   covered in more detail in `??? <#cds-cdnskey>`__.

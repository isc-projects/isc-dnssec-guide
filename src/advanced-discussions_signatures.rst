.. _signature-validity-periods:

Signature Validity Periods and Zone Re-Signing Intervals
========================================================

In `??? <#how-are-answers-verified>`__, we saw that record signatures
have a validity period, outside which they are not valid. This means
that at some point, a signature will no longer be valid and a query for
the associated record will fail DNSSEC validation. But how long should a
signature be valid for?

A maximum value for the validity period is determined by the impact of a
replay attack. If this is low, the period can be long; if this is high,
the period should be shorter. There is no right value, but periods of
between a few days to a month seem to be common.

Deciding a minimum value is probably an easier task. Should something
fail (e.g. a hidden primary distributing to secondary servers that
actually answer queries), how long will it be before the failure is
noticed, and how long before it is fixed? If you are a large 24x7
operation with operators always on site, the answer might be less than
an hour. On the other hand in smaller companies, if the failure occurs
just after everyone has gone home for a long weekend, the answer might
be several days.

There are no right values - they depend on your circumstances. The
signature validity period you decide to use should be a value between
the two bounds. At the time of writing, the default policy used by BIND
sets a value of 14 days.

Since the signatures expire, to keep the zone valid, the signatures must
be periodically refreshed, in other words, the zone must be periodically
re-signed. The frequency of the re-signing depends on a number of
considerations. For example, signing puts a load on your server, so if
the server is very highly loaded, a lower frequency is better. Another
consideration is the signature lifetime. Obviously the intervals between
signings must not be longer that the signature validity period. But if
you have set a signature lifetime close to the minimum (see above), the
signing interval must be much shorter (what would happen if the system
fails just before the zone is re-signed?).

Again, there is no right answer, it depends on your circumstances. The
default policy sets the signature refresh interval to 5 days.

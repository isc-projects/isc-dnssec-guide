.. _troubleshooting-nta:

Negative Trust Anchors
======================

BIND 9.11 introduced *Negative Trust Anchors* (NTAs) as a means to
*temporarily* disable DNSSEC validation for a zone when you know that
the zone's DNSSEC is mis-configured.

NTAs are added using the ``rndc`` command, e.g:

::

   $ rndc nta example.com
    Negative trust anchor added: example.com/_default, expires 19-Mar-2020 19:57:42.000
    

The list of currently configured NTAs can also be examined using
``rndc``, e.g:

::

   $ rndc nta -dump
    example.com/_default: expiry 19-Mar-2020 19:57:42.000
    

The default lifetime of an NTA is one hour although, by default, BIND
will poll the zone every five minutes to see if the zone now correctly
validates, at which point the NTA will automatically expire. Both the
default lifetime and the polling interval may be configured via
``named.conf``, and the lifetime can be overridden on a per-zone basis
using the ``-lifetime duration`` parameter to ``rndc nta``. Both timer
values have a permitted maximum value of one week.

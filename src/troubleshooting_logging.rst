.. _troubleshooting-logging:

Logging
=======

DNSSEC validation error messages by default will show up in syslog as a
Query-Error. Here is an example of what it may look like:

::

   validating www.example.org/A: no valid signature found
   RRSIG failed to verify resolving 'www.example.org/A/IN': 10.53.0.2#53

Usually, this level of error logging should suffice for most. If you
would like to get more detailed information about why DNSSEC validation
failed, read on to `BIND DNSSEC Debug
Logging <#troubleshooting-logging-debug>`__ to learn more.

.. _troubleshooting-logging-debug:

BIND DNSSEC Debug Logging
-------------------------

A word of caution: before you enable debug logging, be aware that this
may dramatically increase the load on your name servers.

With that said, sometimes it may become necessary to temporarily enable
BIND debug logging to see more details of how DNSSEC is validating (or
not). DNSSEC-related messages are not recorded in syslog by default,
even if query log is enabled, only DNSSEC errors will show up in syslog.
Enabling debug logging is not recommended for production servers, as it
increases load on the server.

The example below shows how to enable debug level 3 (to see full DNSSEC
validation messages) in BIND 9 and have it sent to syslog:

::

   logging {
      channel dnssec_log {
           syslog daemon;
           severity debug 3;
           print-category yes;
       };
       category dnssec { dnssec_log; };
   };

The example below shows how to log DNSSEC messages to their own file:

::

   logging {
       channel dnssec_log {
           file "/var/log/dnssec.log";
           severity debug 3;
       };
       category dnssec { dnssec_log; };
   };

After restarting BIND, a large number of log messages will appear in
syslog. The example below shows the log messages as a result of
successfully looking up and validating the domain name ``ftp.isc.org``.

::

   validating ./NS: starting
   validating ./NS: attempting positive response validation
     validating ./DNSKEY: starting
     validating ./DNSKEY: attempting positive response validation
     validating ./DNSKEY: verify rdataset (keyid=20326): success
     validating ./DNSKEY: marking as secure (DS)
   validating ./NS: in validator_callback_dnskey
   validating ./NS: keyset with trust secure
   validating ./NS: resuming validate
   validating ./NS: verify rdataset (keyid=33853): success
   validating ./NS: marking as secure, noqname proof not needed
   validating ftp.isc.org/A: starting
   validating ftp.isc.org/A: attempting positive response validation
   validating isc.org/DNSKEY: starting
   validating isc.org/DNSKEY: attempting positive response validation
     validating isc.org/DS: starting
     validating isc.org/DS: attempting positive response validation
   validating org/DNSKEY: starting
   validating org/DNSKEY: attempting positive response validation
     validating org/DS: starting
     validating org/DS: attempting positive response validation
     validating org/DS: keyset with trust secure
     validating org/DS: verify rdataset (keyid=33853): success
     validating org/DS: marking as secure, noqname proof not needed
   validating org/DNSKEY: in validator_callback_ds
   validating org/DNSKEY: dsset with trust secure
   validating org/DNSKEY: verify rdataset (keyid=9795): success
   validating org/DNSKEY: marking as secure (DS)
     validating isc.org/DS: in fetch_callback_dnskey
     validating isc.org/DS: keyset with trust secure
     validating isc.org/DS: resuming validate
     validating isc.org/DS: verify rdataset (keyid=33209): success
     validating isc.org/DS: marking as secure, noqname proof not needed
   validating isc.org/DNSKEY: in validator_callback_ds
   validating isc.org/DNSKEY: dsset with trust secure
   validating isc.org/DNSKEY: verify rdataset (keyid=7250): success
   validating isc.org/DNSKEY: marking as secure (DS)
   validating ftp.isc.org/A: in fetch_callback_dnskey
   validating ftp.isc.org/A: keyset with trust secure
   validating ftp.isc.org/A: resuming validate
   validating ftp.isc.org/A: verify rdataset (keyid=27566): success
   validating ftp.isc.org/A: marking as secure, noqname proof not needed

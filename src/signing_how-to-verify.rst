.. _how-to-test-authoritative-server:

How To Test Authoritative Zones (So You Think You Are Signed)
=============================================================

So we've activated DNSSEC and uploaded some data to our parent zone. How
do we know our zone is signed correctly? Here are a few ways to check.

.. _signing-verify-key-data:

Look for Key Data in Your Zone
------------------------------

One of the ways to see if your zone is signed, is to check for the
presence of DNSKEY record types. In our example, we created a single
key, and we expect to see it returned when we query for it.

::

   $ dig @192.168.1.13 example.com. DNSKEY +multiline

   ; <<>> DiG 9.16.0 <<>> @10.53.0.6 example.com DNSKEY +multiline
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18637
   ;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
   ;; WARNING: recursion requested but not available

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags:; udp: 4096
   ; COOKIE: efe186423313fb66010000005e8c997e99864f7d69ed7c11 (good)
   ;; QUESTION SECTION:
   ;example.com.       IN DNSKEY

   ;; ANSWER SECTION:
   example.com.        3600 IN DNSKEY 257 3 13 (
                   6saiq99qDBb5b4G4cx13cPjFTrIvUs3NW44SvbbHorHb
                   kXwOzeGAWyPORN+pwEV/LP9+FHAF/JzAJYdqp+o0dw==
                   ) ; KSK; alg = ECDSAP256SHA256 ; key id = 10376
     

.. _signing-verify-signature:

Look for Signatures in Your Zone
--------------------------------

Another way to see if your zone data is signed is to check for the
presence of signature. With DNSSEC, every record [1]_now comes with at
least one corresponding signature known as RRSIG.

::

   $ dig @192.168.1.13 example.com. SOA +dnssec +multiline

   ; <<>> DiG 9.16.0 <<>> @10.53.0.6 example.com SOA +dnssec +multiline
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 45219
   ;; flags: qr aa rd; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1
   ;; WARNING: recursion requested but not available

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags: do; udp: 4096
   ; COOKIE: 75adff4f4ce916b2010000005e8c99c0de47eabb7951b2f5 (good)
   ;; QUESTION SECTION:
   ;example.com.       IN SOA

   ;; ANSWER SECTION:
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

The serial number was automatically incremented from the old, unsigned
version. Named keeps track of the serial number of the signed version of
the zone independently of the unsigned version. If the unsigned zone is
updated with a new serial number that's higher than the one in the
signed copy, then the signed copy will be increased to match it, but
otherwise the two are kept separate.

.. _signing-verify-zone-file:

Examine the Zone File
---------------------

Our original zone file ``example.com.db`` remains untouched, named has
generated 3 additional files automatically for us (shown below). The
signed DNS data is stored in ``example.com.db.signed`` and in the
associated journal file.

::

   # cd /etc/bind
   # ls
   example.com.db  example.com.db.jbk  example.com.db.signed  example.com.db.signed.jnl

A quick description of each of the files:

-  ``.jbk``: transient file used by ``named``

-  ``.signed``: signed version of the zone in raw format

-  ``.signed.jnl``: journal file for the signed version of the zone

These files are stored in raw (binary) format for faster loading. You
could reveal the human-readable version by using ``named-compilezone``
as shown below. In the example below, we are running the command on the
raw format zone ``example.com.db.signed`` to produce a text version of
the zone ``example.com.text``:

::

   # named-compilezone -f raw -F text -o example.com.text example.com example.com.db.signed
   zone example.com/IN: loaded serial 2014112008 (DNSSEC signed)
   dump zone to example.com.text...done
   OK

.. _signing-verify-check-parent:

Check the Parent
----------------

Although this is not strictly related to whether or not the zone is
signed, a critical part of DNSSEC is the trust relationship between the
parent and child. Just because we, the child, have all the correctly
signed records in our zone doesn't mean it can be fully validated by a
validating resolver, unless our parent's data agrees with us. To check
if our upload to the parent is successful, ask the parent name server
for the DS record of our zone, and we should get back the DS record(s)
containing the information we uploaded in
`??? <#signing-easy-start-upload-to-parent-zone>`__:

::

   $ dig example.com. DS

   ; <<>> DiG 9.16.0 <<>> example.com DS
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 16954
   ;; flags: qr rd ra ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags:; udp: 4096
   ; COOKIE: db280d5b52576780010000005e8c9bf5b0d8de103d934e5d (good)
   ;; QUESTION SECTION:
   ;example.com.           IN  DS

   ;; ANSWER SECTION:
   example.com.  61179 IN  DS  10376 13 2 B92E22CAE0B41430EC38D3F7EDF1183C3A94F4D4748569250C15EE33B8312EF0

.. [1]
   Well, almost every record. NS records and glue records for
   delegations do not have RRSIG records like everyone else. If you do
   not have any delegations, then yes, every record in your zone will be
   signed and comes with its own RRSIG.

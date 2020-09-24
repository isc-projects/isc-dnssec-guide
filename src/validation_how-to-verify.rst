.. _how-to-test-recursive-server:

How To Test Recursive Server (So You Think You Are Validating)
==============================================================

Okay, so now that you have reconfigured your recursive server and
restarted it, how do you know that your recursive name server is
actually verifying each DNS query? There are several ways to check, and
we've listed a couple of suggestions below.

.. _using-web-based-tests-to-verify:

Using Web-based Tools to Verify
-------------------------------

For most people, the simplest way to check if the recursive name server
is indeed validating DNS queries, is to use one of the many web-based
tools.

Configure your client computer to use the newly reconfigured recursive
server for DNS resolution, and then you can use any one of these
web-based tests to see if it is in fact validating answers DNS
responses.

-  

-  

Using dig to Verify
-------------------

The web-based tools often employ JavaScript. If you don't trust the
JavaScript magic that the web-based tools rely on, you can take matters
into your own hands and use a command line DNS tool to check your
validating resolver yourself.

While ``nslookup`` is popular, partly because it comes pre-installed on
most systems, it is not DNSSEC-aware. ``dig``, on the other hand, fully
supports the DNSSEC standard and comes as a part of BIND. If you do not
have ``dig`` already installed on your system, install it by downloading
it from ISC's web site. ISC provides pre-compiled Windows versions on
its web site.

``dig`` is a flexible tool for interrogating DNS name servers. It
performs DNS lookups and displays the answers that are returned from the
name server(s) that were queried. Most seasoned DNS administrators use
``dig`` to troubleshoot DNS problems because of its flexibility, ease of
use, and clarity of output.

The example below shows using ``dig`` to query the name server 10.53.0.1
for the A record for ``ftp.isc.org`` when DNSSEC validation is enabled
(i.e. the default.) The address 10.53.0.1 is only used as an example,
you should replace it with the actual address or host name of your
recursive name server.

::

   $ dig @10.53.0.1 ftp.isc.org. A +dnssec +multiline

   ; <<>> DiG 9.16.0 <<>> @10.53.0.1 ftp.isc.org a +dnssec +multiline
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 48742
   ;; flags: qr rd ra ad; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags: do; udp: 4096
   ; COOKIE: 29a9705c2160b08c010000005e67a4a102b9ae079c1b24c8 (good)
   ;; QUESTION SECTION:
   ;ftp.isc.org.       IN A

   ;; ANSWER SECTION:
   ftp.isc.org.        300 IN A 149.20.1.49
   ftp.isc.org.        300 IN RRSIG A 13 3 300 (
                   20200401191851 20200302184340 27566 isc.org.
                   e9Vkb6/6aHMQk/t23Im71ioiDUhB06sncsduoW9+Asl4
                   L3TZtpLvZ5+zudTJC2coI4D/D9AXte1cD6FV6iS6PQ== )

   ;; Query time: 452 msec
   ;; SERVER: 10.53.0.1#53(10.53.0.1)
   ;; WHEN: Tue Mar 10 14:30:57 GMT 2020
   ;; MSG SIZE  rcvd: 187

The important detail in this output is the presence of the ``ad`` flag
in the header. This signifies that BIND has retrieved all related DNSSEC
information related to the target of the query (ftp.isc.org) and that
the answer received has passed the validation process described in
`??? <#how-are-answers-verified>`__. We can have confidence in the
authenticity and integrity of the answer, that ``ftp.isc.org`` really
points to the IP address 149.20.1.49, and it was not a spoofed answer
from a clever attacker.

Unlike earlier versions of BIND, the current versions of BIND always
request DNSSEC records (by setting the ``do`` bit in the query they make
to upstream servers), regardless of DNSSEC settings. However, with
validation disabled, the returned signature is not checked. This can be
seen by explicitly disabling DNSSEC validation. To do this, add the line
``dnssec-validation no;`` to the "options" section of the configuration
file, i.e.

::

   options {
       ...
       dnssec-validation no;
       ...
   };

If the server is re-started (to ensure a clean cache) and the same
``dig`` command executed, the result is very similar:

::

   $ dig @10.53.0.1 ftp.isc.org. A +dnssec +multiline

   ; <<>> DiG 9.16.0 <<>> @10.53.0.1 ftp.isc.org a +dnssec +multiline
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 39050
   ;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags: do; udp: 4096
   ; COOKIE: a8dc9d1b9ec45e75010000005e67a8a69399741fdbe126f2 (good)
   ;; QUESTION SECTION:
   ;ftp.isc.org.       IN A

   ;; ANSWER SECTION:
   ftp.isc.org.        300 IN A 149.20.1.49
   ftp.isc.org.        300 IN RRSIG A 13 3 300 (
                   20200401191851 20200302184340 27566 isc.org.
                   e9Vkb6/6aHMQk/t23Im71ioiDUhB06sncsduoW9+Asl4
                   L3TZtpLvZ5+zudTJC2coI4D/D9AXte1cD6FV6iS6PQ== )

   ;; Query time: 261 msec
   ;; SERVER: 10.53.0.1#53(10.53.0.1)
   ;; WHEN: Tue Mar 10 14:48:06 GMT 2020
   ;; MSG SIZE  rcvd: 187

However this time there is no ``ad`` flag in the header. Although
``dig`` is still returning the DNSSEC-related resource records, it is
not checking them, so cannot vouch for the authenticity of the answer.
If you do carry out this test, remember to re-enable DNSSEC validation
(by removing the ``dnssec-validation no;`` line from the configuration
file) before continuing.

Verifying Protection from Bad Domain Names
------------------------------------------

It is also important to make sure that DNSSEC is protecting you from
domain names that fail to validate; such failures could be caused by
attacks on your system, attempting to get it to accept false DNS
information. Validation could fail for a number of reasons, maybe the
answer doesn't verify because it's a spoofed response; maybe the
signature was a replayed network attack that has expired; or maybe the
child zone has been compromised along with its keys, and the parent
zone's information is telling us that things don't add up. There is a
domain name specifically setup to purposely fail DNSSEC validation,
``www.dnssec-failed.org``.

With DNSSEC validation enabled (the default), an attempt to look up the
name will fail:

::

   $ dig @10.53.0.1 www.dnssec-failed.org. A

   ; <<>> DiG 9.16.0 <<>> @10.53.0.1 www.dnssec-failed.org. A
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 22667
   ;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags:; udp: 4096
   ; COOKIE: 69c3083144854587010000005e67bb57f5f90ff2688e455d (good)
   ;; QUESTION SECTION:
   ;www.dnssec-failed.org.     IN  A

   ;; Query time: 2763 msec
   ;; SERVER: 10.53.0.1#53(10.53.0.1)
   ;; WHEN: Tue Mar 10 16:07:51 GMT 2020
   ;; MSG SIZE  rcvd: 78

On the other hand, if DNSSEC validation is disabled (by adding the
statement ``dnssec-validation no;`` to the ``options`` clause in the
configuration file), the lookup succeeds:

::

   $ dig @10.53.0.1 www.dnssec-failed.org. A

   ; <<>> DiG 9.16.0 <<>> @10.53.0.1 www.dnssec-failed.org. A
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 54704
   ;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags:; udp: 4096
   ; COOKIE: 251eee58208917f9010000005e67bb6829f6dabc5ae6b7b9 (good)
   ;; QUESTION SECTION:
   ;www.dnssec-failed.org.     IN  A

   ;; ANSWER SECTION:
   www.dnssec-failed.org.  7200    IN  A   68.87.109.242
   www.dnssec-failed.org.  7200    IN  A   69.252.193.191

   ;; Query time: 439 msec
   ;; SERVER: 10.53.0.1#53(10.53.0.1)
   ;; WHEN: Tue Mar 10 16:08:08 GMT 2020
   ;; MSG SIZE  rcvd: 110

Do not be tempted to disable DNSSEC validation just because some names
are failing to resolve. Remember, DNSSEC protects your DNS lookup from
hacking. The next section describes how you can quickly check whether
the failure to successfully look up a name is due to a validation
failure.

How Do I know I Have a Validation Problem?
------------------------------------------

Since all DNSSEC validation failures result in a general ``SERVFAIL``
message, how do we know that it was related to validation in the first
place? Fortunately, there is a flag in ``dig``, (``+cd``, checking
disabled) which tells the server to disable DNSSEC validation. When
you've received a ``SERVFAIL`` message, re-run the query one more time,
and throw in the ``+cd`` flag. If the query succeeds with ``+cd``, but
ends in ``SERVFAIL`` without it, then you know you are dealing with a
validation problem. So using the previous example of
``www.dnssec-failed.org`` and with DNSSEC validation enabled in the
resolver:

::

   $ dig @10.53.0.1 www.dnssec-failed.org A +cd

   ; <<>> DiG 9.16.0 <<>> @10.53.0.1 www.dnssec-failed.org. A +cd
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62313
   ;; flags: qr rd ra cd; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags:; udp: 4096
   ; COOKIE: 73ca1be3a74dd2cf010000005e67c8c8e6df64b519cd87fd (good)
   ;; QUESTION SECTION:
   ;www.dnssec-failed.org.     IN  A

   ;; ANSWER SECTION:
   www.dnssec-failed.org.  7197    IN  A   68.87.109.242
   www.dnssec-failed.org.  7197    IN  A   69.252.193.191

   ;; Query time: 0 msec
   ;; SERVER: 10.53.0.1#53(10.53.0.1)
   ;; WHEN: Tue Mar 10 17:05:12 GMT 2020
   ;; MSG SIZE  rcvd: 110

For more information on troubleshooting, please see
`??? <#dnssec-troubleshooting>`__.

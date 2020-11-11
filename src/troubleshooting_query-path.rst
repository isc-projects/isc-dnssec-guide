.. _troubleshooting-query-path:

Query Path
==========

The first step to your DNS or DNSSEC troubleshooting should be to
determine the query path. This is not a DNSSEC-specific troubleshooting
technique. Whenever you are working with a DNS-related issue, it is
always a good idea to determine the exact query path to identify the
origin of the problem.

End clients, such as laptop computers or mobile phones, are configured
to talk to a recursive name server, and the recursive name server may in
turn forward on to more recursive name servers, before arriving at the
authoritative name server. The giveaway is the presence of the
Authoritative Answer (``aa``) flag: when present, we know we are talking
to the authoritative server; when missing, we are talking to a recursive
server. The example below shows an answer to a query for
``www.example.com`` without the Authoritative Answer flag:

::

   $ dig @10.53.0.3 www.example.com A

   ; <<>> DiG 9.16.0 <<>> @10.53.0.3 www.example.com a
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62714
   ;; flags: qr rd ra ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags:; udp: 4096
   ; COOKIE: c823fe302625db5b010000005e722b504d81bb01c2227259 (good)
   ;; QUESTION SECTION:
   ;www.example.com.       IN  A

   ;; ANSWER SECTION:
   www.example.com.    60  IN  A   10.1.0.1

   ;; Query time: 3 msec
   ;; SERVER: 10.53.0.3#53(10.53.0.3)
   ;; WHEN: Wed Mar 18 14:08:16 GMT 2020
   ;; MSG SIZE  rcvd: 88

Not only do we not see the ``aa`` flag, we see the presence of an ``ra``
flag, which represents Recursion Available. This indicates that the
server we are talking to (10.53.0.3 in this example) is a recursive name
server. And although we were able to get an answer for
``www.example.com``, the answer came from somewhere else.

If we query the authoritative server directly, we get:

::

   $ dig @10.53.0.2 www.example.com A

   ; <<>> DiG 9.16.0 <<>> @10.53.0.2 www.example.com a
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 39542
   ;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
   ;; WARNING: recursion requested but not available
   ...

The presence of the ``aa`` flag tells us that we are now talking to the
authoritative name server for ``www.example.com``, and this is not a
cached answer it obtained from some other name server, it served this
answer to us right from its own database. In fact, if you look closely,
the Recursion Available (``ra``) flag is not present, which means this
name server is not configured to perform recursion (at least not for
this client), so it could not have queried another name server to get
cached results anyway.

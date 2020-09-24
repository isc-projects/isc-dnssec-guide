.. _troubleshooting-visible-symptoms:

Visible Symptoms
================

After you have figured out the query path, the next thing to do is to
determine whether or not the problem is actually related to DNSSEC
validation. You can use the ``+cd`` flag in ``dig`` to disable
validation, as described in
`??? <#how-do-i-know-i-have-a-validation-problem>`__.

When there is indeed a DNSSEC validation problem, the visible symptoms,
unfortunately, are very limited. With DNSSEC validation enabled, if a
DNS response is not fully validated, it will result in a generic
SERVFAIL message, as shown below when querying against a recursive name
server 192.168.1.7:

::

   $ dig @10.53.0.3 www.example.org. A

   ; <<>> DiG 9.16.0 <<>> @10.53.0.3 www.example.org A
   ; (1 server found)
   ;; global options: +cmd
   ;; Got answer:
   ;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 28947
   ;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1

   ;; OPT PSEUDOSECTION:
   ; EDNS: version: 0, flags:; udp: 4096
   ; COOKIE: d1301968aca086ad010000005e723a7113603c01916d136b (good)
   ;; QUESTION SECTION:
   ;www.example.org.       IN  A

   ;; Query time: 3 msec
   ;; SERVER: 10.53.0.3#53(10.53.0.3)
   ;; WHEN: Wed Mar 18 15:12:49 GMT 2020
   ;; MSG SIZE  rcvd: 72

With ``delv``, a "resolution failed" message is output instead:

::

   $ delv @10.53.0.3 www.example.org. A +rtrace
   ;; fetch: www.example.org/A
   ;; resolution failed: SERVFAIL

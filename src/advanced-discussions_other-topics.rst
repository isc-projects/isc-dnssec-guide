Other Topics
============

DNSSEC and Dynamic Updates
--------------------------

Dynamic DNS (DDNS) actually is independent of DNSSEC. DDNS provides a
mechanism other than editing the zone file or zone database, to edit DNS
data. Most clients and DNS servers have the capability to handle dynamic
updates, and DDNS can also be integrated as part of your DHCP
environment.

When you have both DNSSEC and dynamic updates in your environment,
updating zone data works the same way as with traditional (insecure)
DNS: you can use ``rndc freeze`` before editing the zone file, and
``rndc thaw`` when you have finished editing, or you could use the
command ``nsupdate`` to add, edit, or remove records like this:

::

   $ nsupdate
   > server 192.168.1.13
   > update add xyz.example.com. 300 IN A 1.1.1.1
   > send
   > quit

The examples provided in this guide will make ``named`` automatically
re-sign the zone whenever its content has changed. If you decide to sign
your own zone file manually, you will need to remember to executed the
``dnssec-signzone`` whenever your zone file has been updated.

As far as system resources and performance is concerned, be mindful that
when you have a DNSSEC zone that changes frequently, every time the zone
changes, your system is executing a series of cryptographic operations
to (re)generate signatures and NSEC or NSEC3 records.

DNSSEC on Private Networks
--------------------------

Before we discuss DNSSEC on private networks, let's clarify what we mean
by private networks. In this section, private networks really refers to
a private or internal DNS view. Most DNS products offer the ability to
have different version of DNS answers, depending on the origin of the
query. This feature is often called DNS views or split DNS, and is most
commonly implemented as an "internal" versus an "external" setup.

For instance, your organization may have a version of ``example.com``
that is offered to the world, and its names most likely resolves to
publicly reachable IP addresses. You may also have an internal version
of ``example.com`` that is only accessible when you are on the company's
private networks or via a VPN connection. These private networks typical
fall under 10.0.0.0/8, 172.16.0.0.0/12, or 192.168.0.0.0/16 for IPv4.

So what if you want to offer DNSSEC for your internal version of
``example.com``? This can be done: the golden rule is to use the same
key for both the internal and external versions of the zones. This will
get rid of problems that will occur when machines (e.g. laptops) move
between accessing the internal and external zones (when it is possible
that that may have cached records from the wrong zone).

Introduction to DANE
--------------------

With your DNS infrastructure now secured with DNSSEC, information can
now be stored in DNS and its integrity and authenticity can be proved.
One of the new features that takes advantage of this is the DNS-Based
Authentication of Named Entities, or DANE. This improves security in a
number of ways, e.g.

-  Store self-signed X.509 certificates, bypass having to pay a third
   party (such as a Certificate Authority) to sign the certificates
   (`RFC 6698 <https://tools.ietf.org/html/rfc6698>`__).

-  Improved security for clients connecting to mail servers (`RFC
   7672 <https://tools.ietf.org/html/rfc7672>`__).

-  As a secure way of getting public PGP keys (`RFC
   7929 <https://tools.ietf.org/html/rfc7929>`__).

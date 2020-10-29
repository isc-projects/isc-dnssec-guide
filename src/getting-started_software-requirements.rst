Software Requirement
====================

BIND Version
------------

Most configuration examples given in this document require BIND version
9.16.0 or newer (although many should work with all versions of BIND
later than 9.9). To check the version of ``named`` you have installed,
use the ``-v`` switch as shown below:

::

   # named -v
   BIND 9.16.0 (Stable Release) <id:6270e602ea>

Some configuration examples are added in BIND version 9.17 and backported
to 9.16. For example, NSEC3 configuration requires BIND version 9.16.9.

It is recommended to run the latest stable version to get the most rich
DNSSEC configuration, as well as the latest security fixes.


DNSSEC Support in BIND
----------------------

All versions of BIND 9 since BIND 9.7 can support DNSSEC as currently
deployed in the global DNS. The BIND software you are running most
likely already supports DNSSEC as shipped. Run the command ``named -V``
to see what flags it was built with. If it was built with OpenSSL
(``--with-openssl``), then it supports DNSSEC. Below is an example
screenshot of running ``named
  -V``:

::

   $ named -V
   BIND 9.16.0 (Stable Release) <id:6270e602ea>
   running on Linux x86_64 4.9.0-9-amd64 #1 SMP Debian 4.9.168-1+deb9u4 (2019-07-19)
   built by make with defaults
   compiled by GCC 6.3.0 20170516
   compiled with OpenSSL version: OpenSSL 1.1.0l  10 Sep 2019
   linked to OpenSSL version: OpenSSL 1.1.0l  10 Sep 2019
   compiled with libxml2 version: 2.9.4
   linked to libxml2 version: 20904
   compiled with json-c version: 0.12.1
   linked to json-c version: 0.12.1
   compiled with zlib version: 1.2.8
   linked to zlib version: 1.2.8
   threads support is enabled

   default paths:
     named configuration:  /usr/local/etc/named.conf
     rndc configuration:   /usr/local/etc/rndc.conf
     DNSSEC root key:      /usr/local/etc/bind.keys
     nsupdate session key: /usr/local/var/run/named/session.key
     named PID file:       /usr/local/var/run/named/named.pid
     named lock file:      /usr/local/var/run/named/named.lock

If the BIND 9 software you have does not support DNSSEC, you should
upgrade it. (It has not been possible to build BIND without DNSSEC
support since BIND 9.13, released in 2018.) As well as missing out on
DNSSEC support, you are also missing out on a number of security fixes
made to the software in recent years.

System Entropy
--------------

If you plan on deploying DNSSEC to your authoritative server, you will
need to generate cryptographic keys. The amount of time it takes to
generate the keys depends on the source of randomness, or entropy, on
your systems. On some systems (especially virtual machines) with
insufficient entropy, it may take much longer than one cares to wait to
generate keys.

There are software packages, such as ``haveged`` for Linux, that
provides additional entropy for your system. Once installed, they will
significantly reduce the time needed to generate keys.

The more entropy there is, the better pseudo-random numbers you get, and
stronger keys are generated. If you want or need high quality random
numbers, take a look at `??? <#hardware-security-modules>`__ for some of
the hardware-based solutions.

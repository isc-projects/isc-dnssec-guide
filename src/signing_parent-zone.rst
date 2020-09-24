.. _working-with-parent-zone:

Working with the Parent Zone
============================

As we mentioned in `??? <#signing-easy-start-upload-to-parent-zone>`__,
the format of the information you upload to your parent zone is dictated
by your parent zone administrator, and the two main formats are:

1. DS Record Format

2. DNSKEY Format

You should check with your parent zone which format they require.

Next, we will take a look at how to get each of the formats from your
existing data.

First though, what existing data? When ``named`` turned on automatic
DNSSEC maintenance, more or less the first thing it did was to create
the DNSSEC keys and put them in the directory you specified in the
configuration file. If you look in that directory, you will see three
files with names like ``Kexample.com.+013+10376.key``,
``Kexample.com.+013+10376.private`` and
``Kexample.com.+013+10376.state``. The one we are interested in is the
one with the ``.key`` suffix, which contains the zone's public key. (The
other files contain the zone's private key and the DNSSEC state
associated with the key.) This is used to generate the information we
need to pass to the parent.

.. _parent-ds-record-format:

DS Record Format
----------------

Below is an example of generating a DS record formats from the KSK we
created earlier (``Kexample.com.+013+10376.key``):

::

   # cd /etc/bind
    dnssec-dsfromkey Kexample.com.+013+10376.key
   example.com. IN DS 10376 13 2 B92E22CAE0B41430EC38D3F7EDF1183C3A94F4D4748569250C15EE33B8312EF0

Some registrars many ask you to manually specify the types of algorithm
and digest used. In this example, 13 represents the algorithm used, and
2 represents the digest type (SHA-256). The key tag or key ID is 10376.

.. _parent-dnskey-format:

DNSKEY Format
-------------

Below is an example of the same key ID (10376) using DNSKEY format
(actual key shortened for display):

::

   example.com. 3600 IN DNSKEY 257 3 13 (6saiq99qDB...dqp+o0dw==) ; key id = 10376

The key itself is easy to find (it's kind of hard to miss that big long
base64 string) in the file (shortened for display).

::

   # cd /etc/bind
   # cat Kexample.com.+013+10376.key
   ; This is a key-signing key, keyid 10376, for example.com.
   ; Created: 20200407150255 (Tue Apr  7 16:02:55 2020)
   ; Publish: 20200407150255 (Tue Apr  7 16:02:55 2020)
   ; Activate: 20200407150255 (Tue Apr  7 16:02:55 2020)
   example.com. 3600 IN DNSKEY 257 3 13 6saiq99qDB...dqp+o0dw==

Trust Anchors
=============

A trust anchor is a key that is placed into a validating resolver so
that the validator can verify the results for a given request back to a
known or trusted public key (the trust anchor). A validating resolver
must have at least one trust anchor installed in order to perform DNSSEC
validation.

How Trust Anchors are Used
--------------------------

In the section `??? <#how-does-dnssec-change-dns-lookup-revisited>`__,
we walked through the DNSSEC lookup process (12 steps), and at the end
of the 12 steps, a critical comparison happens: the key received from
the remote server, and the key we have on file are compared to see if we
trust it. The key we have on file is called a trust anchor, sometimes
also known as a trust key, trust point, or secure entry point.

The 12-step lookup process describes the DNSSEC lookup in the ideal
world where every single domain name is signed and properly delegated,
each validating resolver only needs to have one trust anchor, and that
is the root's public key. But there is no restriction that the
validating resolver must only have one trust anchor. In fact, in the
early stages of DNSSEC adoption, it was not unusual for a validating
resolver to have more than one trust anchor.

For instance, before the root zone was signed (July 2010), some
validating resolvers that wish to validate domain names in the ``.gov``
zone needed to obtain and install the key for ``.gov``. A sample lookup
process for ``www.fbi.gov`` would thus be only 8 steps rather than 12
steps that look like this:

1. The validating resolver queries ``fbi.gov`` name server for the A
   record of ``www.fbi.gov``.

2. The FBI's name server responds with the answer and its RRSIG.

3. The validating resolver queries FBI's name server for its DNSKEY.

4. The FBI's name server responds with the DNSKEY and its RRSIG.

5. The validating resolver queries a ``.gov`` name server for the DS
   record of ``fbi.gov``.

6. The ``.gov`` name server responds with the DS record and the
   associated RRSIG for ``fbi.gov``.

7. The validating resolver queries ``.gov`` name server for its DNSKEY.

8. The ``.gov`` name server responds with its DNSKEY and the associated
   RRSIG.

This all looks very similar, except it's shorter than the 12-steps that
we saw earlier. Once the validating resolver receives the DNSKEY file in
#8, it recognizes that this is the manually configured trusted key
(trust anchor), and never goes to the root name servers to ask for the
DS record for ``.gov``, or ask the root name servers for its DNSKEY.

In fact, whenever the validating resolver receives a DNSKEY, it checks
to see if this is a configured trusted key, to decide whether or not it
needs to continue chasing down the validation chain.

Trusted Keys and Managed Keys
-----------------------------

So, as the resolver is validating, we must have at least one key (trust
anchor) configured. How did it get here, and how do we maintain it?

If you followed the recommendation in
`??? <#easy-start-guide-for-recursive-servers>`__, by setting
``dnssec-validation`` to <auto>, then there is nothing you need to do.
BIND already includes a copy of the root key (in the file
``bind.keys``), and will automatically update it when the root key
changes. [1]_ It looks something like this:

::

   trust-anchors {
           # This key (20326) was published in the root zone in 2017.
           . initial-key 257 3 8 "AwEAAaz/tAm8yTn4Mfeh5eyI96WSVexTBAvkMgJzkKTOiW1vkIbzxeF3
                   +/4RgWOq7HrxRixHlFlExOLAJr5emLvN7SWXgnLh4+B5xQlNVz8Og8kv
                   ArMtNROxVQuCaSnIDdD5LKyWbRd2n9WGe2R8PzgCmr3EgVLrjyBxWezF
                   0jLHwVN8efS3rCj/EWgvIWgb9tarpVUDK/b58Da+sqqls3eNbuv7pr+e
                   oZG+SrDK6nWeL3c6H5Apxz7LjVc1uTIdsIXxuOLYA4/ilBmSVIzuDWfd
                   RUfhHdY6+cn8HFRm+2hM8AnXGXws9555KrUB5qihylGa8subX2Nn6UwN
                   R1AkUTV74bU=";
   };

You could, of course, decide to manage this key on your own by hand.
First, you'll need to make sure that your ``dnssec-validation`` is set
to <yes> rather than <auto>:

::

   options {
       dnssec-validation yes;
   };

Then, download the root key manually from a trustworthy source, such as
` <https://www.isc.org/bind-keys>`__. Finally, take the root key you
manually downloaded, and put it into a ``trust-anchors`` statement as
shown below:

::

   trust-anchors {
           # This key (20326) was published in the root zone in 2017.
           . static-key 257 3 8 "AwEAAaz/tAm8yTn4Mfeh5eyI96WSVexTBAvkMgJzkKTOiW1vkIbzxeF3
                   +/4RgWOq7HrxRixHlFlExOLAJr5emLvN7SWXgnLh4+B5xQlNVz8Og8kv
                   ArMtNROxVQuCaSnIDdD5LKyWbRd2n9WGe2R8PzgCmr3EgVLrjyBxWezF
                   0jLHwVN8efS3rCj/EWgvIWgb9tarpVUDK/b58Da+sqqls3eNbuv7pr+e
                   oZG+SrDK6nWeL3c6H5Apxz7LjVc1uTIdsIXxuOLYA4/ilBmSVIzuDWfd
                   RUfhHdY6+cn8HFRm+2hM8AnXGXws9555KrUB5qihylGa8subX2Nn6UwN
                   R1AkUTV74bU=";
   };

While this ``trust-anchors`` statement and the one in the ``bind.keys``
file appear similar, the definition of the key in ``bind.keys`` has the
``initial-key`` modifier, whereas in the statement in the configuration
file, that is replaced by ``static-key``. There is an important
difference between the two: a key defined with ``static-key`` is always
trusted until it is deleted from the configuration file. With the
``initial-key`` modified, keys are only trusted once: for as long as it
takes to load the managed key database and start the key maintenance
process. Thereafter BIND will use the managed keys database
(``managed-keys.bind.jnl``) as the source of key information.

.. warning::

   Remember, if you choose to manage the keys on your own, whenever the
   key changes (which, for most zones, will happen on a periodic basis),
   the configuration needs to be updated manually. Failing to do so will
   result in breaking nearly all DNS queries for the sub domain of the
   key. So if you are manually managing ``.gov``, all domain names in
   the ``.gov`` space may become unresolvable; if you are manually
   managing the root key, you could break all DNS requests made to your
   recursive name server.

Explicit management of keys was common in the early days of DNSSEC, when
neither the root zone nor many top-level domains were signed. Since
then, `over 90% <https://stats.research.icann.org/dns/tld_report/>`__ of
the top-level domains have been signed, including all the largest ones.
Unless you have a particular need to manage keys yourself, it is best to
use the BIND defaults and let it manage the root key.

.. [1]
   The root zone was signed in July 2010 and, as at the time of writing,
   the key has been changed once, in October 2018. The intention going
   forwards is to roll the key once every five years.

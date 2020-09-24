.. _recipes-nsec3:

NSEC and NSEC3 Recipes
======================

.. _recipes-nsec-to-nsec3:

Migrating from NSEC to NSEC3
----------------------------

This recipe describes how to go from using NSEC to NSEC3, as described
in `??? <#advanced-discussions-proof-of-nonexistence>`__. This recipe
assumes that the zones are already signed, and ``named`` is configured
according to the steps described in
`??? <#easy-start-guide-for-authoritative-servers>`__.

.. warning::

   If your zone is signed with RSASHA1 (algorithm 5) you cannot migrate
   to NSEC3 without also performing an
   algorithm rollover
   to RSASHA1-NSEC3-SHA1 (algorithm 7) as described in
   . This ensures that older validating resolvers that don't understand
   NSEC3 will fallback to treating the zone as unsecured (rather than
   "bogus") as described in
   Section 2 of RFC 5155
   .

This command below enables NSEC3 for the zone ``example.com``, using a
pseudo-random string 1234567890abcdef for its salt:

::

   # rndc signing -nsec3param 1 0 10 1234567890abcdef example.com

You'll know it worked if you see the following log messages:

::

   Oct 21 13:47:21 received control channel command 'signing -nsec3param 1 0 10 1234567890abcdef example.com'
   Oct 21 13:47:21 zone example.com/IN (signed): zone_addnsec3chain(1,CREATE,10,1234567890ABCDEF)

You can also verify that this worked by querying for a name you know
that does not exist, and check for the presence of the NSEC3 record,
such as this:

::

   $ dig @192.168.1.13 thereisnowaythisexists.example.com. A +dnssec +multiline

   ...
   TOM10UQBL336NFAQB3P6MOO53LSVG8UI.example.com. 300 IN NSEC3 1 0 10 1234567890ABCDEF (
                   TQ9QBEGA6CROHEOC8KIH1A2C06IVQ5ER
                   NS SOA RRSIG DNSKEY NSEC3PARAM )
   ...

Our example used four parameters: 1, 0, 10, and 1234567890ABCDEF, in the
order they appeared. 1 represents the algorithm, 0 represents the
opt-out flag, 10 represents the number of iterations, and
1234567890abcedf is the salt. To learn more about each of these
parameters, please see `??? <#advanced-discussions-nsec3param>`__.

For example, to create an NSEC3 chain using the SHA-1 hash algorithm, no
opt-out flag, 10 iterations, and a salt value of "FFFF", use:

::

   # rndc signing -nsec3param 1 0 10 FFFF example.com

To set the opt-out flag, 15 iterations, and no salt, use:

::

   # rndc signing -nsec3param 1 1 15 - example.com

.. _recipes-nsec3-to-nsec:

Migrating from NSEC3 to NSEC
----------------------------

This recipe describes how to migrate from NSEC3 to NSEC.

Migrating from NSEC3 back to NSEC is easy, just use the ``rndc`` command
like this:

::

   $ rndc signing -nsec3param none example.com

You know that it worked if you see these messages in log:

::

   named[14093]: received control channel command 'signing -nsec3param none example.com'
   named[14093]: zone example.com/IN: zone_addnsec3chain(1,REMOVE,10,1234567890ABCDEF)

Of course, you can query for a name that you know that does not exist,
and you should no longer see any traces of NSEC3 records.

::

   $ dig @192.168.1.13 reieiergiuhewhiouwe.example.com. A +dnssec +multiline

   ...
   example.com.        300 IN NSEC aaa.example.com. NS SOA RRSIG NSEC DNSKEY
   ...
   ns1.example.com.    300 IN NSEC web.example.com. A RRSIG NSEC
   ...

.. _recipes-nsec3-salt:

Changing NSEC3 Salt Recipe
--------------------------

In `??? <#advanced-discussions-nsec3-salt>`__, we've discussed the
reasons why you may want to change your salt once in a while for better
privacy. In this recipe, we will look at what command to execute to
actually change the salt, and how to verify that it has been changed.

To change your NSEC3 salt to "fedcba0987654321", you may run the
``rndc signing`` command like this:

::

   # rndc signing -nsec3param 1 1 10 fedcba0987654321 example.com

You should see the following messages in log, assuming your old salt was
"1234567890abcdef":

::

   named[15848]: zone example.com/IN: zone_addnsec3chain(1,REMOVE,10,1234567890ABCDEF)
   named[15848]: zone example.com/IN: zone_addnsec3chain(1,CREATE|OPTOUT,10,FEDCBA0987654321)

You can of course, try to query the name server (192.168.1.13 in our
example) for a name that does not exist, and check the NSEC3 record
returned:

::

   $ dig @192.168.1.13 thereisnowaythisexists.example.com. A +dnssec +multiline

   ...
   TOM10UQBL336NFAQB3P6MOO53LSVG8UI.example.com. 300 IN NSEC3 1 0 10 FEDCBA0987654321 (
                   TQ9QBEGA6CROHEOC8KIH1A2C06IVQ5ER
                   NS SOA RRSIG DNSKEY NSEC3PARAM )
   ...

.. note::

   You can use a pseudo-random source to create the salt for you. Here
   is an example on Linux to create a 16-character hex string:

   ::

      # rndc signing -nsec3param 1 0 10 $(head -c 300 /dev/random | sha1sum | cut -b 1-16) example.com

BIND 9.10 and newer provides the keyword “auto” which may be used in
place of the salt field for ``named`` to generate a random salt.

.. _recipes-nsec3-optout:

NSEC3 Optout Recipe
-------------------

This recipe discusses how to enable and disable NSEC3 opt-out, and show
the results of each action. As discussed in
`??? <#advanced-discussions-nsec3-optout>`__, NSEC3 opt-out is a feature
that can help conserve resources on parent zones that have many
delegations that have yet been signed.

Before starting, for this recipe we will assume the zone ``example.com``
has the following 4 entries (for this example, it is not relevant what
record types these entries are):

-  ns1.example.com

-  ftp.example.com

-  www.example.com

-  web.example.com

And the zone example.com has 5 delegations to 5 sub domains, only one of
which is signed and has a valid DS RRset:

-  aaa.example.com, not signed

-  bbb.example.com, signed

-  ccc.example.com, not signed

-  ddd.example.com, not signed

-  eee.example.com, not signed

Before enabling NSEC3 opt-out, the zone ``example.com`` contains ten
NSEC3 records, below is the list with plain text name before the actual
NSEC3 record:

-  *aaa.example.com*: 9NE0VJGTRTMJOS171EC3EDL6I6GT4P1Q.example.com.

-  *bbb.example.com*: AESO0NT3N44OOSDQS3PSL0HACHUE1O0U.example.com.

-  *ccc.example.com*: SF3J3VR29LDDO3ONT1PM6HAPHV372F37.example.com.

-  *ddd.example.com*: TQ9QBEGA6CROHEOC8KIH1A2C06IVQ5ER.example.com.

-  *eee.example.com*: L16L08NEH48IFQIEIPS1HNRMQ523MJ8G.example.com.

-  *ftp.example.com*: JKMAVHL8V7EMCL8JHIEN8KBOAB0MGUK2.example.com.

-  *ns1.example.com*: FSK5TK9964BNE7BPHN0QMMD68IUDKT8I.example.com.

-  *web.example.com*: D65CIIG0GTRKQ26Q774DVMRCNHQO6F81.example.com.

-  *www.example.com*: NTQ0CQEJHM0S17POMCUSLG5IOQQEDTBJ.example.com.

-  *example.com*: TOM10UQBL336NFAQB3P6MOO53LSVG8UI.example.com.

We can enable NSEC3 opt-out with this command, changing the opt-out bit
(the second parameter of the 4) from 0 to 1 (see
`??? <#advanced-discussions-nsec3param>`__ to review what each parameter
is):

::

   # rndc signing -nsec3param 1 1 10 1234567890abcdef example.com

After NSEC3 opt-out is enabled, the number of NSEC3 records is reduced.
Notice that the unsigned delegations ``aaa``, ``ccc``, ``ddd``, and
``eee`` now don't have corresponding NSEC3 records.

-  *bbb.example.com*: AESO0NT3N44OOSDQS3PSL0HACHUE1O0U.example.com.

-  *ftp.example.com*: JKMAVHL8V7EMCL8JHIEN8KBOAB0MGUK2.example.com.

-  *ns1.example.com*: FSK5TK9964BNE7BPHN0QMMD68IUDKT8I.example.com.

-  *web.example.com*: D65CIIG0GTRKQ26Q774DVMRCNHQO6F81.example.com.

-  *www.example.com*: NTQ0CQEJHM0S17POMCUSLG5IOQQEDTBJ.example.com.

-  *example.com*: TOM10UQBL336NFAQB3P6MOO53LSVG8UI.example.com.

To undo NSEC3 opt-out, run the same ``rndc`` command with the opt-out
bit set to 0:

::

   # rndc signing -nsec3param 1 0 10 1234567890abcdef example.com

.. note::

   NSEC3 hashes the plain text domain name, and we can compute our own
   hashes using the tool ``nsec3hash``. For example, to compute the
   hashed name for "www.example.com" using the parameters we listed
   above, we would execute the command like this:

   ::

      # nsec3hash 1234567890ABCDEF 1 10 www.example.com.
      NTQ0CQEJHM0S17POMCUSLG5IOQQEDTBJ (salt=1234567890ABCDEF, hash=1, iterations=10)

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

To enable NSEC3, update your ``dnssec-policy`` and add the desired NSEC3
parameters. The example below enables NSEC3 for zones with the ``standard``
DNSSEC policy, using 10 iterations, no opt-out, and a random string that is
16 characters long:

::

    dnssec-policy "standard" {
        nsec3param iterations optout no salt-length 16;
    };

Then reconfigure the server with ``rndc``. You can tell that it worked if you
see the following debug log messages:

::

   Oct 21 13:47:21 received control channel command 'reconfig'
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
1234567890ABCDEF is the salt. To learn more about each of these
parameters, please see `??? <#advanced-discussions-nsec3param>`__.

.. _recipes-nsec3-to-nsec:

Migrating from NSEC3 to NSEC
----------------------------

This recipe describes how to migrate from NSEC3 to NSEC.

Migrating from NSEC3 back to NSEC is easy; just remove the ``nsec3param``
configuration option from your ``dnssec-policy`` and reconfigure the name
server. You can tell that it worked if you see these messages in the log:

::

   named[14093]: received control channel command 'reconfig'
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

The ``dnssec-policy`` currently has no easy way to re-salt using the
same salt length, so to change your NSEC3 salt you have to change the
``salt-length`` value, then reconfigure your server. You should see
the following messages in the log, assuming your old salt was
"1234567890ABCDEF" and ``named`` created "FEDCBA09" (salt length 8)
as the new salt:

::

   named[15848]: zone example.com/IN: zone_addnsec3chain(1,REMOVE,10,1234567890ABCDEF)
   named[15848]: zone example.com/IN: zone_addnsec3chain(1,CREATE|OPTOUT,10,FEDCBA09)

You can of course, try to query the name server (192.168.1.13 in our
example) for a name that does not exist, and check the NSEC3 record
returned:

::

   $ dig @192.168.1.13 thereisnowaythisexists.example.com. A +dnssec +multiline

   ...
   TOM10UQBL336NFAQB3P6MOO53LSVG8UI.example.com. 300 IN NSEC3 1 0 10 FEDCBA09 (
                   TQ9QBEGA6CROHEOC8KIH1A2C06IVQ5ER
                   NS SOA RRSIG DNSKEY NSEC3PARAM )
   ...

If you want to use the same salt length, you can repeat the above steps and
go back to your original length value.

.. _recipes-nsec3-optout:

NSEC3 Optout Recipe
-------------------

This recipe discusses how to enable and disable NSEC3 opt-out, and show
the results of each action. As discussed in
`??? <#advanced-discussions-nsec3-optout>`__, NSEC3 opt-out is a feature
that can help conserve resources on parent zones that have many
delegations that have yet been signed.

Because the NSEC3PARAM record does not keep track of whether opt-out is used,
it is hard to check if changes need to be made to the NSEC3 chain if the flag
is changed. Similar to changing the NSEC3 salt, your best way is to change
the value of ``optout`` together with another NSEC3 parameter, for example
``iterations`` and in a following step restore the ``iterations`` value.

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

We can enable NSEC3 opt-out with the following configuration, changing the
the ``optout`` configuration value from ``no`` to ``yes``:

::

   dnssec-policy "standard" {
       nsec3param iterations 10 optout yes salt-length 16;
   };

After NSEC3 opt-out is enabled, the number of NSEC3 records is reduced.
Notice that the unsigned delegations ``aaa``, ``ccc``, ``ddd``, and
``eee`` now don't have corresponding NSEC3 records.

-  *bbb.example.com*: AESO0NT3N44OOSDQS3PSL0HACHUE1O0U.example.com.

-  *ftp.example.com*: JKMAVHL8V7EMCL8JHIEN8KBOAB0MGUK2.example.com.

-  *ns1.example.com*: FSK5TK9964BNE7BPHN0QMMD68IUDKT8I.example.com.

-  *web.example.com*: D65CIIG0GTRKQ26Q774DVMRCNHQO6F81.example.com.

-  *www.example.com*: NTQ0CQEJHM0S17POMCUSLG5IOQQEDTBJ.example.com.

-  *example.com*: TOM10UQBL336NFAQB3P6MOO53LSVG8UI.example.com.

To undo NSEC3 opt-out, change the configuration again:

::

   dnssec-policy "standard" {
       nsec3param iterations 10 optout no salt-length 16;
   };

.. note::

   NSEC3 hashes the plain text domain name, and we can compute our own
   hashes using the tool ``nsec3hash``. For example, to compute the
   hashed name for "www.example.com" using the parameters we listed
   above, we would execute the command like this:

   ::

      # nsec3hash 1234567890ABCDEF 1 10 www.example.com.
      NTQ0CQEJHM0S17POMCUSLG5IOQQEDTBJ (salt=1234567890ABCDEF, hash=1, iterations=10)

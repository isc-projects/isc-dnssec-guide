.. _signing-custom-policy:

Creating a Custom DNSSEC Policy
===============================

The remainder of this section describes the contents of a custom DNSSEC
policy. `??? <#dnssec-advanced-discussions>`__ describes the concepts
involved here and the pros and cons of choosing particular values. If
you are not familiar with DNSSEC, it may be worth reading that chapter
first.

Setting up your own DNSSEC policy means that you have to include a
``dnssec-policy`` clause in the zone file. This sets values for the
various parameters that affect the signing of zones and the rolling of
keys. The following is an example of such a clause:

::

   dnssec-policy standard {
       dnskey-ttl 600;
       key {
           ksk lifetime 365d algorithm ecdsap256sha256;
           zsk lifetime 60d algorithm ecdsap256sha256;
       };
       max-zone-ttl 600;
       parent-ds-ttl 600;
       parent-propagation-delay 2h;
       parent-registration-delay 3d;
       publish-safety 7d;
       retire-safety 7d;
       signatures-refresh 5d;
       signatures-validity 15d;
       signatures-validity-dnskey 15d;
       zone-propagation-delay 2h;
   };

The various parts of the policy are:

-  The name. As each zone can use a different policy, ``named`` needs to
   be able to distinguish between policies. This is done by giving each
   policy a name, being ``standard`` in the above example.

-  The ``keys`` clause lists all keys that should be in the zone, along
   with their associated parameters. In this example, we are using the
   conventional KSK/ZSK split, with the KSK changed every year and the
   ZSK changed every two months. We have used one of the two mandatory
   algorithms for the keys. (The ``default`` DNSSEC policy sets a CSK
   that is never changed.)

-  The parameters ending in ``-ttl`` are, as expected, the TTLs of the
   associated records. Remember that we said that during a key rollover,
   we have to wait for records to expire from caches? Well, the values
   here tell BIND the maximum amount of time it has to wait for this to
   happen. Values can be set for the DNSKEY records in your zone, the
   non-DNSKEY records in your zone, and for the DS records in the parent
   zone.

-  Another set of time-related parameters are those ending in
   ``-propagation-delay``. These tell BIND how long it takes for a
   change in zone contents to become available on all secondary servers.
   (This may be non-negligible, for example, if a large zone is
   transferred over a slow link.)

-  The policy also sets values for the various signature parameters: how
   long the signatures on the DNSKEY and non-DNSKEY records are valid,
   and how often BIND should re-sign the zone.

-  When a new KSK or CSK appears in the zone, the associated DS record
   needs to be included in the parent zone. That time is represented by
   the ``parent-registration-delay`` option. Getting the record into the
   parent zone may still require manual intervention, so we will look at
   this in more detail in section `??? <#working-with-the-parent-2>`__.

-  Finally, the parameters ending in ``-safety`` are are there to give
   you a bit of leeway in case a key roll doesn't go to plan. When
   introduced into the zone, the ``publish-safety`` time is the amount
   of additional time over and above that calculated from the other
   parameters, that the new key will be in the zone before BIND starts
   to sign record with it. Similarly, the ``retire-safety`` is the
   amount of additional time, over and above that calculated from the
   other parameters, that the old key is retained in the zone before
   being removed.

(You do not have to specify all the items listed above in your policy
definition. Any that are not set will take the default value.)

Usually, the exact timing of a key roll, or how long a signature remains
valid is not critical. For this reason err on the side of caution when
setting values for the parameters. It is better to have an operation
like a key roll take a few days longer than absolutely required than it
is to have a quick key roll but have users get validation failures
during the process.

Having defined a new policy called "standard", we now need to tell
``named`` to use it. We do this by adding a ``dnssec-policy standard;``
statement to the configuration file. Like a number of configuration
statements, it can be placed in the ``options`` statement (so applying
to all zones on the server), a ``view`` statement (applying to all zones
in the view) or a ``zone`` statement (applying only to that zone). In
this example, we'll add it to the ``zone`` statement:

::

   zone "example.net" in {
       ...
       dnssec-policy standard;
       ...
   };

Finally, tell ``named`` to use the new policy:

::

   # rndc reconfig

... and that's it. ``named`` will now apply the "standard" policy to
your zone.

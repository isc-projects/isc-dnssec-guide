Signing Easy Start Explained
============================

.. _enable-automatic-maintenance-explained:

Enable Automatic DNSSEC Maintenance Explained
---------------------------------------------

Signing a zone requires a number of separate steps:

-  Generation of the keys to sign the zone.

-  Inclusion of the keys into the zone.

-  Signing of the records in the file (including the generation of the
   NSEC or NSEC3 records).

Maintaining it comprises a set of ongoing tasks:

-  Re-signing the zone as signatures approach expiration.

-  Generation of new keys as the time approaches for a key roll.

-  Inclusion of new keys into the zone when the rollover starts.

-  Transition from signing the zone with the old set of keys to signing
   the zone with the new set of keys.

-  Waiting the appropriate interval before removing the old keys from
   the zone.

-  Deleting the old keys.

That is a lot of complexity, and it is all handled with the single
``dnssec-policy default`` statement. We will see later on (in section
`??? <#signing-custom-policy>`__) how the these actions can be tuned by
setting up our own DNSSEC policy with customized parameters. In many
cases though, the defaults are adequate. After reading the rest of this
guide, you may decide that you do need to tweak the parameters or use an
alternative signing method. But if not, that's it - you can forget about
DNSSEC, there is nothing more to do.

At the time of writing (April 2020), ``dnssec-policy`` is still a
relatively new feature in BIND. As such, although it is the preferred
way to run DNSSEC in your zone, it can't do everything that you can do
with a more "hands on" approach to signing and key maintenance. For this
reason, we will be covering alternative signing techniques in
`??? <#signing-alternative-ways>`__.

.. _signing-alternative-ways:

Alternative Ways of Signing a Zone
==================================

Although use of ``dnssec-policy`` is the preferred way to sign zones in
BIND, there are occasions where a more "hands-on" approach may be
needed. The principal example is where external hardware is used to
generate and sign the zone. ``dnssec-policy`` currently does not support
use of external hardware so if your security policy requires it, you
will need to use one of the methods described here.

The idea of DNSSEC was first discussed in the 1990s and has been
extensively developed over the intervening years. BIND has tracked the
development of this technology, often being the first nameserver
implementation to introduce new ideas. For compatibility reasons, BIND
retained older ways of doing things even when new ways were added. This
particularly applies to signing and maintaining zones, where different
levels of automation are available.

The following lists the available methods of signing in BIND in the
order they were introduced. This is also the order of decreasing
complexity as far as you are concerned.

Manual
   "Manual" signing was the first method to be introduced into BIND and
   its name describes it perfectly - you have to do everything. In the
   more automated methods, you load an unsigned zone file into
   ``named``, which takes care of signing it. With manual signing, you
   have provide a signed zone for ``named`` to serve.

   In practice, this means creating an unsigned zone file as usual, then
   using the BIND-provided tools ``dnssec-keygen`` to create the keys
   and ``dnssec-signzone`` to sign the zone. The signed zone is stored
   in another file and is the one you tell BIND to load. If you want to
   update the zone (for example to add a resource record) you update the
   unsigned zone, re-sign it, and tell ``named`` to load the updated
   signed copy. The same goes for refreshing signatures or rolling keys
   - you are responsible for providing the signed zone served by
   ``named``. (In the case of rolling keys, you are also responsible for
   ensuring that the keys are added and removed at the correct times.)

   Why would you want to sign your zone this way? Well, you probably
   wouldn't in the normal course of events; but as there may be
   circumstances in which it is required, the scripts have been left in
   the BIND distribution.

Semi-Automatic
   The first step in DNSSEC automation came with BIND 9.7, when the
   ``auto-dnssec`` option was added. This causes ``named`` to
   periodically search the directory holding the key files (see
   `Generate Keys <#generate-keys>`__ for a description of these) and to
   use the information in them to add and remove keys and to sign the
   zone.

   Use of ``auto-dnssec`` alone requires that the zone be dynamic,
   something not suitable for a number of situations. BIND 9.9 added the
   ``inline-signing`` option. With this, ``named`` essentially keeps the
   signed and unsigned copies of the zone separate. The signed zone is
   created from the unsigned one using the key information. When the
   unsigned zone is updated and the zone reloaded, ``named`` detects the
   changes and updates the signed copy of the zone.

   This mode of signing and been termed "Semi-Automatic" in this
   document because keys still have to be manually created (and deleted
   when appropriate). Although not an onerous task, it is still
   something extra to do.

   The obvious question of course is, why would anyone want to use this
   method when fully-automated ones are available? At the time of
   writing, the fully-automatic methods handle all scenarios,
   particularly that of having a single key shared between multiple
   zones. They also don't handle keys stored in Hardware Security
   Modules (HSMs). HSMs are briefly covered in
   `??? <#hardware-security-modules>`__

Fully-Automatic with dnssec-keymgr
   The next step in the automation of DNSSEC operations came with BIND
   9.11, which introduced the ``dnssec-keymgr`` utility. This is a
   separate program and is expected to be run on a regular basis
   (probably via ``cron``). It reads a DNSSEC policy from its
   configuration file and reads timing information from the DNSSEC key
   files. With this information it creates new key files with timing
   information in them consistent with the policy. ``named`` is run as
   usual, picking up the timing information in the key files to
   determine when to add and remove keys, and when to sign with them.

   In BIND 9.17.0 and later, this method of handling your DNSSEC
   policies has been replaced by the ``dnssec-policy`` statement in the
   configuration file.

Fully-Automatic with dnssec-policy
   Introduced in BIND 9.16, this replaces ``dnssec-keymgr`` from BIND
   9.17 onwards and avoids the need to run a separate program. It also
   handles the creation of keys if a zone is added (``dnssec-keymgr``
   requires an initial key) and deletes old key files as they are
   removed from the zone. This is the method described in
   `??? <#easy-start-guide-for-authoritative-servers>`__.

We will now look at these methods in more detail. We will cover
semi-automatic signing first, as that contains a lot of useful
information about keys and key timings. We will then describe what
``dnssec-keymgr`` adds to semi-automatic signing. After that, we will
touch on fully-automatic signing with dnssec-policy. Since this has
already been described in
`??? <#easy-start-guide-for-authoritative-servers>`__ we will just
mention a few points that were not covered there. Finally, we will
briefly describe manual signing.

Semi-Automatic Signing
----------------------

As noted above, the term semi-automatic signing has been used in this
document to indicate the mode of signing enabled by the ``auto-dnssec``
and ``inline-signing`` keywords. ``named`` signs the zone without and
manual intervention, based purely on the timing information in the
DNSSEC key files. The files however, have to be created manually.

By appropriately setting the key parameters and the timing information
in the key files, you can implement any DNSSEC policy you want for your
zones. But why manipulate the key information yourself rather than rely
on ``dnssec-keymgr`` or ``dnssec-policy`` to do it for you? The answer
is that is allows you to do things that, at the time of writing
(mid-2020), you are not able to do with one of the key managers; for
example, the ability to use an HSM to store keys, or the ability to use
the same key for multiple zones.

So now let's get down to the details. To convert a traditional
(insecure) DNS zone to a secure one, we need to create various
additional records (DNSKEY, RRSIG, NSEC or NSEC3) and, as with
fully-automatic signing, upload verifiable information (such as DS
record) to the parent zone to complete the chain of trust.

.. note::

   For the rest of this chapter we assume all configuration files, key
   files, and zone files are stored in
   /etc/bind
   . And most of the times we show examples of running various commands
   as the root user. This is arguably not the best setup, but we don't
   want to distract you from what's important here: learning how to sign
   a zone. There are many best practices for deploying a more secure
   BIND installation, with techniques such as jailed process and
   restricted user privileges, but we are not going to cover any of
   those in this document. We are trusting you, a responsible DNS
   administrator, to take the necessary precautions to secure your
   system.

For our examples below, we will be working with the assumption that
there is an existing insecure zone ``example.com`` that we will be
converting to a secure version. The secure version will use both a KSK
and a ZSK.

Generate Keys
~~~~~~~~~~~~~

Everything in DNSSEC centers around keys, and we will begin by
generating our own keys.

::

   # cd /etc/bind
   # dnssec-keygen -a RSASHA256 -b 1024 example.com
   Generating key pair...........................+++++ ......................+++++ 
   Kexample.com.+008+34371
   # dnssec-keygen -a RSASHA256 -b 2048 -f KSK example.com
   Generating key pair........................+++ ..................................+++ 
   Kexample.com.+008+00472

This generated four key files in ``/etc/bind/keys``:

-  Kexample.com.+008+34371.key

-  Kexample.com.+008+34371.private

-  Kexample.com.+008+00472.key

-  Kexample.com.+008+00472.private

The two files ending in .key are your public keys. These contain the
DNSKEY resource records that will appear in the zone. The two files
ending in .private are your private keys, and contain the information
that ``named`` actually uses to sign the zone.

Of the two pairs, one is the zone-signing key (ZSK), and one is the
key-signing Key (KSK). We can tell which is which by looking at the file
contents (actual keys shortened for display):

::

   # cat Kexample.com.+008+34371.key
   ; This is a zone-signing key, keyid 34371, for example.com.
   ; Created: 20200616104249 (Tue Jun 16 11:42:49 2020)
   ; Publish: 20200616104249 (Tue Jun 16 11:42:49 2020)
   ; Activate: 20200616104249 (Tue Jun 16 11:42:49 2020)
   example.com. IN DNSKEY 256 3 8 AwEAAfel66...LqkA7cvn8=
   # cat Kexample.com.+008+00472.key
   ; This is a key-signing key, keyid 472, for example.com.
   ; Created: 20200616104254 (Tue Jun 16 11:42:54 2020)
   ; Publish: 20200616104254 (Tue Jun 16 11:42:54 2020)
   ; Activate: 20200616104254 (Tue Jun 16 11:42:54 2020)
   example.com. IN DNSKEY 257 3 8 AwEAAbCR6U...l8xPjokVU=

(The keys themselves have been abbreviated for clarity.)

The first line of each file tell us what type of key it is. Also, by
looking at the actual DNSKEY record, we could tell them apart: 256 is
ZSK, and 257 is KSK.

As you may have guessed, the name of the file also tells us something
about the contents. The file names are of the form:

::

   K<zone-name>+<algorithm-id>+<keyid>

The zone name is self-explanatory. The algorithm ID is a number assigned
to the algorithm used to construct the key: the number appears in the
DNSKEY resource record (and is highlighted in the example above). In
this case, 8 means the algorithm RSASHA256. Finally, the keyid is
essentially a hash of the key itself.

Make sure these files are readable by ``named`` and make sure that the
.private file isn't readable by anyone else.

Refer to `??? <#system-entropy>`__ for information on how you might
speed up the key generation process if your random number generator has
insufficient entropy.

Setting Key Timing Information
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You may remember that in the above description of this method, we said
that time information related to rolling keys is stored in the key
files. This is placed there by ``dnssec-keygen`` when the file is
created, and it can be modified using ``dnssec-settime``. By default,
only a limited amount of timing information is included in the file, as
is illustrated in the examples in the previous section.

All the dates are the same and are the date and time that
``dnssec-keygen`` created the key. We can use ``dnssec-settime`` to
modify the dates [1]_. For example, if we wanted to publish this key in
the zone on 1 July 2020, use it to sign records for a year starting on
15 July 2020, and remove it from the zone at the end of July 2021, we
could use the following command:

::

   # dnssec-settime -P 20200701 -A 20200715 -I 20210715 -D 20210731 Kexample.com.+008+34371.key
   ./Kexample.com.+008+34371.key
   ./Kexample.com.+008+34371.private

which would set the contents of the key file to:

::

   ; This is a zone-signing key, keyid 34371, for example.com.
   ; Created: 20200616104249 (Tue Jun 16 11:42:49 2020)
   ; Publish: 20200701000000 (Wed Jul  1 01:00:00 2020)
   ; Activate: 20200715000000 (Wed Jul 15 01:00:00 2020)
   ; Inactive: 20210715000000 (Thu Jul 15 01:00:00 2021)
   ; Delete: 20210731000000 (Sat Jul 31 01:00:00 2021)
   example.com. IN DNSKEY 256 3 8 AwEAAfel66...LqkA7cvn8=

Below is a complete list of each of the metadata fields, and how each
one affects the signing of your zone:

1. *Created*: A record of the date on which the key was created. It is
   not used in calculations, it is just present for documentation
   purposes.

2. *Publish*: Sets the date on which a key is to be published to the
   zone. After that date, the key will be included in the zone but will
   not be used to sign it. This allows validating resolvers to get a
   copy of the new key in their cache before any there are any resource
   records signed with it. By default, if not specified during creation
   time, this is set to the current time, meaning the key will be
   published as soon as ``named`` picks it up.

3. *Activate*: Sets the date on which the key is to be activated. After
   that date, resource records will be signed with the key. By default,
   if not specified during creation time, this is set to the current
   time, meaning the key will be used to sign data as soon as ``named``
   picks it up.

4. *Revoke:* Sets the date on which the key is to be revoked. After that
   date, the key will be flagged as revoked. It will be included in the
   zone and will be used to sign it. This is used to notify validating
   resolvers that this key is about to be removed or retired from the
   zone. (This state is not used in normal day to day operations. See
   `RFC 5011 <https://tools.ietf.org/html/rfc5011>`__ to understand the
   circumstances where it may be used.)

5. *Inactive*: Sets the date on which the key is to become inactive.
   After that date, the key will still be included in the zone, but it
   will not be used to sign it. This sets the "expiration" or "retire"
   date for a key.

6. *Delete*: Sets the date on which the key is to be deleted. After that
   date, the key will no longer be included in the zone, but it
   continues to exist on the file system or key repository.

This can be summarized as follows:

.. table:: Key Metadata Comparison

   +----------+------------------+------------------+------------------+
   | Metadata | Included in Zone | Used to Sign     | Purpose          |
   |          | File?            | Data?            |                  |
   +==========+==================+==================+==================+
   | Created  | No               | No               | Record of when   |
   |          |                  |                  | the key was      |
   |          |                  |                  | created          |
   +----------+------------------+------------------+------------------+
   | Publish  | Yes              | No               | Introducing a    |
   |          |                  |                  | key soon to be   |
   |          |                  |                  | active           |
   +----------+------------------+------------------+------------------+
   | Activate | Yes              | Yes              | Activation date  |
   |          |                  |                  | for new key      |
   +----------+------------------+------------------+------------------+
   | Revoke   | Yes              | Yes              | Notifying a key  |
   |          |                  |                  | soon to be       |
   |          |                  |                  | retired          |
   +----------+------------------+------------------+------------------+
   | Inactive | Yes              | No               | Inactivate or    |
   |          |                  |                  | retire a key     |
   +----------+------------------+------------------+------------------+
   | Delete   | No               | No               | Deletion or      |
   |          |                  |                  | removal of key   |
   |          |                  |                  | from zone        |
   +----------+------------------+------------------+------------------+

The publication date is the date the key is introduced into the zone.
Some time later it is activated and is used to sign resource records.
After a period of use BIND stops using it to sign records and at some
later time it is removed from the zone.

Finally, we should note that the ``dnssec-keygen`` command supports the
same set of switches so if we had wanted, we could have set the dates
when we created the key.

.. _semi-automatic-signing-reconfigure-bind:

Reconfigure BIND
~~~~~~~~~~~~~~~~

Having the created the keys with the appropriate timing information, the
next step is to turn on DNSSEC signing. Below is a very simple
``named.conf``, in our example environment, this file is
``/etc/bind/named.conf``. The lines you most likely need to add are in
bold.

::

   options {
       directory "/etc/bind";
       recursion no;
       minimal-responses yes;
   };

   zone "example.com" IN {
       type primary;
       file "example.com.db";
       auto-dnssec maintain;
       inline-signing yes;
   };

When you are done updating the configuration file, tell ``named`` to
reload:

::

   # rndc reload
   server reload successful

.. _semi-automated-signing-verification:

Verify that The Zone is Signed Correctly
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You should now check that your zone is signed. Follow the steps in
`??? <#signing-verification>`__

.
.. _semi-automatic-signing-upload-ds:

Upload DS Record to Parent
~~~~~~~~~~~~~~~~~~~~~~~~~~

As described in `??? <#signing-easy-start-upload-to-parent-zone>`__, we
now have to upload information to the parent zone. The format of the
information and how to generate it is described in
`??? <#working-with-parent-zone>`__, although remember that you have to
use the file holding the KSK that you generated above as input to the
process.

When the DS record is published in the parent zone, you are fully
signed.

Check Your Zone Can Be Validated
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Finally, follow the steps in `??? <#how-to-test-authoritative-server>`__
to confirm a query will recognize the zone as properly signed and
vouched for by the parent zone.

So... What Now?
~~~~~~~~~~~~~~~

With the zone signed, you need to monitor it. These tasks are described
in `??? <#signing-maintenance-tasks>`__. However, an additional task is
that as time comes up for a key roll, you need to create the new key. Of
course, there is nothing stopping you creating keys for the next fifty
years all at once and setting key times appropriately. Whether the
increased risk in having the private key files for future keys available
on disk offsets the overhead of having to remember to create a new key
before a rollover depends on your security policy.

.. _advanced-discussions-automatic-dnssec-keymgr:

Fully-Automatic Signing With dnssec-keymgr
------------------------------------------

``dnssec-keymgr`` is a program supplied with BIND (versions 9.11 to
9.16) to help with key rollovers. When run, it compares the timing
information for existing keys with the defined policy, and adjusts it if
necessary. It also creates additional keys as required.

``dnssec-keymgr`` is completely separate from ``named``. As we will see,
the policy states a coverage period; ``dnssec-keymgr`` will generate
enough key files to handle all rollovers in that period. However, it is
a good idea to schedule it to run on a regular basis; that way there is
no chance of forgetting to run it when the coverage period ends.

So, down to the detail.

BIND should be set up in exactly the same way as described in
`Semi-Automatic Signing <#semi-automatic-signing>`__; in other words,
with ``auto-dnssec`` set to ``maintain`` and ``inline-signing`` set to
``true``. Then a policy file must be created. The following is an
example of such a file:

::

   # cat policy.conf
   policy standard {
       coverage 1y;
       algorithm RSASHA256;
       directory "/etc/bind";
       keyttl 2h;

       key-size ksk 4096;
       roll-period ksk 1y;
       pre-publish ksk 30d;
       post-publish ksk 30d;

       key-size zsk 2048;
       roll-period zsk 90d;
       pre-publish zsk 30d;
       post-publish zsk 30d;
   };

   zone example.com {
       policy standard;
   };

   zone example.net {
       policy standard;
       keyttl 300;
   };

As can be seen, the syntax is similar to that of the ``named``
configuration file.

In the example above, we define a DNSSEC policy called "standard". Keys
are created using the RSASHA256 algorithm, assigned a TTL of two hours
and are placed in the directory ``/etc/bind``. KSKs have a key size of
4096 bits, are expected to roll once a year; the key is added to the
zone 30 days before it becomes active, and is retained in the zone for
30 days after it is rolled. ZSKs have a key size of 2048 bits, will roll
every 90 days and, like the KSKs, are added to the zone 30 days before
they are used for signing, and retained for 30 days after ``named``
ceases to sign with them.

The policy is applied to two zones, ``example.com`` and ``example.net``.
The policy is applied unaltered to the former, but for the latter the
setting for the DNSKEY TTL has been overridden and set to 300 seconds.

To apply the policy, we need to run ``dnssec-keymgr``. Since this does
not read the ``named`` configuration file, it relies on the presence of
at least one key file for a zone to tell it that the zone is
DNSSEC-enabled. So if they don't already exist, we first need to create
a key file for each zone. We can do that either by running
``dnssec-keygen`` to create a key file for each zone [2]_, or by
specifying the zones in question on the command line. We will do the
latter:

::

   # dnssec-keymgr -c policy.conf example.com example.net
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -L 7200 -a RSASHA256 -b 2048 example.net
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -L 7200 -fk -a RSASHA256 -b 4096 example.net
   # /usr/local/sbin/dnssec-settime -K /etc/bind -I 20200915110318 -D 20201015110318 Kexample.net.+008+31339
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -S Kexample.net.+008+31339 -L 7200 -i 2592000
   # /usr/local/sbin/dnssec-settime -K /etc/bind -I 20201214110318 -D 20210113110318 Kexample.net.+008+14526
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -S Kexample.net.+008+14526 -L 7200 -i 2592000
   # /usr/local/sbin/dnssec-settime -K /etc/bind -I 20210314110318 -D 20210413110318 Kexample.net.+008+46069
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -S Kexample.net.+008+46069 -L 7200 -i 2592000
   # /usr/local/sbin/dnssec-settime -K /etc/bind -I 20210612110318 -D 20210712110318 Kexample.net.+008+13018
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -S Kexample.net.+008+13018 -L 7200 -i 2592000
   # /usr/local/sbin/dnssec-settime -K /etc/bind -I 20210617110318 -D 20210717110318 Kexample.net.+008+55237
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -S Kexample.net.+008+55237 -L 7200 -i 2592000
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -L 7200 -a RSASHA256 -b 2048 example.com
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -L 7200 -fk -a RSASHA256 -b 4096 example.com
   # /usr/local/sbin/dnssec-settime -K /etc/bind -P 20200617110318 -A 20200617110318 -I 20200915110318 -D 20201015110318 Kexample.com.+008+31168
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -S Kexample.com.+008+31168 -L 7200 -i 2592000
   # /usr/local/sbin/dnssec-settime -K /etc/bind -I 20201214110318 -D 20210113110318 Kexample.com.+008+24199
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -S Kexample.com.+008+24199 -L 7200 -i 2592000
   # /usr/local/sbin/dnssec-settime -K /etc/bind -I 20210314110318 -D 20210413110318 Kexample.com.+008+08728
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -S Kexample.com.+008+08728 -L 7200 -i 2592000
   # /usr/local/sbin/dnssec-settime -K /etc/bind -I 20210612110318 -D 20210712110318 Kexample.com.+008+12874
   # /usr/local/sbin/dnssec-keygen -q -K /etc/bind -S Kexample.com.+008+12874 -L 7200 -i 2592000
   # /usr/local/sbin/dnssec-settime -K /etc/bind -P 20200617110318 -A 20200617110318 Kexample.com.+008+26186

This creates enough key files to last for the coverage period, set in
the policy file to be one year. The script should be run on a regular
basis (probably via ``cron``) to keep the reserve of key files topped
up. With the shortest roll period set to 90 days, every 30 days would be
more than adequate.

At any time, you can check chat key changes are coming up and whether
the keys and timings are correct by using ``dnssec-coverage``. For
example, to check coverage for the next 60 days:

::

    # dnssec-coverage -d 2h -m 1d -l 60d -K /etc/bind/keys
   PHASE 1--Loading keys to check for internal timing problems
   PHASE 2--Scanning future key events for coverage failures
   Checking scheduled KSK events for zone example.net, algorithm RSASHA256...
     Wed Jun 17 11:03:18 UTC 2020:
       Publish: example.net/RSASHA256/55237 (KSK)
       Activate: example.net/RSASHA256/55237 (KSK)

   Ignoring events after Sun Aug 16 11:47:24 UTC 2020

   No errors found

   Checking scheduled ZSK events for zone example.net, algorithm RSASHA256...
     Wed Jun 17 11:03:18 UTC 2020:
       Publish: example.net/RSASHA256/31339 (ZSK)
       Activate: example.net/RSASHA256/31339 (ZSK)
     Sun Aug 16 11:03:18 UTC 2020:
       Publish: example.net/RSASHA256/14526 (ZSK)

   Ignoring events after Sun Aug 16 11:47:24 UTC 2020

   No errors found

   Checking scheduled KSK events for zone example.com, algorithm RSASHA256...
     Wed Jun 17 11:03:18 UTC 2020:
       Publish: example.com/RSASHA256/26186 (KSK)
       Activate: example.com/RSASHA256/26186 (KSK)

   No errors found

   Checking scheduled ZSK events for zone example.com, algorithm RSASHA256...
     Wed Jun 17 11:03:18 UTC 2020:
       Publish: example.com/RSASHA256/31168 (ZSK)
       Activate: example.com/RSASHA256/31168 (ZSK)
     Sun Aug 16 11:03:18 UTC 2020:
       Publish: example.com/RSASHA256/24199 (ZSK)

   Ignoring events after Sun Aug 16 11:47:24 UTC 2020

   No errors found

The ``-d 2h`` and ``-m 1d`` on the command line specify the maximum TTL
for the DNSKEYs and other resource records in the zone, in this example
two hours and one day respectively. ``dnssec-coverage`` needs this
information when it checks that the zones will remain secure through key
rolls.

.. _advanced-discussions-automatic-dnssec-policy:

Fully-Automatic Signing With dnssec-policy
------------------------------------------

The latest development of DNSSEC key management appeared with BIND 9.16,
and is the full integration of key management into ``named``. Managing
the signing process and rolling of these keys has been described in
`??? <#easy-start-guide-for-authoritative-servers>`__, and will not be
repeated here. A few points are worth noting though:

-  The ``dnssec-policy`` statement in the ``named`` configuration file
   describes all aspects of the DNSSEC policy, including the signing.
   With ``dnssec-keymgr``, this is split between two configuration files
   and two programs.

-  When using ``dnssec-policy``, there is no need to set the
   ``auto-dnssec`` and ``inline-signing`` options for a zone. The zone's
   ``policy`` statement implicitly does this.

-  It is possible to manage some zones served by an instance of BIND
   through ``dnssec-policy`` and others through ``dnssec-keymgr``, but
   this is not recommended. Although everything should be fine, if you
   modify the configuration files and inadvertently specify a zone to be
   managed by both systems, BIND will get seriously confused.

.. _advanced-discussions-manual-key-management-and-signing:

Manual Signing
--------------

Manual signing of a zone was the first method of signing introduced into
BIND and has, as the name suggests, no automation. In short, you have to
do everything: create the keys, to sign the zone file with them, load
the signed zone, periodically re-sign the zone, handle key rolls,
including interaction with the parent. Certainly you could so all this,
although you would probably write scripts to handle it - in which case,
why not use one of the automated methods? Nevertheless, as a one-off way
of signing the zone, perhaps for test purposes, it may be useful so it
will be briefly covered here.

The first step is to create the keys as described in `Generate
Keys <#generate-keys>`__. You must then edit the zone file to make sure
the proper DNSKEY entries are included in your zone file, then use the
command ``dnssec-signzone``:

::

   # cd /etc/bind/keys/example.com/
   # dnssec-signzone -A -t -N INCREMENT -o example.com -f /etc/bind/db/example.com.signed.db \
   > /etc/bind/db/example.com.db Kexample.com.+008+17694.key Kexample.com.+008+06817.key
   Verifying the zone using the following algorithms: RSASHA256.
   Zone fully signed:
   Algorithm: RSASHA256: KSKs: 1 active, 0 stand-by, 0 revoked
                         ZSKs: 1 active, 0 stand-by, 0 revoked
   /etc/bind/db/example.com.signed.db
   Signatures generated:                       17
   Signatures retained:                         0
   Signatures dropped:                          0
   Signatures successfully verified:            0
   Signatures unsuccessfully verified:          0
   Signing time in seconds:                 0.046
   Signatures per second:                 364.634
   Runtime in seconds:                      0.055

The -o switch explicitly defines the domain name (``example.com`` in
this case), -f switch specifies the output file name. The second line
has 3 parameters, they are the unsigned zone name
(``/etc/bind/db/example.com.db``), ZSK, and KSK file names. This
generated a plain text file ``/etc/bind/db/example.com.signed.db``,
which you can verify for correctness.

Finally, you'll need to update ``named.conf`` to load the signed version
of the zone, so it looks something like this:

::

   zone "example.com" IN {
       type primary;
       file "db/example.com.signed.db";
   };

After issuing a ``rndc reconfig`` command, BIND will be serving a signed
zone. The file ``dsset-example.com`` (created by ``dnssec-signzone``
when it signed the ``example.com`` zone) contains the DS record for the
zones KSK. You will need to pass that to the administrator of the parent
zone for them to place it in the zone.

You will need to re-sign periodically as well as every time the zone
data changes. You will also need to manually roll the keys by adding and
removing DNSKEY records (and interacting with the parent) at the
appropriate times.

.. [1]
   We could also modify the dates using an editor. But that is likely to
   be more error-prone than using ``dnssec-settime``.

.. [2]
   Only one key file - for either a KSK or ZSK - is needed to signal the
   presence of the zone. ``dnssec-keygen`` will create files of both
   types as needed.

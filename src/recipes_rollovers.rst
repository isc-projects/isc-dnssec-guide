.. _recipes-rollovers:

Rollover Recipes
================

If you are signing your zone using a ``dnssec-policy`` statement, you
don't really need this section. In the policy statement you set how long
you want your keys to be valid for, other parameters (such as the time
taken for information to propagate through your zone, how long it takes
for your parent zone to register a new DS record etc.) and that's more
or less it. ``named`` takes care of everything for you (apart from
uploading the new DS records to your parent zone - that is covered in
`??? <#signing-easy-start-upload-to-parent-zone>`__, although some
screenshots from a session where a KSK is uploaded to the parent zone
are presented here). However, it is useful in describing what's happens
through the rollover process and what you should be monitoring.

.. _recipes-zsk-rollover:

ZSK Rollover Recipe
-------------------

This recipe covers how to perform a ZSK rollover using what is known as
the Pre-Publication method. For other ZSK rolling methods, please see
`??? <#zsk-rollover-methods>`__ in
`??? <#dnssec-advanced-discussions>`__.

Below is the timeline for a ZSK rollover to occur on January 1st, 2021:

1. December 1st, 2020, a month before rollover

   -  Generate new ZSK

   -  Add DNSKEY for new ZSK to zone

2. January 1st, 2021, day of rollover

   -  New ZSK used to replace RRSIGs for the bulk of the zone

3. February 1st, 2021

   -  Remove old ZSK DNSKEY RRset from zone

   -  DNSKEY signatures made with KSK are changed

The current active ZSK has the ID 17694 in this example. For more
information on key management (such as what inactive date is, and why 30
days for example), please see
`??? <#advanced-discussions-key-management>`__.

One Month Before ZSK Rollover
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On December 1st, 2020, a month before the planned rollover, you should
change the parameters on the current key (17694) to become inactive on
January 1st, 2021, and be deleted from the zone on February 1st, 2021,
as well as generate a successor key (51623):

::

   # cd /etc/bind/keys/example.com/
   # dnssec-settime -I 20210101 -D 20210201 Kexample.com.+008+17694
   ./Kexample.com.+008+17694.key/GoDaddy

   ./Kexample.com.+008+17694.private
   # dnssec-keygen -S Kexample.com.+008+17694
   Generating key pair..++++++ ...........++++++ 
   Kexample.com.+008+51623

The first command gets us into the key directory
``/etc/bind/keys/example.com/``, where keys for ``example.com`` are
stored.

The second ``dnssec-settime`` sets an inactive (-I) date of January 1st,
2021, and a deletion (-D) date of February 1st, 2021 for the current ZSK
(Kexample.com.+008+17694).

Then the third command ``dnssec-keygen`` creates a successor key, using
the exact same parameters (algorithms, key sizes, etc.) as the current
ZSK. The new ZSK created in our example is Kexample.com.+008+51623.

Don't forget to make sure the successor keys are readable by ``named``.

You can see in ``named``'s logging messages informing you when the next
key checking event is scheduled to occur, the frequency of which can be
controlled by ``dnssec-loadkeys-interval``. The log message looks like
this:

::

   zone example.com/IN (signed): next key event: 01-Dec-2020 00:13:05.385

And you can check the publish date of the key by looking at the key
file:

::

   # cd /etc/bind/keys/example.com
   # cat Kexample.com.+008+51623.key 
   ; This is a zone-signing key, keyid 11623, for example.com.
   ; Created: 20201130160024 (Mon Dec  1 00:00:24 2020)
   ; Publish: 20201202000000 (Fri Dec  2 08:00:00 2020)
   ; Activate: 20210101000000 (Sun Jan  1 08:00:00 2021)
   ...

Since the publish date is set to the morning of December 2nd, the next
morning you will notice that your zone has gained a new DNSKEY record,
but the new ZSK is not yet being used to generate signatures. Below is
the abbreviated output with shortened DNSKEY and RRSIG when querying the
authoritative name server, 192.168.1.13:

::

   $ dig @192.168.1.13 example.com. DNSKEY +dnssec +multiline

   ...
   ;; ANSWER SECTION:
   example.com.        600 IN DNSKEY 257 3 8 (
                   AwEAAcWDps...lM3NRn/G/R
                   ) ; KSK; alg = RSASHA256; key id = 6817
   example.com.        600 IN DNSKEY 256 3 8 (
                   AwEAAbi6Vo...qBW5+iAqNz
                   ) ; ZSK; alg = RSASHA256; key id = 51623
   example.com.        600 IN DNSKEY 256 3 8 (
                   AwEAAcjGaU...0rzuu55If5
                   ) ; ZSK; alg = RSASHA256; key id = 17694
   example.com.        600 IN RRSIG DNSKEY 8 2 600 (
                   20210101000000 20201201230000 6817 example.com.
                   LAiaJM26T7...FU9syh/TQ= )
   example.com.        600 IN RRSIG DNSKEY 8 2 600 (
                   20210101000000 20201201230000 17694 example.com.
                   HK4EBbbOpj...n5V6nvAkI= )
   ...

And for good measures, let's take a look at the SOA record and its
signature for this zone. Notice the RRSIG is signed by the current ZSK
17694. This will come in handy later when you want to verify whether or
not the new ZSK is in effect:

::

   $ dig @192.168.1.13 example.com. SOA +dnssec +multiline

   ...
   ;; ANSWER SECTION:
   example.com.        600 IN SOA ns1.example.com. admin.example.com. (
                   2020120102 ; serial
                   1800       ; refresh (30 minutes)
                   900        ; retry (15 minutes)
                   2419200    ; expire (4 weeks)
                   300        ; minimum (5 minutes)
                   )
   example.com.        600 IN RRSIG SOA 8 2 600 (
                   20201230160109 20201130150109 17694 example.com.
                   YUTC8rFULaWbW+nAHzbfGwNqzARHevpryzRIJMvZBYPo
                   NAeejNk9saNAoCYKWxGJ0YBc2k+r5fYq1Mg4ll2JkBF5
                   buAsAYLw8vEOIxVpXwlArY+oSp9T1w2wfTZ0vhVIxaYX
                   6dkcz4I3wbDx2xmG0yngtA6A8lAchERx2EGy0RM= )

These are all the manual tasks you need to perform for a ZSK rollover.
If you have followed the configuration examples in this guide of using
``inline-signing`` and ``auto-dnssec``, everything else is automated for
you.

Day of ZSK Rollover
~~~~~~~~~~~~~~~~~~~

On the actual day of the rollover, although there is technically nothing
for you to do, you should still keep an eye on the zone to make sure new
signatures are being generated by the new ZSK (51623 in this example).
The easiest way is to query the authoritative name server 192.168.1.13
for the SOA record like you did a month ago:

::

   $ dig @192.168.1.13 example.com. SOA +dnssec +multiline

   ...
   ;; ANSWER SECTION:
   example.com.        600 IN SOA ns1.example.com. admin.example.com. (
                   2020112011 ; serial
                   1800       ; refresh (30 minutes)
                   900        ; retry (15 minutes)
                   2419200    ; expire (4 weeks)
                   300        ; minimum (5 minutes)
                   )
   example.com.        600 IN RRSIG SOA 8 2 600 (
                   20210131000000 20201231230000 51623 example.com.
                   J4RMNpJPOmMidElyBugJp0RLqXoNqfvo/2AT6yAAvx9X
                   zZRL1cuhkRcyCSLZ9Z+zZ2y4u2lvQGrNiondaKdQCor7
                   uTqH5WCPoqalOCBjqU7c7vlAM27O9RD11nzPNpVQ7xPs
                   y5nkGqf83OXTK26IfnjU1jqiUKSzg6QR7+XpLk0= )
   ...

As you can see, the signature generated by the old ZSK (17694)
disappeared, replaced by a new signature generated from the new ZSK
(51623).

.. note::

   Not all signatures will disappear magically on the same day,
   depending on when each one is generated. Worst case scenario is that
   a new signature could have been signed by the old ZSK (17695) moments
   before it was deactivated, thus the signature could live for almost
   30 more days, all the way up to right before February 1st.

   This is why it is important that you should keep the old ZSK in the
   zone for a little bit longer and not delete it right away.

One Month After ZSK Rollover
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Again, technically there should be nothing you need to do on this day,
but it doesn't hurt to verify that the old ZSK (17694) is now completely
gone from your zone. ``named`` will not touch
``Kexample.com.+008+17694.private`` and ``Kexample.com.+008+17694.key``
on your file system. Running the same ``dig`` command for DNSKEY should
suffice:

::

   $ dig @192.168.1.13 example.com. DNSKEY +multiline +dnssec

   ...
   ;; ANSWER SECTION:
   example.com.        600 IN DNSKEY 257 3 8 (
                   AwEAAcWDps...lM3NRn/G/R
                   ) ; KSK; alg = RSASHA256; key id = 6817
   example.com.        600 IN DNSKEY 256 3 8 (
                   AwEAAdeCGr...1DnEfX+Xzn
                   ) ; ZSK; alg = RSASHA256; key id = 51623
   example.com.        600 IN RRSIG DNSKEY 8 2 600 (
                   20170203000000 20170102230000 6817 example.com.
                   KHY8P0zE21...Y3szrmjAM= )
   example.com.        600 IN RRSIG DNSKEY 8 2 600 (
                   20170203000000 20170102230000 51623 example.com.
                   G2g3crN17h...Oe4gw6gH8= )
   ...

Congratulations, the ZSK rollover is complete! As for the actual key
files (the ``.key`` and ``.private`` files), they may be deleted at this
point, but it's not required.

.. _recipes-ksk-rollover:

KSK Rollover Recipe
-------------------

This recipe describes how to perform KSK rollover using the Double-DS
method. For other KSK rolling methods, please see
`??? <#ksk-rollover-methods>`__ in
`??? <#dnssec-advanced-discussions>`__. The registrar used in this
recipe is `GoDaddy <https://www.godaddy.com>`__. Also for this recipe,
we are keeping the number of DS records down to just one per active set
using just SHA-1, for the sake of better clarity, although in practice
most zone operators choose to upload 2 DS records as we have shown in
`??? <#working-with-parent-zone>`__. For more information on key
management (such as what inactive date is, and why 30 days for example),
please see `??? <#advanced-discussions-key-management>`__.

Below is the timeline for a KSK rollover to occur on January 1st, 2021:

1. December 1st, 2020, a month before rollover

   -  Change timer on the current KSK

   -  Generate new KSK and DS records

   -  Add DNSKEY for the new KSK to zone

   -  Upload new DS records to parent zone

2. January 1st, 2021, day of rollover

   -  Use the new KSK to sign all DNSKEY RRset, this generates new
      RRSIGs

   -  Add new RRSIGs to the zone

   -  Remove RRSIG for the old ZSK from zone

   -  Start using the new KSK to sign DNSKEY

3. February 1st, 2021

   -  Remove the old KSK DNSKEY from zone

   -  Remove old DS records from parent zone

The current active KSK has the ID 24828, and this is the DS record that
has already been published by the parent zone:

::

   # dnssec-dsfromkey -a SHA-1 Kexample.com.+007+24828.key
   example.com. IN DS 24828 7 1 D4A33E8DD550A9567B4C4971A34AD6C4B80A6AD3

.. _one-month-before-ksk-rolloever:

One Month Before KSK Rollover
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On December 1st, 2020, a month before the planned rollover, you should
change the parameters on the current key to become inactive on January
1st, 2021, and be deleted from the zone on February 1st, 2021, as well
as generate a successor key (23550). Finally, you should generate a new
DS record based on the new key 23550:

::

   # cd /etc/bind/keys/example.com/
   # dnssec-settime -I 20210101 -D 20210201 Kexample.com.+007+24828
   ./Kexample.com.+007+24848.key
   ./Kexample.com.+007+24848.private
   # dnssec-keygen -S Kexample.com.+007+24848
   Generating key pair.......................................................................................++ ...................................++ 
   Kexample.com.+007+23550
   # dnssec-dsfromkey -a SHA-1 Kexample.com.+007+23550.key
   example.com. IN DS 23550 7 1 54FCF030AA1C79C0088FDEC1BD1C37DAA2E70DFB

The first command gets us into the key directory
``/etc/bind/keys/example.com/``, where keys for ``example.com`` are
stored.

The second ``dnssec-settime`` sets an inactive (-I) date of January 1st,
2021, and a deletion (-D) date of February 1st, 2021 for the current KSK
(Kexample.com.+007+24848).

Then the third command ``dnssec-keygen`` creates a successor key, using
the exact same parameters (algorithms, key sizes, etc.) as the current
KSK. The new key pair created in our example is Kexample.com.+007+23550.

The fourth and final command ``dnssec-dsfromkey`` creates a DS record
from the new KSK (23550), using SHA-1 as the digest type. Again, in
practice most people generate two DS records for both supported digest
types (SHA-1 and SHA-256), but for our example here we are only using
one to keep the output small and hopefully clearer.

Don't forget to make sure the successor keys are readable by ``named``.

You can see in syslog the messages informing you when the next key
checking event is, and it looks like this:

::

   zone example.com/IN (signed): next key event: 01-Dec-2020 00:13:05.385

And you can check the publish date of the key by looking at the key
file:

::

   # cd /etc/bind/keys/example.com
   # cat Kexample.com.+007+23550.key
   ; This is a key-signing key, keyid 23550, for example.com.
   ; Created: 20201130160024 (Thu Dec  1 00:00:24 2020)
   ; Publish: 20201202000000 (Fri Dec  2 08:00:00 2020)
   ; Activate: 20210101000000 (Sun Jan  1 08:00:00 2021)
   ...

Since the publish date is set to the morning of December 2nd, the next
morning you will notice that your zone has gained a new DNSKEY record
based on your new KSK, but no corresponding RRSIG yet. Below is the
abbreviated output with shortened DNSKEY and RRSIG when querying the
authoritative name server, 192.168.1.13:

::

   $ dig @192.168.1.13 example.com. DNSKEY +dnssec +multiline

   ...
   ;; ANSWER SECTION:
   example.com.   300 IN DNSKEY 256 3 7 (
                   AwEAAdYqAc...TiSlrma6Ef
                   ) ; ZSK; alg = NSEC3RSASHA1; key id = 29747
   example.com.   300 IN DNSKEY 257 3 7 (
                   AwEAAeTJ+w...O+Zy9j0m63
                   ) ; KSK; alg = NSEC3RSASHA1; key id = 24828
   example.com.   300 IN DNSKEY 257 3 7 (
                   AwEAAc1BQN...Wdc0qoH21H
                   ) ; KSK; alg = NSEC3RSASHA1; key id = 23550
   example.com.   300 IN RRSIG DNSKEY 7 2 300 (
                   20201206125617 20201107115617 24828 example.com.
                   4y1iPVJOrK...aC3iF9vgc= )
   example.com.   300 IN RRSIG DNSKEY 7 2 300 (
                   20201206125617 20201107115617 29747 example.com.
                   g/gfmPjr+y...rt/S/xjPo= )

   ...

Any time after you have generated the DS record, you could upload it,
you don't have to wait for the DNSKEY to be published in your zone,
since this new KSK is not active yet. You could choose to do it
immediately after the new DS record has been generated on December 1st,
or you could wait until the next day after you have verified that the
new DNSKEY record is added to the zone. Below are the screenshots from
using GoDaddy's web-based interface to add a new DS record [1]_.

1. After logging in, click the green "Launch" button next to the domain
   name you want to manage.

   .. figure:: ../img/add-ds-1.png
      :alt: Upload DS Record Step #1
      :width: 70.0%

      Upload DS Record Step #1

2. Scroll down to the "DS Records" section and click Manage.

   .. figure:: ../img/add-ds-2.png
      :alt: Upload DS Record Step #2
      :width: 40.0%

      Upload DS Record Step #2

3. A dialog appears, displaying the current key (24828). Click "Add DS
   Record".

   .. figure:: ../img/add-ds-3.png
      :alt: Upload DS Record Step #3
      :width: 80.0%

      Upload DS Record Step #3

4. Enter the Key ID, algorithm, digest type, and the digest, then click
   "Next".

   .. figure:: ../img/add-ds-4.png
      :alt: Upload DS Record Step #4
      :width: 80.0%

      Upload DS Record Step #4

5. Address any errors and click "Finish".

   .. figure:: ../img/add-ds-5.png
      :alt: Upload DS Record Step #5
      :width: 80.0%

      Upload DS Record Step #5

6. Both DS records are shown. Click "Save".

   .. figure:: ../img/add-ds-6.png
      :alt: Upload DS Record Step #6
      :width: 80.0%

      Upload DS Record Step #6

Finally, let's verify that the registrar has published the new DS
record. This may take anywhere from a few minutes to a few days,
depending on your parent zone. You could verify whether or not your
parent zone has published the new DS record by querying for the DS
record of your zone. In the example below, the Google public DNS server
8.8.8.8 is used:

::

   $ dig @8.8.8.8 example.com. DS

   ...
   ;; ANSWER SECTION:
   example.com.    21552   IN  DS  24828 7 1 D4A33E8DD550A9567B4C4971A34AD6C4B80A6AD3
   example.com.    21552   IN  DS  23550 7 1 54FCF030AA1C79C0088FDEC1BD1C37DAA2E70DFB

You could also query your parent zone's authoritative name servers
directly to see if these records have been published. DS records will
not show up on your own authoritative zone, so do not query your own
name servers for them. In this recipe, the parent zone is ``.com``, so
querying a few of the ``.com`` name servers is another appropriate
verification.

Day of KSK Rollover
~~~~~~~~~~~~~~~~~~~

If you have followed the examples in this document as described in
`??? <#easy-start-guide-for-authoritative-servers>`__, there is
technically nothing you need to do manually on the actual day of the
rollover. However, you should still keep an eye on the zone to make sure
new signature(s) are being generated by the new KSK (23550 in this
example). The easiest way is to query the authoritative name server
192.168.1.13 for the same DNSKEY and signatures like you did a month
ago:

::

   $ dig @192.168.1.13 example.com. DNSKEY +dnssec +multiline

   ...
   ;; ANSWER SECTION:
   example.com.   300 IN DNSKEY 256 3 7 (
                   AwEAAdYqAc...TiSlrma6Ef
                   ) ; ZSK; alg = NSEC3RSASHA1; key id = 29747
   example.com.   300 IN DNSKEY 257 3 7 (
                   AwEAAeTJ+w...O+Zy9j0m63
                   ) ; KSK; alg = NSEC3RSASHA1; key id = 24828
   example.com.   300 IN DNSKEY 257 3 7 (
                   AwEAAc1BQN...Wdc0qoH21H
                   ) ; KSK; alg = NSEC3RSASHA1; key id = 23550
   example.com.    300 IN RRSIG DNSKEY 7 2 300 (
                   20210201074900 20210101064900 23550 mydnssecgood.org.
                   S6zTbBTfvU...Ib5eXkbtE= )
   example.com.    300 IN RRSIG DNSKEY 7 2 300 (
                   20210105074900 20201206064900 29747 mydnssecgood.org.
                   VY5URQA2/d...OVKr1+KX8= )
   ...

As you can see, the signature generated by the old KSK (24828)
disappeared, replaced by a new signature generated from the new KSK
(23550).

One Month After KSK Rollover
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

While the removal of the old DNSKEY from zone should be automated by
``named``, the removal of the DS record is manual. You should make sure
the old DNSKEY record is gone from your zone first by querying for the
DNSKEY records of the zone, and this time we expect to see one less
DNSKEY, namely the key with ID of 24828:

::

   $ dig @192.168.1.13 example.com. DNSKEY +dnssec +multiline

   ...
   ;; ANSWER SECTION:
   example.com.    300 IN DNSKEY 256 3 7 (
                   AwEAAdYqAc...TiSlrma6Ef
                   ) ; ZSK; alg = NSEC3RSASHA1; key id = 29747
   example.com.    300 IN DNSKEY 257 3 7 (
                   AwEAAc1BQN...Wdc0qoH21H
                   ) ; KSK; alg = NSEC3RSASHA1; key id = 23550
   example.com.    300 IN RRSIG DNSKEY 7 2 300 (
                   20210208000000 20210105230000 23550 mydnssecgood.org.
                   Qw9Em3dDok...bNCS7KISw= )
   example.com.    300 IN RRSIG DNSKEY 7 2 300 (
                   20210208000000 20210105230000 29747 mydnssecgood.org.
                   OuelpIlpY9...XfsKupQgc= )
   ...

Now, we can remove the old DS record for key 24828 from our parent zone.
Be careful to remove the correct DS record. If we accidentally removed
the new DS record(s) of key ID 23550, it could lead to a problem called
"security lameness", as discussed in
`??? <#troubleshooting-security-lameness>`__, and may cause users unable
to resolve any names in our zone.

1. After logging in and launched the domain, scroll down to the "DS
   Records" section and click Manage.

   .. figure:: ../img/remove-ds-1.png
      :alt: Remove DS Record Step #1
      :width: 40.0%

      Remove DS Record Step #1

2. A dialog appears, displaying both keys (24828 and 23550). Use the far
   right hand X button to remove the key 24828.

   .. figure:: ../img/remove-ds-2.png
      :alt: Remove DS Record Step #2
      :width: 80.0%

      Remove DS Record Step #2

3. Key 24828 now appears crossed out, click "Save" to complete the
   removal.

   .. figure:: ../img/remove-ds-3.png
      :alt: Remove DS Record Step #3
      :width: 80.0%

      Remove DS Record Step #3

Congratulations, the KSK rollover is complete! As for the actual key
files (the ``.key`` and ``.private`` files), they may be deleted at this
point, but it's not required.

.. [1]
   The screenshots were taken from GoDaddy's interface at the time the
   original version of this guide was published (2015). It may have
   changed since then.

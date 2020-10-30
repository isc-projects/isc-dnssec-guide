.. _revert-to-unsigned:

Reverting to Unsigned Recipe
============================

This recipe describes how to revert from signed zone (DNSSEC) back to
unsigned (DNS).

Whether or not the world thinks your zone is signed really comes down to
the DS records hosted by your parent zone. If there are no DS records,
the world thinks your zone is not signed. So reverting to unsigned is as
easy as removing all DS records from the parent zone.

Below is an example of removing using
`GoDaddy <https://www.godaddy.com>`__ web-based interface to remove all
DS records.

1. After logging in, click the green "Launch" button next to the domain
   name you want to manage.

   .. figure:: ../img/unsign-1.png
      :alt: Revert to Unsigned Step #1
      :width: 60.0%

      Revert to Unsigned Step #1

2. Scroll down to the "DS Records" section and click Manage.

   .. figure:: ../img/unsign-2.png
      :alt: Revert to Unsigned Step #2
      :width: 40.0%

      Revert to Unsigned Step #2

3. A dialog appears, displaying all current keys. Use the far right hand
   X button to remove each key.

   .. figure:: ../img/unsign-3.png
      :alt: Revert to Unsigned Step #3
      :width: 70.0%

      Revert to Unsigned Step #3

4. Click Save

   .. figure:: ../img/unsign-4.png
      :alt: Revert to Unsigned Step #4
      :width: 70.0%

      Revert to Unsigned Step #4

To be on the safe side, you should wait a while before actually deleting
all signed data from your zone, just in case some validating resolvers
out there have cached information. After you are certain that all cached
information have expired (usually this means TTL has passed), you may
reconfigure your zone. This is the ``named.conf`` when it is signed,
with DNSSEC-related configurations in bold:

::

   zone "example.com" IN {
       type primary;
       file "db/example.com.db";
       allow-transfer { any; };
       dnssec-policy "default";
   };

Remove the ``dnssec-policy`` line so your ``named.conf`` looks like this, then use
``rndc reload`` to reload the zone:

::

   zone "example.com" IN {
       type primary;
       file "db/example.com.db";
       allow-transfer { any; };
   };

Your zone is now reverted back to the traditional, insecure DNS format.

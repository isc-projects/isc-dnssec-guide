.. _signing-maintenance-tasks:

Maintenance Tasks
=================

Zone data is signed and the parent zone has published your DS records
MDASH at this point your zone is officially secure. When other
validating resolvers lookup information in your zone, they are able to
follow the 12-step process as described in
`??? <#how-does-dnssec-change-dns-lookup-revisited>`__ and verify the
authenticity and integrity of the answers.

There is not that much left for you to do, as the DNS administrator, at
an ongoing basis. Whenever you update your zone, BIND will automatically
resign your zone with new RRSIG and NSEC or NSEC3 records, and even
increment the serial number for you. If you choose to split your keys
into a KSK and ZSK, the rolling of the ZSK is completely automatic.
Rolling of a KSK or CSK may require some manual intervention though.
Before we discuss that though, let's introduce two more DNSSEC-related
resource records, CDS and CDNSKEY.

.. _cds-cdnskey:

The CDS and CDNSKEY Resource Records
------------------------------------

Passing the DS record to the organization running the parent zone has
always been recognized as a bottleneck in the key rollover process. To
automate the process the CDS and CDNSKEY resource records were
introduced.

The CDS and CDNSKEY records are identical to the DS and DNSKEY records,
except in the type code and the name. When such a record appears in the
child zone, it is a signal to the parent that it should update the DS it
has for that zone. In essence, what happens is that the parent notices
the presence of either or both of the CDS and CDNSKEY records in the
child zone. It checks these records in the usual way i.e., that they are
signed by a valid key for the zone. If the record(s) successfully
validate, the parent zone's DS RRset for the child zone is changed to
correspond to the CDS (or CDNSKEY) records. (If you want more
information on how the signaling works and the issues surrounding it,
the details can be found in `RFC
7344 <https://tools.ietf.org/html/rfc7344>`__ and `RFC
8078 <https://tools.ietf.org/html/rfc8078>`__.)

.. _working-with-the-parent-2:

Working with the Parent Zone (2)
--------------------------------

Once you have signed your zone the only manual tasks for you to do are
to monitor KSK or CSK key rolls rolls and pass the new DS record to the
parent zone. However, if the parent can process CDS or CDNSKEY records,
you may not even have to do that [1]_.

When the time approaches for the roll of a KSK or CSK, BIND will add a
CDS and a CDNSKEY record for the key in question to the apex of the
zone. If your parent zone supports polling for CDS/CDNSKEY records, they
will be uploaded and the DS record published in the parent - we hope. At
the time of writing (mid 2020) BIND does not check for the presence of a
DS record in the parent zone before completing the KSK or CSK rollover
and withdrawing the old key. Instead, you will have to use the ``rndc`` tool
to tell ``named`` that the DS record has been published, for example:

::

   # rndc dnssec -checkds published example.net

If your parent doesn't support CDS/CDNSKEY, when a new KSK appears in
your zone, you will have to supply the DNSKEY or DS record to the parent
zone manually, probably using the same mechanism you used to upload the
records for the first time. Again, you will have to use the ``rndc`` tool
to tell ``named`` that the DS record has been published.

.. [1]
   For security reasons, a parent zone that supports CDS/CDNSKEY may require
   the DS record to be  manually uploaded when we first sign the zone:
   until our zone is signed, the parent cannot be sure that a CDS or CDNSKEY
   record it finds by querying our zone really comes from our zone. Thus it
   needs to use some other form of secure transfer to obtain the information.

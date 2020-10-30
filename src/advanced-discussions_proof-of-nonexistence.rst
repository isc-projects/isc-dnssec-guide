.. _advanced-discussions-proof-of-nonexistence:

Proof of Non-Existence (NSEC and NSEC3)
=======================================

How do you prove that something does not exist? This zen-like question
is an interesting one, and in this section we will provide an overview
of how DNSSEC solves the problem.

Why is it even important to have authenticated denial of existence?
Couldn't we just send back a "hey, what you asked for does not exist",
and somehow generate a digital signature to go with it, proving it
really is from the correct authoritative source? Well, the technical
challenge of signing nothing aside, this solution has flaws, one of
which is it gives an attacker a way to create the appearance of denial
of service by replaying this message on the network.

We are going to use a little story, and tell it three different times to
illustrate how proof of nonexistence works. In our story, we run a small
company with three employees: Alice, Edward, and Susan. For reasons that
are far too complicated to go into, they don't have email accounts;
instead, email for them is sent to a single account and a nameless
intern passes the message to them. The intern has access to our private
DNSSEC key to create signatures for their responses.

If we followed the approach of giving back the same answer no matter
what was asked, when people emailed and asked for the message to be
passed to "Bob", our intern would simply answer "Sorry, that person
doesn’t work here" and sign this message. This answer can be validated
because our intern signed the response with our private DNSSEC key.
However since the signature doesn’t change, an attacker could record
this message. If the attacker could intercept our email, when the next
person emailed in asking for it to be passed to Susan, the attacker
could return the exact same message: "Sorry, that person doesn’t work
here" with the same signature. Now the attacker has successfully fooled
the sender into thinking that Susan doesn’t work at our company, and
might even be able to convince all senders that no one works at this
company".

To solve this problem, two different solutions were created. We will
look at the first one, NSEC, next.

.. _advanced-discussions-nsec:

NSEC
----

The NSEC record is used to prove that something does not exist, by
providing the name before it, and the name after it. Using our tiny
company example, this would be analogous to someone sending an email for
Bob and our nameless intern responding with with: "I'm sorry, that
person doesn't work here. The name before that is Alice, and the name
after that is Edward". Let's say another email was received for a
non-existent person, this time Oliver; our intern would respond "I'm
sorry, that person doesn't work here. The name before that is Edward,
and the name after that is Susan". If another sender asked for Todd, the
answer would be: "I'm sorry, that person doesn't work here. The name
before that is Susan, and there's no other name after that".

So we end up with four NSEC records:

::

   example.com.        300   IN  NSEC    alice.example.com.  A RRSIG NSEC
   alice.example.com.  300 IN  NSEC    edward.example.com. A RRSIG NSEC
   edward.example.com. 300 IN  NSEC    susan.example.com.  A RRSIG NSEC
   susan.example.com.  300 IN  NSEC    example.com.        A RRSIG NSEC

What if the attacker tried to use the same replay method described
earlier? If someone sent an email for Edward, none of the four answers
would fit. If attacker replied with message #2, "I'm sorry, that person
doesn't work here. The name before it is Alice, and the name after it is
Edward", it is obviously false, since "Edward" is in the response; same
for #3, Edward and Susan. As for #1 and #4, Edward does not fall in
range before Alice or after Susan, so the sender can logically deduce
that it was an incorrect answer.

When BIND signs your zone, the zone data will be automatically sorted on
the fly before generating NSEC records, much like how a phone directory
is sorted.

The NSEC record allows for a proof of non-existence for record types. If
you ask a signed zone for a name that exists but for a record type that
doesn't (for that name), the signed NSEC record returned lists all of
the record types that *do* exist for the requested domain name.

NSEC records can also be used to show whether a record was generated as
the result of a wildcard expansion or not. The details of this are out
of scope for this document, but are described well in `RFC
7129 <https://tools.ietf.org/html/rfc7129>`__.

Unfortunately, the NSEC solution has a few drawbacks, one of which is
trivial "zone walking". A curious person can keep sending emails, and
our nameless, gullible intern will keep divulging information about our
employees. Imagine if the sender first asked: "Is Bob there?" and
received back the names Alice and Edward. Our sender can then email
again: "Is Edwarda. there?", and will get back Edward and Susan. (No,
"Edwarda" is not a real name. However, it is the first name
alphabetically after "Edward" and that is enough to get the intern reply
with a message telling us the next valid name after Edward.) Repeat the
process enough times and the person sending the emails will eventually
learn every name in our company phone directory. For many of you, this
may not be a problem, since the very idea of DNS is similar to a public
phone book: if you don't want a name to be known publicly, don't put it
in DNS! Consider using DNS views (split DNS) and only display your
sensitive names to a selective audience.

The second drawback of NSEC is a actually increased operational
overhead: no opt-out mechanism for insecure child zones, this generally
is a problem for parent zone operators dealing with a lot of insecure
child zones, such as ``.com``. To learn more about opt-out, please see
`NSEC3 Opt-Out <#advanced-discussions-nsec3-optout>`__.

.. _advanced-discussions-nsec3:

NSEC3
-----

NSEC3 adds two additional features that NSEC does not have:

1. No easy zone enumeration.

2. Provides a mechanism for the parent zone to exclude insecure
   delegations (i.e. delegations to zones that are not signed) from the
   proof of non-existence.

Recall, in `NSEC <#advanced-discussions-nsec>`__, we provided a range of
names to prove that something really does not exist. But as it turns
out, even disclosing these ranges of names becomes a problem: this made
it very easy for the curious minded to look at your entire zone. Not
only that, unlike a zone transfer, this "zone walking" is more resource
intensive. So how do we disclose something, without actually disclosing
it?

The answer is actually quite simple, hashing functions, or one-way
hashes. Without going into many details, think of it like a magical meat
grinder. A juicy piece of ribeye steak goes in one end, and out comes a
predictable shape and size of ground meat (hash) with a somewhat unique
pattern. No matter how hard you try, you cannot turn the ground meat
back into the juicy ribeye steak, that's what we call a one-way hash.

NSEC3 basically runs the names through a one-way hash, before giving it
out, so the recipients can verify the non-existence, without any
knowledge of the actual names.

So let's tell our little receptionist story for the third time, this
time with NSEC3. This time, our intern is not given a list of actual
names, he is given a list of "hashed" names. So instead of Alice,
Edward, and Susan, the list he is given reads like this (hashes
shortened for easier reading):

::

   FSK5.... (produced from Edward)
   JKMA.... (produced from Susan)
   NTQ0.... (produced from Alice)

Then, an email is received for Bob again. Our intern takes the name Bob
through a hash function, and the result is L8J2..., so he replies: "I'm
sorry, that person doesn't work here. The name before that is JKMA...,
and the name after that is NTQ0...". There, we proved Bob doesn't exist,
without giving away any names! To put that into proper NSEC3 resource
records, they would look like this (again, hashes shortened for
display):

::

   FSK5....example.com. 300 IN NSEC3 1 0 10 1234567890ABCDEF  JKMA... A RRSIG
   JKMA....example.com. 300 IN NSEC3 1 0 10 1234567890ABCDEF  NTQ0... A RRSIG
   NTQ0....example.com. 300 IN NSEC3 1 0 10 1234567890ABCDEF  FSK5... A RRSIG

.. note::

   Just because we employed one-way hash functions does not mean there's
   no way for a determined individual to figure out what your zone data
   is. Someone could still gather all of your NSEC3 records and hashed
   names, and perform an offline brute-force attack by trying all
   possible combinations to figure out what the original name is. This
   would be like if someone really wanted to know how you got the ground
   meat, he could buy all cuts of meat and ground it up at home using
   the same model of meat grinder, and compare the output with the meat
   you gave him. It is expensive and time consuming (especially with
   real meat), but like everything else in cryptography, if someone has
   enough resources and time, nothing is truly private forever. If you
   are concerned about someone performing this type of attack on your
   zone data, see about adding salt as described in `NSEC3
   Salt <#advanced-discussions-nsec3-salt>`__.

.. _advanced-discussions-nsec3param:

NSEC3PARAM
~~~~~~~~~~

The above NSEC3 examples used four parameters: 1, 0, 10, and
1234567890ABCDEF. 1 represents the algorithm, 0 represents the opt-out
flag, 10 represents the number of iterations, and 1234567890ABCDEF is the
salt. Let's look at how each one can be configured:

-  *Algorithm*: Not much of a choice here, the only defined value
   currently is 1 for SHA-1.

-  *Opt-out*: Set this to 1 if you want to do NSEC3 opt-out, which we
   will discuss in `NSEC3
   Opt-Out <#advanced-discussions-nsec3-optout>`__.

-  *Iterations*: iterations defines the number of additional times to
   apply the algorithm when generating an NSEC3 hash. More iterations
   yields more secure results, but consumes more resources for both
   authoritative servers and validating resolvers. In this regard, we
   have similar considerations as we've seen in `??? <#key-sizes>`__ of
   security versus resources.

-  *Salt*: The salt cannot be configured explicitly, but you can provide
   a salt length and ``named`` will generate a random salt of the given length.
   We learn more about salt in :ref:`advanced_discussions_nsec3_salt`.

If you want to use these NSEC3 parameters for a zone, you can add the
following configuration to your ``dnssec-policy``. For example, to create an
NSEC3 chain using the SHA-1 hash algorithm, with no opt-out flag,
5 iterations, and a salt that is 8 characters long, use:

::

   dnssec-policy "nsec3" {
       ...
       nsec3param iterations 5 optout no salt-length 8;
   };

To set the opt-out flag, 15 iterations, and no salt, use:

::

   dnssec-policy "nsec3" {
       ...
       nsec3param iterations 15 optout yes salt-length 0;
    };

.. _advanced-discussions-nsec3-optout:

NSEC3 Opt-Out
~~~~~~~~~~~~~

One of the advantages of NSEC3 over NSEC is the ability for parent zones
to publish less information about its child or delegated zones. Why
would you ever want to do that? Well, if a significant number of your
delegations are not yet DNSSEC-aware, meaning they are still insecure or
unsigned, generating DNSSEC-records for their NS and glue records is not
a good use of your precious name server resources.

The resources may not seem like a lot, but imagine in if you are the
operator of busy top level domains such as ``.com`` or ``.net``, with
millions and millions of insecure delegated domain names, it quickly
adds up. As of mid-2020, less than 1.5% of all ``.com`` zones are
signed. Basically, without opt-out, if you have 1,000,000 delegations,
only 5 of which are secure, you still have to generate NSEC RRset for
the other 999,995 delegations; with NSEC3 opt-out, you will have saved
yourself 999,995 sets of records.

For most DNS administrators who do not manage a large number of
delegations, the decision whether or not to use NSEC3 opt-out is
probably not relevant.

To learn more about how to configure NSEC3 opt-out, please see
`??? <#recipes-nsec3-optout>`__.

.. _advanced-discussions-nsec3-salt:

NSEC3 Salt
~~~~~~~~~~

As described in `NSEC3 <#advanced-discussions-nsec3>`__, while NSEC3
doesn't put your zone data in plain public display, it is still not
difficult for an attacker to collect all the hashed names, and perform
an offline attack. All that is required is running through all the
combinations to construct a database of plaintext names to hashed names,
also known as a "rainbow table".

There is one more features NSEC3 gives us to provide additional
protection: salt. Basically, salt gives us the ability introduce further
randomness into the hashed results. Whenever the salt is changed, any
pre-computed rainbow table is rendered useless, and a new rainbow table
must be re-computed. If the salt is changed from time to time, it
becomes difficult to construct a useful rainbow table, thus difficult to
walk the DNS zone data programmatically. How often you want to change
your NSEC3 salt is up to you.

To learn more about what steps to take to change NSEC3, please see
`??? <#recipes-nsec3-salt>`__.

.. _advanced-discussions-nsec-or-nsec3:

NSEC or NSEC3?
--------------

So which one should you choose? NSEC or NSEC3? There is not really a
single right answer here that fits everyone. It all comes down to your
needs or requirements.

If you prefer not to make your zone easily enumerable, implementing
NSEC3 paired with a periodically changed salt will provide a certain
level of privacy protection. However, someone could still randomly guess
the names in your zone (such as "ftp" or "www"), as in the traditional
insecure DNS.

If you have many many delegations, and have a need for opt-out to save
resources, NSEC3 is for you.

Other than that, using NSEC is typically a good choice for most zone
administrators, as it relieves the authoritative servers from the
additional cryptographic operations that NSEC3 requires, and NSEC is
comparatively easier to troubleshoot than NSEC3.

NSEC3 in conjunction with ``dnssec-policy`` is supported since BIND
version 9.16.9.

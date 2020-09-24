.. _dnssec-commonly-asked-questions:

Commonly Asked Questions
========================

No questions are too stupid to ask, below is a collection of such
questions and answers.

Do I need IPv6 to have DNSSEC? No. DNSSEC can be deployed independent of
IPv6. Does DNSSEC encrypt my DNS traffic, so others cannot eavesdrop on
my DNS queries? No. Although cryptographic keys and digital signatures
are used in DNSSEC, they only provide authenticity and integrity, not
privacy. Someone who sniffs network traffic can still see all the DNS
queries and answers in plain text, DNSSEC just makes it very difficult
for the eavesdropper to alter or spoof the DNS responses. Does DNSSEC
protect the communication between my laptop and my name server?
Unfortunately, currently, no. DNSSEC is designed to protect the
communication between the end clients (laptop) and the name servers,
however, there are few applications or stub resolver libraries as of
late 2016 that take advantage of this capability. This communication
between the recursive server to the clients are commonly called the
"last mile", while enabling DNSSEC today does little to enhance the
security for the last mile, we hope that will change in the near future
as more and more applications become DNSSEC-aware. Does DNSSEC secure
zone transfers? No. You should consider using TSIG to secure zone
transfers among your name servers. Is DNSSEC going to protect me from
malicious web sites? The answer for now is, unfortunately for early
stages of DNSSEC deployment, no. DNSSEC is designed so you can have
confidence that when you received the DNS response for www.isc.org over
port 53, you know it really came from the ISC name servers, and the
answers are authentic. But that does not mean the web server you visit
over port 80 or port 443 is necessarily safe. Further more, 98.5% of the
domain names (as of this writing) have not signed their zones yet, so
DNSSEC cannot even validate their answers. The answer for sometime in
the future is, as more and more zones are signed and more and more
recursive servers are validating, DNSSEC will make it much more
difficult for attackers to spoof DNS responses or perform cache
poisoning. It still does not protect users from visiting a malicious web
site that the attacker owns and operates, or prevent users from
mis-typing a domain name, it just becomes unlikely that the attacker can
hijack other domain names. If I enable DNSSEC validation, will it break
DNS lookup for majority of the domain names, since most domains names
don't have DNSSEC yet? No, DNSSEC is backwards compatible to "standard"
DNS. As of this writing, although 98.5% of the .com domains have yet to
be signed, a DNSSEC-enabled validating resolver can still lookup all of
these domain names following the "old fashioned way". There are four (4)
categories of responses (`RFC 4035 Sec
4.3 <https://tools.ietf.org/html/rfc4035#section-4.3>`__): *Secure*:
Domains that have DNSSEC deployed correctly *Insecure*: Domains that
have yet to deploy DNSSEC *Bogus*: Domains that deployed DNSSEC but did
it incorrectly *Indeterminate*: Unable to determine whether or not to
use DNSSEC A validating resolver will still resolve #1 and #2, only #3
and #4 will result in a SERVFAIL.You may already be using DNSSEC
validation without realizing it, since some ISP's have begun enabling
DNSSEC validation on their recursive name servers. Google public DNS
(8.8.8.8) also has enabled DNSSEC validation. Do I need to have special
client software to use DNSSEC? No. DNSSEC only changes the communication
behavior among DNS servers, not DNS server (validating resolver) and
client (stub resolver). With DNSSEC validation enabled on your recursive
server, if a domain name doesn't pass the checks, an error message
(typically SERVFAIL) is returned to the clients, and to most client
software today, it looks as if the DNS query has failed, or the domain
name does not exist. Since DNSSEC uses public key cryptography, do I
need Public Key Infrastructure (PKI) in order to use DNSSEC? No, it
operates independently of an existing PKI. Public keys are stored within
the DNS hierarchy and the trustworthiness of each zone is guaranteed by
its parent zone, all the way back to the root zone. A copy of the trust
anchor for the root zone is distributed with BIND. Do I need to purchase
SSL certificates from a Certificate Authority (CA) to use DNSSEC? No.
With DNSSEC, you generate and publish your own keys, and sign your own
data as well. There is no need to pay someone else to do it for you. My
parent zone does not support DNSSEC, can I still sign my zone?
Technically, yes, you can sign your zone, but you wouldn't be getting
the full benefit of DNSSEC, as other validating resolvers would not be
able to validate your zone data. Without the DS record(s) in your parent
zone, other validating resolvers will treat your zone as an insecure
(traditional) zone, thus no actual verification is carried out. The end
result is, to the rest of the world, your zone still appears to be
insecure, and it will continue to be insecure until your parent zone can
host DS record(s) for you, effectively telling the rest of the world
that your zone is signed. Is DNSSEC the same thing as TSIG that I have
between my primary and secondary servers? No. TSIG is typically used
between primary and secondary name servers to secure zone transfers,
DNSSEC secures DNS lookup by validating answers. Even if you enabled
DNSSEC, zone transfers are still not validated, and if you wish to
secure the communication between your primary and secondary name
servers, you should consider setting up TSIG or similar secure channels.
How are keys copied from primary to secondary server(s)? DNSSEC uses
public cryptography, which results in two types of keys: public and
private. The public keys are part of the zone data, stored as DNSKEY
record types. Thus the public keys are synchronized from primary to
secondary server(s) as part of the zone transfer. The private keys do
not, and should not be stored anywhere else but the primary server in a
secured fashion. See `??? <#advanced-discussions-key-storage>`__ for
more information on key storage options and considerations. Can I use
the same key for multiple zones? Yes and no. Good security practice
suggests that you should use unique key pairs for each zone, just like
how you should have different passwords for your email account, social
media login, and online banking credentials. On a technical level, this
is completely feasible, but then multiple zones are at risk when one key
pair is compromised. If you have hundreds or thousands (or even hundreds
of thousands) of zones to administer, a single key pair for all might be
less error-prone to manage. You may choose to use the same approach to
password management: use unique passwords for your bank accounts and
shopping sites, but use a standard password for your not-very-important
logins. So categorize your zones, high valued zones (or zones that have
specific key rollover requirements) get their own key pairs, while other
more "generic" zones can use a single key pair for easier management. At
present (mid-2020), fully-automatic signing (using the ``dnssec-policy``
clause in your ``named`` configuration file) does not support this
except when the same zone appears in multiple views (see next question).
If you wish to use the same key for multiple zones, you should sign your
zones using semi-automatic signing. Each zone wishing to use the key
should point to the same key directory. How do I sign the different
instances of a zone that appears in multiple views? Add a
``dnssec-policy`` statement to each ``zone`` definition in the
configuration file. To avoid problems when a single computer may access
different instances of the zone while information is still in its cache
(e.g. (e.g. a laptop moving from your office to a customer site), you
should sign all instances with the same key. This means: Setting the
same DNSSEC policy for all instances of the zone. Making sure that the
key directory is the same for all instances of the zone. Will there be
any problems if I change the DNSSEC policy for a zone? If you are using
fully-automatic signing, no. Just change the parameters in the
``dnssec-policy`` statement and reload the configuration file. ``named``
will make a smooth transition to the new policy, ensuring that your zone
remains valid at all times.

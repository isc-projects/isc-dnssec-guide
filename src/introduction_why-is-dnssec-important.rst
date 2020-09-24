.. _why-is-dnssec-important:

Why is DNSSEC Important? (Why Should I Care?)
=============================================

You might be thinking to yourself: all this DNSSEC stuff sounds
wonderful, but why should I care? Below are some reasons why you may
want to consider deploying DNSSEC:

1. *Be a good netizen*: By enabling DNSSEC validation (as described in
   `??? <#dnssec-validation>`__) on your DNS servers, you're protecting
   your users or yourself a little more by checking answers returned to
   you; by signing your zones (as described in
   `??? <#dnssec-signing>`__), you are making it possible for other
   people to verify your zone data. As more people adopt DNSSEC, the
   Internet as a whole becomes more secure for everyone.

2. *Compliance*: You may not even get a say whether or not you want to
   implement DNSSEC, if your organization is subject to compliance
   standards that mandate it. For example, the US government set a
   deadline back in 2008, to have all ``.gov`` sub domains signed by the
   December 2009  [1]_. So if you operated a subdomain in ``.gov``, you
   must implement DNSSEC in order to be compliant. ICANN also requires
   that all new top-level domains support DNSSEC.

3. *Enhanced Security*: Okay, so the big lofty goal of "let's be good"
   doesn't appeal to you, and you don't have any compliance standards to
   worry about . Here is a more practical reason why you should consider
   DNSSEC: in case of a DNS-based security breach, such as cache
   poisoning or domain hijacking, after all the financial and brand
   damage done to your domain name, you might be placed under scrutiny
   for any preventive measure that could have been put in place. Think
   of this like having your web site only available via HTTP but not
   HTTPS.

4. *New Features*: DNSSEC brings not only enhanced security, but with
   that new level of security, a whole new suite of features. Once DNS
   can be trusted completely, it becomes possible to publish SSL
   certificates in DNS, or PGP keys for fully automatic cross-platform
   email encryption, or SSH fingerprints... People are still coming up
   with new features, but this all relies on a trust-worthy DNS
   infrastructure. To take a peek at these next generation DNS features,
   check out `??? <#introduction-to-dane>`__.

.. [1]
   The Office of Management and Budget (OMB) for the US government
   published `a memo in
   2008 <https://www.whitehouse.gov/sites/whitehouse.gov/files/omb/memoranda/2008/m08-23.pdf>`__,
   requesting all ``.gov`` sub-domains to be DNSSEC signed by December
   2009. This explains why ``.gov`` is the most deployed DNSSEC domain
   currently, with `around 90% of subdomains
   signed. <https://fedv6-deployment.antd.nist.gov/cgi-bin/generate-gov>`__

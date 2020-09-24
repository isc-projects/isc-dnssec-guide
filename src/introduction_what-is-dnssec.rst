What is DNSSEC?
===============

The Domain Name System (DNS) was designed in a day and age when the
Internet was a friendly and trusting place. The protocol itself provides
little protection against malicious or forged answers. DNS Security
Extensions (DNSSEC) addresses this need, by adding digital signatures
into DNS data so that each DNS response can be verified for integrity
(the answer did not change during transit) and authenticity (the data
came from the true source, not an impostor). In the ideal world when
DNSSEC is fully deployed, every single DNS answer can be validated and
trusted.

DNSSEC does not provide a secure tunnel; it does not encrypt or hide DNS
data. It operates independently of an existing Public Key Infrastructure
(PKI). It does not need SSL certificates or shared secrets. It was
designed with backwards compatibility in mind, and can be deployed
without impacting "old" unsecured domain names.

DNSSEC is deployed on the three major components of the DNS
infrastructure:

-  *Recursive Server*: People use recursive servers to lookup external
   domain names such www.example.com. Operators of recursive servers
   need to enable DNSSEC validation. With validation enabled, recursive
   servers will carry out additional tasks on each DNS response they
   received to ensure its authenticity.

-  *Authoritative Server*: People who publish DNS data on their name
   servers need to sign that data. This entails creating additional
   resource records, and publishing them to parent domains where
   necessary. With DNSSEC enabled, authoritative servers will respond to
   queries with additional DNS data, such as digital signatures and
   keys, in addition to the standard answers.

-  *Application*: This component lives on every client machine, from web
   server to smart phones. This includes resolver libraries on different
   Operating Systems, and applications such as web browsers.

In this guide, we will focus on the first two components, Recursive
Server and Authoritative Server, and only lightly touch on the third
component. We will look at how DNSSEC works, how to configure a
validating resolver, how to sign DNS zone data, and other operational
tasks and considerations.

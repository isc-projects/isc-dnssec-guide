Preface
=======

.. _preface-organization:

Organization
============

This document provides introductory information on how DNSSEC works, how
to configure BIND 9 to support some common DNSSEC features, as well as
some basic troubleshooting tips. The chapters are organized as follows:

`??? <#introduction>`__ covers the intended audience for this document,
assumed background knowledge, and a basic introduction to the topic of
DNSSEC.

`??? <#getting-started>`__ covers various requirements that are needed
before implementing DNSSEC, such as software versions, hardware
capacity, network requirements, and security changes.

`??? <#dnssec-validation>`__ walks through setting up a validating
resolver, more information on the validation process, as well as
examples of using tools to verify that the resolver is validating
answers.

`??? <#dnssec-signing>`__ walks through setting up a basic signed
authoritative zone, explains the relationship with the parent zone, and
on-going maintenance tasks.

`??? <#dnssec-troubleshooting>`__ provides some tips on how to analyze
and diagnose DNSSEC-related problems.

`??? <#dnssec-advanced-discussions>`__ covers several topics, from key
generation, key storage, key management, NSEC and NSEC3, to
disadvantages of DNSSEC.

`??? <#dnssec-recipes>`__ provides several working examples of common
solutions, with step-by-step details.

`??? <#dnssec-commonly-asked-questions>`__ lists some commonly asked
questions and answers about DNSSEC.

.. _preface-acknowledgement:

Acknowledgement
===============

This document is originally authored by Josh Kuo of `DeepDive
Networking <https://www.deepdivenetworking.com/>`__. He can be reached
at josh@deepdivenetworking.com

Thanks to the following individuals (in no particular order) who have
helped in completing this document: Jeremy C. Reed, Heidi Schempf,
Stephen Morris, Jeff Osborn, Vicky Risk, Jim Martin, Evan Hunt, Mark
Andrews, Michael McNally, Kelli Blucher, Chuck Aurora, Francis Dupont,
Rob Nagy and Ray Bellis.

Special thanks goes to Cricket Liu and Matt Larson for their
selflessness in knowledge sharing.

Thanks to all the reviewers and contributors, including: John Allen, Jim
Young, Tony Finch, Timothe Litt, and Dr. Jeffry A. Spain.

The sections on key rollover and key timing meta data borrowed heavily
from the Internet Engineering Task Force draft titled "DNSSEC Key Timing
Considerations" by S. Morris, J. Ihren, J. Dickinson, and W. Mekking,
subsequently published as `RFC
7583 <https://tools.ietf.org/html/rfc7583>`__.

Icons made by `Freepik <https://www.freepik.com/>`__ and
`SimpleIcon <https://www.simpleicon.com/>`__ from
` <https://www.flaticon.com>`__, licensed under `Creative Commons BY
3.0 <https://creativecommons.org/licenses/by/3.0/>`__.

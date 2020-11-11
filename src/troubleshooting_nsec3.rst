.. _troubleshooting-nsec3:

NSEC3 Troubleshooting
=====================

BIND includes a tool called ``nsec3hash`` that runs through the same
steps a validating resolver would, to generate the correct hashed name
based on NSEC3PARAM parameters. The command takes the following
parameters in order: salt, algorithm, iterations, and domain. For
example, if the salt is 1234567890ABCDEF, hash algorithm is 1, and
iteration is 10, to get the NSEC3-hashed name for ``www.example.com`` we
would execute a command like this:

::

   $ nsec3hash 1234567890ABCEDF 1 10 www.example.com
   RN7I9ME6E1I6BDKIP91B9TCE4FHJ7LKF (salt=1234567890ABCEDF, hash=1, iterations=10)

While it is unlikely you would construct a rainbow table of your own
zone data, this tool might be useful to troubleshoot NSEC3 problems.

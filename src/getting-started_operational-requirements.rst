Operational Requirements
========================

Parent Zone
-----------

Before starting your DNSSEC deployment, check with your parent zone
administrators to make sure they support DNSSEC. This may or may not be
the same entity as your registrar. As you will see later in
`??? <#working-with-parent-zone>`__, a crucial step in DNSSEC deployment
is to establish the parent-child trust relationship. If your parent zone
does not support DNSSEC yet, contact them to voice your concern.

Security Requirements
---------------------

Some organizations may be subject to stricter security requirements than
others. Check to see if your organization requires stronger
cryptographic keys be generated and stored, or how often keys need to be
rotated. The examples presented in this document are not intended for
high value zones. We cover some of these security considerations in
`??? <#dnssec-advanced-discussions>`__.

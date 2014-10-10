#!/bin/sh
# This script is a shortcut to quickly generate a single HTML
# file from the DocBook XML source in this directory

mkdir -p doc
cp src/dnssec-guide.css doc/

xsltproc --novalid --xinclude --nonet \
         -o doc/dnssec-guide.html --stringparam section.autolabel 1 \
         --stringparam section.label.includes.component.label 1 \
         --stringparam html.stylesheet dnssec-guide.css http://docbook.sourceforge.net/release/xsl/current/html/docbook.xsl \
         src/dnssec-guide.xml

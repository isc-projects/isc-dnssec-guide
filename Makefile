DBLATEX		= dblatex
PARAMS		= -P latex.output.revhistory=0 -P doc.collab.show=0

dnssec-guide.pdf:	src/*.xml
	$(DBLATEX) $(PARAMS) -q -o $@ src/dnssec-guide.xml

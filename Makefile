include $(top_srcdir)/Makefile.top
include $(top_srcdir)/Makefile.docs

EXTRA_DIST =					\
	conf.py					\
	advanced-discussions.rst		\
	commonly-asked-questions.rst		\
	getting-started.rst			\
	index.rst				\
	introduction.rst			\
	preface.rst				\
	recipes.rst				\
	signing.rst				\
	troubleshooting.rst			\
	validation.rst				\

html-local:
	$(AM_V_SPHINX)$(SPHINX_BUILD) -b html -d $(SPHINXBUILDDIR)/doctrees $(ALLSPHINXOPTS) $(SPHINXBUILDDIR)/html

install-html-local:
	$(INSTALL) -d $(DESTDIR)/$(docdir) $(DESTDIR)/$(docdir)/_static
	$(INSTALL) -D $(SPHINXBUILDDIR)/html/*.html $(DESTDIR)/$(docdir)/
	cp -R $(SPHINXBUILDDIR)/html/_static/ $(DESTDIR)/$(docdir)/_static/

singlehtml:
	$(AM_V_SPHINX)$(SPHINX_BUILD) -b singlehtml -d $(SPHINXBUILDDIR)/doctrees $(ALLSPHINXOPTS) $(SPHINXBUILDDIR)/singlehtml

install-singlehtml: singlehtml
	$(INSTALL) -d $(DESTDIR)/$(docdir) $(DESTDIR)/$(docdir)/_static
	$(INSTALL_DATA) $(SPHINXBUILDDIR)/singlehtml/*.html $(DESTDIR)/$(docdir)/
	cp -R $(SPHINXBUILDDIR)/singlehtml/_static/* $(DESTDIR)/$(docdir)/_static/

epub:
	$(AM_V_SPHINX)$(SPHINX_BUILD) -b epub -A today=$(RELEASE_DATE) -d $(SPHINXBUILDDIR)/doctrees $(ALLSPHINXOPTS) $(SPHINXBUILDDIR)/epub

install-epub:
	$(INSTALL) -d $(DESTDIR)/$(docdir)
	$(INSTALL_DATA) $(SPHINXBUILDDIR)/epub/*.epub $(DESTDIR)/$(docdir)/

if HAVE_XELATEX
pdf-local:
	$(AM_V_SPHINX)$(SPHINX_BUILD) -b latex -d $(SPHINXBUILDDIR)/doctrees $(ALLSPHINXOPTS) $(SPHINXBUILDDIR)/latex
	$(MAKE) -C $(SPHINXBUILDDIR)/latex all-pdf

install-pdf-local:
	$(INSTALL) -d $(DESTDIR)/$(docdir)
	$(INSTALL_DATA) $(SPHINXBUILDDIR)/latex/*.pdf $(DESTDIR)/$(docdir)/
endif

clean-local:
	-rm -rf $(SPHINXBUILDDIR)

doc-local: html singlehtml pdf epub

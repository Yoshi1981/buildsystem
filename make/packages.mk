#
# drivers pkgs
#

#
# contrib-apps pkgs
#

#
# contrib-libs pkgs
#

#
# gstreamer-pkg
#
gstreamer-pkg: $(D)/bootstrap $(D)/libglib2 $(D)/libxml2 $(D)/glib_networking $(ARCHIVE)/$(GSTREAMER_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/gstreamer-$(GSTREAMER_VER)
	$(UNTAR)/$(GSTREAMER_SOURCE)
	$(CHDIR)/gstreamer-$(GSTREAMER_VER); \
		$(call apply_patches, $(GSTREAMER_PATCH)); \
		./autogen.sh --noconfigure $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--datarootdir=/.remove \
			--enable-silent-rules \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-tests \
			--disable-valgrind \
			--disable-gst-tracer-hooks \
			--disable-dependency-tracking \
			--disable-examples \
			--disable-check \
			$(GST_MAIN_CONFIG_DEBUG) \
			--disable-benchmarks \
			--disable-gtk-doc-html \
			ac_cv_header_valgrind_valgrind_h=no \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/gstreamer-$(GSTREAMER_VER)
	cp -R $(PACKAGES)/gstreamer/* $(PKGPREFIX)/
	cd $(PKGPREFIX) && \
	tar -cvzf $(PKGS_DIR)/gstreamer.tgz *
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# apps-tools pkgs
#

#
# apps-libs
#

#
# neutrino-pkg
#
$(PKGPREFIX)/.version:
	echo "distro=$(MAINTAINER)" > $@
	echo "imagename=`sed -n 's/\#define PACKAGE_NAME "//p' $(N_OBJDIR)/config.h | sed 's/"//'`" >> $@
	echo "imageversion=`sed -n 's/\#define PACKAGE_VERSION "//p' $(N_OBJDIR)/config.h | sed 's/"//'`" >> $@
	echo "homepage=https://github.com/Duckbox-Developers" >> $@
	echo "creator=$(MAINTAINER)" >> $@
	echo "docs=https://github.com/Duckbox-Developers" >> $@
	echo "forum=https://github.com/Duckbox-Developers/neutrino-ddt" >> $@
	echo "version=0200`date +%Y%m%d%H%M`" >> $@
	echo "git=`git log | grep "^commit" | wc -l`" >> $@
	
$(D)/neutrino-pkg: $(D)/neutrino.do_prepare $(D)/neutrino.do_compile
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(PKGPREFIX); \
	rm -f $(PKGPREFIX)/.version
	make $(PKGPREFIX)/.version
	cp -R $(PACKAGES)/neutrino/* $(PKGPREFIX)/
	cd $(PKGPREFIX) && \
	tar -cvzf $(PKGS_DIR)/neutrino.tgz *
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	

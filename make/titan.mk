#
# titan
#
TITAN_DEPS  = $(D)/bootstrap
TITAN_DEPS += $(KERNEL)
TITAN_DEPS += $(D)/libopenthreads
TITAN_DEPS += $(D)/system-tools
TITAN_DEPS += $(D)/module_init_tools
TITAN_DEPS += $(LIRC)
TITAN_DEPS += $(D)/libpng
TITAN_DEPS += $(D)/freetype
TITAN_DEPS += $(D)/libjpeg
TITAN_DEPS += $(D)/zlib
TITAN_DEPS += $(D)/openssl
TITAN_DEPS += $(D)/timezone
TITAN_DEPS += $(D)/tools-libmme_host
TITAN_DEPS += $(D)/tools-libmme_image

ifeq ($(MEDIAFW), buildinplayer)
T_CONFIG_OPTS += --enable-eplayer3
TITAN_DEPS += $(D)/libcurl
TITAN_DEPS += $(D)/ffmpeg
endif

ifeq ($(MEDIAFW), gstreamer)
T_CONFIG_OPTS += --with-gstversion=1.0 --enable-mediafwgstreamer
TITAN_DEPS += $(D)/gstreamer $(D)/gst_plugins_base $(D)/gst_plugins_dvbmediasink
TITAN_DEPS += $(D)/gst_plugins_good $(D)/gst_plugins_bad $(D)/gst_plugins_ugly
endif

ifeq ($(WLAN), wlandriver)
TITAN_DEPS += $(D)/wpa_supplicant $(D)/wireless_tools
endif

ifeq ($(EXTERNAL_LCD), graphlcd)
T_CONFIG_OPTS += --with-graphlcd
TITAN_DEPS_ += $(D)/graphlcd
endif

ifeq ($(EXTERNAL_LCD), lcd4linux)
T_CONFIG_OPTS += --with-lcd4linux
TITAN_DEPS += $(D)/lcd4linux
endif

ifeq ($(EXTERNAL_LCD), both)
T_CONFIG_OPTS += --with-graphlcd
TITAN_DEPS += $(D)/graphlcd
T_CONFIG_OPTS += --with-lcd4linux
TITAN_DEPS += $(D)/lcd4linux
endif

T_CPPFLAGS   += -DDVDPLAYER
T_CPPFLAGS   += -Wno-unused-but-set-variable
T_CPPFLAGS   += -I$(DRIVER_DIR)/include
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/include
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/freetype2
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/openssl
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/libpng16
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/dreamdvd
T_CPPFLAGS   += -I$(KERNEL_DIR)/include
T_CPPFLAGS   += -I$(DRIVER_DIR)/bpamem
T_CPPFLAGS   += -I$(APPS_DIR)/tools
T_CPPFLAGS   += -I$(APPS_DIR)/tools/libmme_image
T_CPPFLAGS   += -L$(TARGET_DIR)/usr/lib
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/python
T_CPPFLAGS   += -L$(SOURCE_DIR)/titan/libipkg

ifeq ($(MEDIAFW), buildinplayer)
T_CPPFLAGS   += -DEPLAYER3
T_CPPFLAGS   += -DEXTEPLAYER3
T_CPPFLAGS   += -I$(SOURCE_DIR)/titan/libeplayer3/include
T_CPPFLAGS   += -I$(SOURCE_DIR)/titan/libeplayer3/include/external
endif

ifeq ($(MEDIAFW), gstreamer)
T_CPPFLAGS   += -DEPLAYER4
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/gstreamer-1.0
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/glib-2.0
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/include/libxml2
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/lib/gstreamer-1.0/include
T_CPPFLAGS   += -I$(TARGET_DIR)/usr/lib/gstreamer-1.0/include
T_CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
T_CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
T_CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
T_CPPFLAGS   += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
T_CPPFLAGS   += -I$(SOURCE_DIR)/titan/libeplayer3/include
T_CPPFLAGS   += -I$(SOURCE_DIR)/titan/libeplayer3/include/external
endif

#
# titan
#
TITAN_PATCH = titan.patch

$(D)/titan.do_prepare: $(TITAN_DEPS)
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/titan
	[ -d "$(ARCHIVE)/titan.svn" ] && \
	(cd $(ARCHIVE)/titan.svn; svn up;); \
	[ -d "$(ARCHIVE)/titan.svn" ] || \
	svn checkout --username=public --password=public http://sbnc.dyndns.tv/svn/titan/ $(ARCHIVE)/titan.svn; \
	cp -ra $(ARCHIVE)/titan.svn $(SOURCE_DIR)/titan; \
	set -e; cd $(SOURCE_DIR)/titan; \
		$(call apply_patches, $(TITAN_PATCH))
	@touch $@

$(SOURCE_DIR)/titan/config.status:
	$(SILENT)cd $(SOURCE_DIR)/titan; \
		echo "Configuring titan..."; \
		./autogen.sh $(SILENT_OPT); \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(T_CONFIG_OPTS) \
			--datadir=/usr/local/share \
			--libdir=/usr/lib \
			--bindir=/usr/local/bin \
			--prefix=/usr \
			--sysconfdir=/etc \
			--with-boxtype=$(BOXTYPE) \
			--with-boxmodel=$(BOXTYPE) \
			--enable-multicom324 \
			PKG_CONFIG=$(PKG_CONFIG) \
			CPPFLAGS="$(T_CPPFLAGS)"

$(D)/titan.do_compile: $(SOURCE_DIR)/titan/config.status $(D)/titan-libipkg $(D)/titan-libdreamdvd $(D)/titan-libeplayer3
	$(SILENT)cd $(SOURCE_DIR)/titan; \
		$(MAKE) all
	@touch $@

$(D)/titan: $(D)/titan.do_prepare $(D)/titan.do_compile
	$(MAKE) -C $(SOURCE_DIR)/titan install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# titan-plugins
#
$(SOURCE_DIR)/titan/plugins/config.status: $(D)/titan.do_prepare $(D)/python
#$(D)/titan-plugins: $(D)/titan.do_prepare $(D)/python
	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/plugins; \
		./autogen.sh $(SILENT_OPT); \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(T_CONFIG_OPTS) \
			--datadir=/usr/local/share \
			--libdir=/usr/lib \
			--bindir=/usr/local/bin \
			--prefix=/usr \
			--sysconfdir=/etc \
			--enable-multicom324 \
			PKG_CONFIG=$(PKG_CONFIG) \
			CPPFLAGS="$(T_CPPFLAGS)"
#		$(MAKE) all
#		$(MAKE) -C $(SOURCE_DIR)/titan/plugins all install DESTDIR=$(TARGET_DIR)
#		$(TOUCH)		

$(D)/titan-plugins.do_compile: $(SOURCE_DIR)/titan/plugins/config.status
	$(SILENT)cd $(SOURCE_DIR)/titan/plugins; \
		$(MAKE) all
	@touch $@

$(D)/titan-plugins: $(D)/titan-plugins.do_compile
#	$(START_BUILD)
	$(SILENT)cd $(SOURCE_DIR)/titan/plugins
#	$(MAKE) -C $(SOURCE_DIR)/titan/plugins all install DESTDIR=$(TARGET_DIR)
#	$(SILENT)echo " done."
#	$(SILENT)echo
	$(TOUCH)

#
# titan-libipkg
#
TITAN_LIBIPKG_PATCH =
$(D)/titan-libipkg: $(D)/titan.do_prepare
	$(START_BUILD)
	$(SILENT)cd $(SOURCE_DIR)/titan/libipkg; \
	aclocal $(ACLOCAL_FLAGS); \
	libtoolize --automake -f -c; \
	autoconf; \
	autoheader; \
	automake --add-missing; \
	$(call apply_patches, $(TITAN_LIBIPKG_PATCH)); \
	./configure $(SILENT_CONFIGURE) \
		--build=$(BUILD) \
		--host=$(TARGET) \
		$(T_CONFIG_OPTS) \
		--datadir=/usr/local/share \
		--libdir=/usr/lib \
		--bindir=/usr/local/bin \
		--prefix=/usr \
		--sysconfdir=/etc \
		PKG_CONFIG=$(PKG_CONFIG) \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
		cp $(SOURCE_DIR)/titan/libipkg/libipkg.pc $(TARGET_LIB_DIR)/pkgconfig
		$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libipkg.pc
	$(TOUCH)

#
# titan-libdreamdvd
#
$(D)/titan-libdreamdvd: $(D)/titan.do_prepare $(D)/libdvdnav
	$(START_BUILD)
	export PATH=$(hostprefix)/bin:$(PATH) && \
	cd $(SOURCE_DIR)/titan/libdreamdvd && \
		./autogen.sh; \
		libtoolize --force && \
		aclocal -I $(TARGET_DIR)/usr/share/aclocal && \
		autoconf && \
		automake --foreign --add-missing && \
		$(BUILDENV) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/ \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libdreamdvd.pc
	$(REWRITE_LIBTOOL)/libdreamdvd.la
	$(TOUCH)

titan-libdreamdvd-clean:
	rm -f $(D)/titan-libdreamdvd
	cd $(SOURCE_DIR)/titan/libdreamdvd && \
		$(MAKE) clean

titan-libdreamdvd-distclean:
	rm -f $(D)/titan-libdreamdvd*
	rm -rf $(SOURCE_DIR)/titan/libdreamdvd

#
# titan-libeplayer3
#	
TITAN_LIBEPLAYER3_PATCH =
$(D)/titan-libeplayer3: $(D)/titan.do_prepare
	$(START_BUILD)
	$(SILENT)cd $(SOURCE_DIR)/titan/libeplayer3; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
#
#
titan-clean:
	rm -f $(D)/titan
	rm -f $(D)/titan.do_compile
	cd $(SOURCE_DIR)/titan; \
		$(MAKE) distclean

titan-distclean:
	rm -f $(D)/titan
	rm -f $(D)/titan.do_compile
	rm -f $(D)/titan.do_prepare
	rm -rf $(SOURCE_DIR)/titan
	rm -rf $(SOURCE_DIR)/titan.org

#
#
#
titan-plugins-clean:
	$(SILENT)rm -f $(D)/titan-plugins

titan-plugins-distclean:
	$(SILENT)rm -f $(D)/titan-plugins
		
#
# release-TITAN
#
release-TITAN: release-NONE $(D)/titan
	cp -af $(TARGET_DIR)/usr/local/bin $(RELEASE_DIR)/usr/local/
	cp -aR $(SOURCE_DIR)/titan/skins/0acht5zehn $(RELEASE_DIR)/usr/local/share/skins
	
#
# lib usr/lib
#
	cp -R $(TARGET_DIR)/lib/* $(RELEASE_DIR)/lib/
	rm -f $(RELEASE_DIR)/lib/*.{a,o,la}
	chmod 755 $(RELEASE_DIR)/lib/*

	cp -R $(TARGET_DIR)/usr/lib/* $(RELEASE_DIR)/usr/lib/

	rm -rf $(RELEASE_DIR)/usr/lib/{engines,gconv,libxslt-plugins,pkgconfig,sigc++-2.0,python*,lua}
	rm -f $(RELEASE_DIR)/usr/lib/*.{a,o,la}

	chmod 755 $(RELEASE_DIR)/usr/lib/*
	
#
# delete unnecessary files
#
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), ufs910 ufs922))
	rm -f $(RELEASE_DIR)/sbin/jfs_fsck
	rm -f $(RELEASE_DIR)/sbin/fsck.jfs
	rm -f $(RELEASE_DIR)/sbin/jfs_mkfs
	rm -f $(RELEASE_DIR)/sbin/mkfs.jfs
	rm -f $(RELEASE_DIR)/sbin/jfs_tune
	rm -f $(RELEASE_DIR)/etc/ssl/certs/ca-certificates.crt
endif
	rm -rf $(RELEASE_DIR)/lib/autofs
	rm -f $(RELEASE_DIR)/lib/libSegFault*
	rm -f $(RELEASE_DIR)/lib/libstdc++.*-gdb.py
	rm -f $(RELEASE_DIR)/lib/libthread_db*
	rm -f $(RELEASE_DIR)/lib/libanl*
	rm -rf $(RELEASE_DIR)/lib/modules/$(KERNEL_VER)
	rm -rf $(RELEASE_DIR)/usr/lib/alsa
	rm -rf $(RELEASE_DIR)/usr/lib/glib-2.0
	rm -rf $(RELEASE_DIR)/usr/lib/cmake
	rm -f $(RELEASE_DIR)/usr/lib/*.py
	rm -f $(RELEASE_DIR)/usr/lib/libc.so
	rm -f $(RELEASE_DIR)/usr/lib/xml2Conf.sh
	rm -f $(RELEASE_DIR)/usr/lib/libfontconfig*
	rm -f $(RELEASE_DIR)/usr/lib/libdvdcss*
	rm -f $(RELEASE_DIR)/usr/lib/libdvdnav*
	rm -f $(RELEASE_DIR)/usr/lib/libdvdread*
	rm -f $(RELEASE_DIR)/usr/lib/libcurses.so
	[ ! -e $(RELEASE_DIR)/usr/bin/mc ] && rm -f $(RELEASE_DIR)/usr/lib/libncurses* || true
	rm -f $(RELEASE_DIR)/usr/lib/libthread_db*
	rm -f $(RELEASE_DIR)/usr/lib/libanl*
	rm -f $(RELEASE_DIR)/usr/lib/libopkg*
	rm -f $(RELEASE_DIR)/bin/gitVCInfo
	rm -f $(RELEASE_DIR)/bin/evtest
	rm -f $(RELEASE_DIR)/bin/meta
	rm -f $(RELEASE_DIR)/bin/streamproxy
	rm -f $(RELEASE_DIR)/bin/libstb-hal-test
	rm -f $(RELEASE_DIR)/sbin/ldconfig
	rm -f $(RELEASE_DIR)/usr/bin/pic2m2v
	rm -f $(RELEASE_DIR)/usr/bin/{gdbus-codegen,glib-*,gtester-report}
ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mips))
	rm -rf $(RELEASE_DIR)/dev.static
	rm -rf $(RELEASE_DIR)/ram
	rm -rf $(RELEASE_DIR)/root
endif	
	
#
#
#
#PHONY += $(TARGET_DIR)/.version




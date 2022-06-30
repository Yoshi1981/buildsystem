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
TITAN_DEPS += $(D)/gstreamer $(D)/gst_plugins_base $(D)/gst_plugins_dvbmediasink
TITAN_DEPS += $(D)/gst_plugins_good $(D)/gst_plugins_bad $(D)/gst_plugins_ugly
endif

ifeq ($(WLAN), wlandriver)
TITAN_DEPS += $(D)/wpa_supplicant $(D)/wireless_tools
endif

ifeq ($(GRAPHLCD), graphlcd)
T_CONFIG_OPTS += --with-graphlcd
TITAN_DEPS_ += $(D)/graphlcd
endif

ifeq ($(LCD4LINUX), lcd4linux)
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

ifeq ($(BOXARCH), sh4)
T_CPPFLAGS   += -DSH4
else
T_CPPFLAGS   += -DMIPSEL
endif

#
#
#
MACHINE := $(BOXTYPE)
ifeq ($(BOXARCH), mips)
MACHINE = vuduo
endif

#
# titan
#
TITAN_PATCH = titan.patch titan-Makefile.patch

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

$(D)/titan.config.status: $(D)/titan.do_prepare
	cd $(SOURCE_DIR)/titan; \
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
			--with-boxtype=$(MACHINE) \
			--enable-multicom324 \
			PKG_CONFIG=$(PKG_CONFIG) \
			CPPFLAGS="$(T_CPPFLAGS)"
	@touch $@

$(D)/titan.do_compile: $(D)/titan.config.status $(D)/titan-libipkg $(D)/titan-libdreamdvd $(D)/titan-libeplayer3
	cd $(SOURCE_DIR)/titan; \
		$(MAKE) all
	@touch $@

$(D)/titan: $(D)/titan.do_compile
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
	cd $(SOURCE_DIR)/titan/plugins; \
		$(MAKE) all
	@touch $@

$(D)/titan-plugins: $(D)/titan-plugins.do_compile
#	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/plugins
#	$(MAKE) -C $(SOURCE_DIR)/titan/plugins all install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# titan-libipkg
#
TITAN_LIBIPKG_PATCH =
$(D)/titan-libipkg: $(D)/titan.do_prepare
	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/libipkg; \
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
	$(TOUCH)

#
# titan-libeplayer3
#	
TITAN_LIBEPLAYER3_PATCH =
$(D)/titan-libeplayer3: $(D)/titan.do_prepare
	$(START_BUILD)
	cd $(SOURCE_DIR)/titan/libeplayer3; \
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
	$(MAKE) -C $(SOURCE_DIR)/titan clean

titan-distclean:
	$(MAKE) -C $(SOURCE_DIR)/titan distclean
	rm -rf $(SOURCE_DIR)/titan config.status
	rm -f $(D)/titan*

#
#
#
titan-plugins-clean:
	rm -f $(D)/titan-plugins
	cd $(SOURCE_DIR)/titan/plugins; \
		$(MAKE) distclean

titan-plugins-distclean:
	rm -f $(D)/titan-plugins
		
#
# release-TITAN
#
release-TITAN: release-NONE $(D)/titan
	cp -af $(TARGET_DIR)/usr/local/bin $(RELEASE_DIR)/usr/local/
	cp -aR $(SOURCE_DIR)/titan/skins/default $(RELEASE_DIR)/var/usr/local/share/titan/skin
	cp -af $(SKEL_ROOT)/var/etc/titan $(RELEASE_DIR)/var/etc/
	cp -af $(SKEL_ROOT)/var/usr/share/fonts $(RELEASE_DIR)/var/usr/share
	
#
#
#
#PHONY += $(TARGET_DIR)/.version




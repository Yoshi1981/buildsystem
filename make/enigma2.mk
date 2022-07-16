#
# ENIGMA2
#
ENIGMA2_DEPS  = $(D)/bootstrap
ENIGMA2_DEPS += $(D)/opkg
ENIGMA2_DEPS += $(D)/ncurses
ENIGMA2_DEPS += $(D)/module_init_tools
ENIGMA2_DEPS += $(LIRC)
ENIGMA2_DEPS += $(D)/libpng
ENIGMA2_DEPS += $(D)/libjpeg
ENIGMA2_DEPS += $(D)/giflib
ENIGMA2_DEPS += $(D)/libfribidi
ENIGMA2_DEPS += $(D)/libglib2
ENIGMA2_DEPS += $(D)/libdvbsi
ENIGMA2_DEPS += $(D)/libxml2
ENIGMA2_DEPS += $(D)/openssl
ENIGMA2_DEPS += $(D)/tuxtxt32bpp
ENIGMA2_DEPS += $(D)/hotplug_e2_helper
ENIGMA2_DEPS += $(D)/avahi
ENIGMA2_DEPS += python
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), size))
ENIGMA2_DEPS += $(D)/ethtool
ENIGMA2_DEPS += $(D)/alsa_utils
ENIGMA2_DEPS += $(D)/libdreamdvd
ENIGMA2_DEPS += $(D)/libmad
ENIGMA2_DEPS += $(D)/libusb
ENIGMA2_DEPS += $(D)/libid3tag
ENIGMA2_DEPS += $(D)/minidlna
ENIGMA2_DEPS += $(D)/sdparm
ENIGMA2_DEPS += $(D)/parted 
endif

ifeq ($(WLAN), wlandriver)
ENIGMA2_DEPS += $(D)/wpa_supplicant $(D)/wireless_tools
endif

ENIGMA2_DEPS  += $(D)/libsigc

E2_CONFIG_OPTS =

#MEDIAFW = gstreamer
#ifeq ($(MEDIAFW), gstreamer)
#ENIGMA2_DEPS  += $(D)/gstreamer $(D)/gst_plugins_base $(D)/gst_plugins_dvbmediasink
#ENIGMA2_DEPS  += $(D)/gst_plugins_good $(D)/gst_plugins_bad $(D)/gst_plugins_ugly
#E2_CONFIG_OPTS += --with-gstversion=1.0
#endif

ifeq ($(EXTERNAL_LCD), graphlcd)
E2_CONFIG_OPTS += --with-graphlcd
ENIGMA2_DEPS_ += $(D)/graphlcd
endif

ifeq ($(EXTERNAL_LCD), lcd4linux)
E2_CONFIG_OPTS += --with-lcd4linux
ENIGMA2_DEPS += $(D)/lcd4linux
endif

ifeq ($(GRAPHLCD), graphlcd)
E2_CONFIG_OPTS += --with-graphlcd
ENIGMA2_DEPS_ += $(D)/graphlcd
endif

ifeq ($(LCD4LINUX), lcd4linux)
E2_CONFIG_OPTS += --with-lcd4linux
ENIGMA2_DEPS += $(D)/lcd4linux
endif

E2_CPPFLAGS    = -I$(DRIVER_DIR)/include
E2_CPPFLAGS   += -I$(TARGET_DIR)/usr/include
E2_CPPFLAGS   += -I$(KERNEL_DIR)/include
E2_CPPFLAGS   += -I$(APPS_DIR)/tools

ifeq ($(FLAVOUR), ENIGMA2)
PYTHON = python
LUA =
endif

E2_CONFIG_OPTS += PYTHON_CPPFLAGS="-I$(TARGET_DIR)/usr/include/python2.7" PYTHON_LIBS="-L$(TARGET_DIR)/usr/lib -lpython2.7" PYTHON_SITE_PKG="$(TARGET_DIR)/usr/lib/python2.7/site-packages"

ENIGMA2_PATCHES = enigma2.patch

#
# enigma2
#
$(D)/enigma2.do_prepare: $(ENIGMA2_DEPS)
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/enigma2
	[ -d "$(ARCHIVE)/enigma2.git" ] && \
	(cd $(ARCHIVE)/enigma2.git; git pull;); \
	[ -d "$(ARCHIVE)/enigma2.git" ] || \
	git clone -b 6.4 https://github.com/openatv/enigma2.git $(ARCHIVE)/enigma2.git; \
	cp -ra $(ARCHIVE)/enigma2.git $(SOURCE_DIR)/enigma2; \
	set -e; cd $(SOURCE_DIR)/enigma2; \
		$(call apply_patches,$(ENIGMA2_PATCHES))
	@touch $@

$(D)/enigma2.config.status: $(D)/enigma2.do_prepare
	cd $(SOURCE_DIR)/enigma2; \
		./autogen.sh $(SILENT_OPT); \
		sed -e 's|#!/usr/bin/python|#!$(HOST_DIR)/bin/python|' -i po/xml2po.py; \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(E2_CONFIG_OPTS) \
			--with-libsdl=no \
			--datadir=/usr/local/share \
			--libdir=/usr/lib \
			--bindir=/usr/local/bin \
			--prefix=/usr \
			--sysconfdir=/etc \
			--with-boxtype=$(BOXTYPE) \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			PY_PATH=$(TARGET_DIR)/usr \
			CPPFLAGS="$(E2_CPPFLAGS)"
	@touch $@

$(D)/enigma2.do_compile: $(D)/enigma2.config.status
	cd $(SOURCE_DIR)/enigma2; \
		$(MAKE) all
	@touch $@

$(D)/enigma2: $(D)/enigma2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/enigma2 install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

enigma2-clean:
	rm -f $()/enigma2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/enigma2 clean
	rm -f $(D)/enigma2

enigma2-distclean:
	rm -f $(D)/enigma2*
	$(MAKE) -C $(SOURCE_DIR)/enigma2 distclean
	
#
# release-ENIGMA2
#
release-ENIGMA2: release-NONE $(D)/enigma2
	cp -af $(TARGET_DIR)/usr/local/bin/enigma2 $(RELEASE_DIR)/usr/local/bin/enigma2
	cp -aR $(TARGET_DIR)/usr/local/share $(RELEASE_DIR)/usr/local
	cp -aR $(TARGET_DIR)/usr/lib/enigma2 $(RELEASE_DIR)/usr/lib
	cp -Rf $(TARGET_DIR)/usr/local/share/enigma2/po/en $(RELEASE_DIR)/usr/local/share/enigma2/po
	cp -Rf $(TARGET_DIR)/usr/local/share/enigma2/po/de $(RELEASE_DIR)/usr/local/share/enigma2/po
	cp -aR $(RELEASE_DIR)/usr/local/share/fonts $(RELEASE_DIR)/usr/share/
	cp -aR $(SKEL_ROOT)/usr/local/share/enigma2/* $(RELEASE_DIR)/usr/local/share/enigma2
		

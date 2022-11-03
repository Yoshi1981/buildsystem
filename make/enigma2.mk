#
# ENIGMA2
#
ENIGMA2_DEPS  = $(D)/bootstrap
ENIGMA2_DEPS += $(D)/opkg
ENIGMA2_DEPS += $(D)/ncurses
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
ENIGMA2_DEPS += $(D)/python
ENIGMA2_DEPS  += $(D)/libsigc
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

ENIGMA2_CONFIG_OPTS =

ifeq ($(GRAPHLCD), graphlcd)
ENIGMA2_CONFIG_OPTS += --with-graphlcd
ENIGMA2_DEPS_ += $(D)/graphlcd
endif

ifeq ($(LCD4LINUX), lcd4linux)
ENIGMA2_CONFIG_OPTS += --with-lcd4linux
ENIGMA2_DEPS += $(D)/lcd4linux
endif

ENIGMA2_CPPFLAGS   += -I$(KERNEL_DIR)/include
ENIGMA2_CPPFLAGS   += -I$(DRIVER_DIR)/include
ENIGMA2_CPPFLAGS   += -I$(TARGET_DIR)/usr/include
ENIGMA2_CPPFLAGS   += -I$(CROSS_DIR)/$(TARGET)/sys-root/usr/include
ENIGMA2_CPPFLAGS   += -I$(APPS_DIR)/tools

ifeq ($(GUI), ENIGMA2)
PYTHON = python
endif

ENIGMA2_CONFIG_OPTS += PYTHON_CPPFLAGS="-I$(TARGET_DIR)/usr/include/python2.7" PYTHON_LIBS="-L$(TARGET_DIR)/usr/lib -lpython2.7" PYTHON_SITE_PKG="$(TARGET_DIR)/usr/lib/python2.7/site-packages"

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
			$(ENIGMA2_CONFIG_OPTS) \
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
			CPPFLAGS="$(ENIGMA2_CPPFLAGS)"
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
# hotplug_e2_helper
#
HOTPLUG_E2_PATCH = hotplug-e2-helper.patch

$(D)/hotplug_e2_helper: $(D)/bootstrap
	$(START_BUILD)
	$(REMOVE)/hotplug-e2-helper
	$(SET) -e; if [ -d $(ARCHIVE)/hotplug-e2-helper.git ]; \
		then cd $(ARCHIVE)/hotplug-e2-helper.git; git pull $(MINUS_Q); \
		else cd $(ARCHIVE); git clone $(MINUS_Q) https://github.com/OpenPLi/hotplug-e2-helper.git hotplug-e2-helper.git; \
		fi
	$(SILENT)cp -ra $(ARCHIVE)/hotplug-e2-helper.git $(BUILD_TMP)/hotplug-e2-helper
	$(SET) -e; cd $(BUILD_TMP)/hotplug-e2-helper; \
		$(call apply_patches,$(HOTPLUG_E2_PATCH)); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install prefix=/usr DESTDIR=$(TARGET_DIR)
	$(REMOVE)/hotplug-e2-helper
	$(TOUCH)

#
# tuxtxtlib
#
TUXTXTLIB_PATCH = tuxtxtlib-1.0-fix-dbox-headers.patch tuxtxtlib-fix-found-dvbversion.patch

$(D)/tuxtxtlib: $(D)/bootstrap $(D)/freetype
	$(START_BUILD)
	$(REMOVE)/tuxtxtlib
	$(SILENT)if [ -d $(ARCHIVE)/tuxtxt.git ]; \
		then cd $(ARCHIVE)/tuxtxt.git; git pull $(MINUS_Q); \
		else cd $(ARCHIVE); git clone $(MINUS_Q) https://github.com/OpenPLi/tuxtxt.git tuxtxt.git; \
		fi
	$(SILENT)cp -ra $(ARCHIVE)/tuxtxt.git/libtuxtxt $(BUILD_TMP)/tuxtxtlib
	$(SILENT)cd $(BUILD_TMP)/tuxtxtlib; \
		$(call apply_patches,$(TUXTXTLIB_PATCH)); \
		aclocal; \
		autoheader; \
		autoconf; \
		libtoolize --force $(SILENT_OPT); \
		automake --foreign --add-missing; \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--with-boxtype=generic \
			--with-configdir=/etc \
			--with-datadir=/usr/share/tuxtxt \
			--with-fontdir=/usr/share/fonts \
		; \
		$(MAKE) all; \
		$(MAKE) install prefix=/usr DESTDIR=$(TARGET_DIR)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/tuxbox-tuxtxt.pc
	$(REWRITE_LIBTOOL)/libtuxtxt.la
	$(REMOVE)/tuxtxtlib
	$(TOUCH)

#
# tuxtxt32bpp
#
TUXTXT32BPP_PATCH = tuxtxt32bpp-1.0-fix-dbox-headers.patch tuxtxt32bpp-fix-found-dvbversion.patch

$(D)/tuxtxt32bpp: $(D)/bootstrap $(D)/tuxtxtlib
	$(START_BUILD)
	$(REMOVE)/tuxtxt
	$(SILENT)cp -ra $(ARCHIVE)/tuxtxt.git/tuxtxt $(BUILD_TMP)/tuxtxt
	$(SET) -e; cd $(BUILD_TMP)/tuxtxt; \
		$(call apply_patches,$(TUXTXT32BPP_PATCH)); \
		aclocal; \
		autoheader; \
		autoconf; \
		libtoolize --force $(SILENT_OPT); \
		automake --foreign --add-missing; \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--with-fbdev=/dev/fb0 \
			--with-boxtype=generic \
			--with-configdir=/etc \
			--with-datadir=/usr/share/tuxtxt \
			--with-fontdir=/usr/share/fonts \
		; \
		$(MAKE) all; \
		$(MAKE) install prefix=/usr DESTDIR=$(TARGET_DIR)
	$(REWRITE_LIBTOOL)/libtuxtxt32bpp.la
	$(REMOVE)/tuxtxt
	$(TOUCH)
	
#
# release-ENIGMA2
#
release-ENIGMA2: release-NONE $(D)/enigma2
	cp -af $(TARGET_DIR)/usr/local/bin/enigma2 $(RELEASE_DIR)/usr/local/bin/enigma2
	cp -aR $(TARGET_DIR)/usr/local/share/enigma2 $(RELEASE_DIR)/usr/local/share
	cp -aR $(TARGET_DIR)/usr/local/share/keymaps $(RELEASE_DIR)/usr/local/share
	cp -aR $(TARGET_DIR)/usr/local/share/meta $(RELEASE_DIR)/usr/local/share
	cp -aR $(TARGET_DIR)/usr/local/share/fonts $(RELEASE_DIR)/usr/share
	cp -aR $(TARGET_DIR)/usr/lib/enigma2 $(RELEASE_DIR)/usr/lib
	cp -Rf $(TARGET_DIR)/usr/local/share/enigma2/po/en $(RELEASE_DIR)/usr/local/share/enigma2/po
	cp -Rf $(TARGET_DIR)/usr/local/share/enigma2/po/de $(RELEASE_DIR)/usr/local/share/enigma2/po
	cp -aR $(SKEL_ROOT)/usr/local/share/enigma2/* $(RELEASE_DIR)/usr/local/share/enigma2
		

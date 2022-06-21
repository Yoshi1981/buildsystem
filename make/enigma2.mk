#
# enigma2
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
ENIGMA2_DEPS += python-all
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), small))
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
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), small size))
# required for DVDBurn plugin (adds ? Mbyte to image)
#ENIGMA2_DEPS += $(D)/dvd+rw-tools $(D)/dvdauthor $(D)/mjpegtools $(D)/cdrkit $(D)/replex $(D)/python_imaging
endif
ifeq ($(IMAGE), enigma2-wlandriver)
ENIGMA2_DEPS += $(D)/wpa_supplicant $(D)/wireless_tools
endif

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), hs7110 hs7119 hs7420 hs7429 hs7810a hs7819 opt9600 opt9600mini opt9600prima vitamin_hd5000))
ifeq ($(DESTINATION), USB)
E_CONFIG_OPTS += --enable-run_from_usb
endif
endif

# determine libsigc++ version
#ifeq ($(E2_DIFF), $(filter $(E2_DIFF), 1))
#ENIGMA2_DEPS  += $(D)/libsigc_e2
#else
ENIGMA2_DEPS  += $(D)/libsigc
#endif

# determine requirements for media framework
# Note: for diffs 0, 2, 3, 4 & 5 there are no extra dependencies;
# these are part of enigma2-plugins
#ifeq ($(E2_DIFF), $(filter $(E2_DIFF), 1)) # diff 1 (local)
#ifeq ($(MEDIAFW), buildinplayer)
#ENIGMA2_DEPS  += $(D)/tools-libeplayer3
#E_CONFIG_OPTS += --enable-libeplayer3
#endif

#ifeq ($(MEDIAFW), gstreamer)
ENIGMA2_DEPS  += $(D)/gstreamer $(D)/gst_plugins_base $(D)/gst_plugins_dvbmediasink
ENIGMA2_DEPS  += $(D)/gst_plugins_good $(D)/gst_plugins_bad $(D)/gst_plugins_ugly
E_CONFIG_OPTS += --with-gstversion=1.0 --enable-mediafwgstreamer
#endif

#ifeq ($(MEDIAFW), gst-eplayer3)
#ENIGMA2_DEPS  += $(D)/tools-libeplayer3
#ENIGMA2_DEPS  += $(D)/gstreamer $(D)/gst_plugins_base $(D)/gst_plugins_dvbmediasink
#ENIGMA2_DEPS  += $(D)/gst_plugins_good $(D)/gst_plugins_bad $(D)/gst_plugins_ugly
#E_CONFIG_OPTS += --with-gstversion=1.0 --enable-mediafwgstreamer --enable-libeplayer3
#endif
#endif

ifeq ($(EXTERNAL_LCD), graphlcd)
E_CONFIG_OPTS += --with-graphlcd
ENIGMA2_DEPS_ += $(D)/graphlcd
endif

ifeq ($(EXTERNAL_LCD), lcd4linux)
E_CONFIG_OPTS += --with-lcd4linux
ENIGMA2_DEPS += $(D)/lcd4linux
endif

ifeq ($(EXTERNAL_LCD), both)
E_CONFIG_OPTS += --with-graphlcd
ENIGMA2_DEPS += $(D)/graphlcd
E_CONFIG_OPTS += --with-lcd4linux
ENIGMA2_DEPS += $(D)/lcd4linux
endif

#E_CONFIG_OPTS += --enable-$(BOXTYPE)

E_CONFIG_OPTS +=$(LOCAL_ENIGMA2_BUILD_OPTIONS)

E_CPPFLAGS    = -I$(DRIVER_DIR)/include
E_CPPFLAGS   += -I$(TARGET_DIR)/usr/include
E_CPPFLAGS   += -I$(KERNEL_DIR)/include
E_CPPFLAGS   += -I$(TOOLS_DIR)
ifeq ($(E2_DIFF), $(filter $(E2_DIFF), 1))
E_CPPFLAGS   += -I$(TOOLS_DIR)/libeplayer3/include
endif
E_CPPFLAGS   += $(LOCAL_ENIGMA2_CPPFLAGS)
E_CPPFLAGS   += $(PLATFORM_CPPFLAGS)

#ENIGMA2_PATCHES = enigma2.patch

#
# enigma2
#
$(D)/enigma2.do_prepare: | $(ENIGMA2_DEPS)
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

$(SOURCE_DIR)/enigma2/config.status:
	$(SILENT)cd $(SOURCE_DIR)/enigma2; \
		./autogen.sh $(SILENT_OPT); \
		sed -e 's|#!/usr/bin/python|#!$(HOST_DIR)/bin/python|' -i po/xml2po.py; \
		$(BUILDENV) \
		./configure $(SILENT_CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(E_CONFIG_OPTS) \
			--with-libsdl=no \
			--datadir=/usr/local/share \
			--libdir=/usr/lib \
			--bindir=/usr/local/bin \
			--prefix=/usr \
			--sysconfdir=/etc \
			--with-boxtype=$(BOXTYPE) \
			$(ENIGMA_OPT_OPTION) \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			PY_PATH=$(TARGET_DIR)/usr \
			CPPFLAGS="$(E_CPPFLAGS)"

$(D)/enigma2.do_compile: $(SOURCE_DIR)/enigma2/config.status
	$(SILENT)cd $(SOURCE_DIR)/enigma2; \
		$(MAKE) all
	@touch $@

PLI_SKIN_PATCH = PLi-HD_skin.patch
REPO_PLIHD="https://github.com/littlesat/skin-PLiHD.git"
HEAD=master
#REVISION_HD=8c9e43bd5b5fbec2d0e0e86d8e9d69a94f139054
REPO_0=$(REPO_PLIHD)
FW=$(MEDIAFW)
$(D)/enigma2: $(D)/enigma2.do_prepare $(D)/enigma2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/enigma2 install DESTDIR=$(TARGET_DIR)
	@echo -n "Stripping..."
	$(SILENT)if [ -e $(TARGET_DIR)/usr/bin/enigma2 ]; then \
		$(TARGET)-strip $(TARGET_DIR)/usr/bin/enigma2; \
	fi
	$(SILENT)if [ -e $(TARGET_DIR)/usr/local/bin/enigma2 ]; then \
		$(TARGET)-strip $(TARGET_DIR)/usr/local/bin/enigma2; \
	fi
	$(SILENT)echo " done."
	$(SILENT)echo
	$(SILENT)echo "Adding PLi-HD skin"
	$(SILENT)if [ ! -d $(ARCHIVE)/PLi-HD_skin.git ]; then \
		(echo -n "Cloning PLi-HD skin git..."; git clone -q -b $(HEAD) $(REPO_0) $(ARCHIVE)/PLi-HD_skin.git; echo " done."); \
	fi
#	$(SILENT)(cd $(ARCHIVE)/PLi-HD_skin.git; echo -n "Checkout commit $(REVISION_HD)..."; git checkout -q $(REVISION_HD); echo " done.")
	$(SILENT)cp -ra $(ARCHIVE)/PLi-HD_skin.git/usr/share/enigma2/* $(TARGET_DIR)/usr/local/share/enigma2
	@echo -e "$(TERM_RED)Applying Patch:$(TERM_NORMAL) $(PLI_SKIN_PATCH)"; $(PATCH)/$(PLI_SKIN_PATCH)
	@echo -e "Patching $(TERM_GREEN_BOLD)PLi-HD skin$(TERM_NORMAL) completed."
#ifneq ($(BOXTYPE), $(filter $(BOXTYPE), spark spark7162 cuberevo cuberevo_250hd cuberevo_mini_fta cuberevo_mini cuberevo_mini2 cuberevo_2000hd cuberevo3000hd cuberevo_9500hd fs9000 hs7110 hs7420 hs7810a hs7119 hs7429 hs7819 hs8200 hs9510 tf7700 ufs912 ufs913))
#	$(SILENT)rm -rf $(TARGET_DIR)/usr/local/share/enigma2/PLi-FullHD
#	$(SILENT)rm -rf $(TARGET_DIR)/usr/local/share/enigma2/PLi-FullNightHD
#endif
	$(TOUCH)

enigma2-clean:
	rm -f $(D)/enigma2
	rm -f $(D)/enigma2.do_compile
	cd $(SOURCE_DIR)/enigma2; \
		$(MAKE) distclean

enigma2-distclean:
	rm -f $(D)/enigma2
	rm -f $(D)/enigma2.do_compile
	rm -f $(D)/enigma2.do_prepare
	rm -rf $(SOURCE_DIR)/enigma2
	rm -rf $(SOURCE_DIR)/enigma2.org
	
#
# release-ENIGMA2
#
release-ENIGMA2: release-NONE $(D)/enigma2
	cp -af $(TARGET_DIR)/usr/local/bin $(RELEASE_DIR)/usr/local/
	cp -dp $(TARGET_DIR)/.version $(RELEASE_DIR)/
	cp -aR $(TARGET_DIR)/var/tuxbox/* $(RELEASE_DIR)/var/tuxbox
	cp -aR $(TARGET_DIR)/usr/share/tuxbox/* $(RELEASE_DIR)/usr/share/tuxbox
	
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
PHONY += $(TARGET_DIR)/.version

	

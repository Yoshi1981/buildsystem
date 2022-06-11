#
# Makefile to build NHD2
#
$(TARGET_DIR)/.version:
	echo "imagename=neutrino2" > $@
	echo "homepage=https://github.com/mohousch" >> $@
	echo "creator=$(MAINTAINER)" >> $@
	echo "docs=https://github.com/mohousch" >> $@
	echo "forum=https://github.com/mohousch/neutrino2" >> $@
	echo "version=0200`date +%Y%m%d%H%M`" >> $@
	echo "git=`git log | grep "^commit" | wc -l`" >> $@

#
# DEPS
#
NHD2_DEPS  = $(D)/bootstrap
NHD2_DEPS += $(D)/ncurses 
NHD2_DEPS += $(D)/libcurl
NHD2_DEPS += $(D)/libpng 
NHD2_DEPS += $(D)/libjpeg 
NHD2_DEPS += $(D)/giflib 
NHD2_DEPS += $(D)/freetype
NHD2_DEPS += $(D)/ffmpeg
NHD2_DEPS += $(D)/libfribidi
NHD2_DEPS += $(D)/libid3tag
NHD2_DEPS += $(D)/libmad
NHD2_DEPS += $(D)/libvorbisidec
NHD2_DEPS += $(D)/flac
NHD2_DEPS += $(D)/e2fsprogs
NHD2_DEPS += $(D)/libopenthreads

ifeq ($(PYTHON), python)
NHD2_DEPS += $(D)/python
endif

ifeq ($(LUA), lua)
NHD2_DEPS += $(D)/lua $(D)/luaexpat $(D)/luacurl $(D)/luasocket $(D)/luafeedparser $(D)/luasoap $(D)/luajson
endif

#
# CFLAGS / CPPFLAGS
#
NHD2_CFLAGS       = -Wall -W -Wshadow -pipe -Os
NHD2_CFLAGS      += -D__KERNEL_STRICT_NAMES
NHD2_CFLAGS      += -D__STDC_FORMAT_MACROS
NHD2_CFLAGS      += -D__STDC_CONSTANT_MACROS
NHD2_CFLAGS      += -fno-strict-aliasing -funsigned-char -ffunction-sections -fdata-sections

NHD2_CPPFLAGS     = -I$(TARGET_DIR)/usr/include
NHD2_CPPFLAGS    += -ffunction-sections -fdata-sections

ifeq ($(BOXARCH), arm)
NHD2_CPPFLAGS    += -I$(CROSS_DIR)/$(TARGET)/sys-root/usr/include
endif

ifeq ($(BOXARCH), sh4)
NHD2_CPPFLAGS    += -I$(DRIVER_DIR)/bpamem
NHD2_CPPFLAGS    += -I$(KERNEL_DIR)/include
endif

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), spark spark7162))
NHD2_CPPFLAGS += -I$(DRIVER_DIR)/frontcontroller/aotom_spark
endif

# MEDIAFW
MEDIAFW ?= gstreamer

ifeq ($(MEDIAFW), gstreamer)
NHD2_DEPS  += $(D)/gst_plugins_dvbmediasink
NHD2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
NHD2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
NHD2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
NHD2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
NHD2_OPTS += --enable-gstreamer --with-gstversion=1.0
endif

# python
PYTHON ?=

ifeq ($(PYTHON), python)
NHD2_OPTS += --enable-python PYTHON_CPPFLAGS="-I$(TARGET_DIR)/usr/include/python2.7" PYTHON_LIBS="-L$(TARGET_DIR)/usr/lib -lpython2.7" PYTHON_SITE_PKG="$(TARGET_DIR)/usr/lib/python2.7/site-packages"
endif

# lua
LUA ?= lua

ifeq ($(LUA), lua)
NHD2_OPTS += --enable-lua
endif

# CICAM
CICAM ?= ci-cam

ifeq ($(CICAM), ci-cam)
NHD2_OPTS += --enable-ci
endif

# SCART
SCART ?= scart

ifeq ($(SCART), scart)
NHD2_OPTS += --enable-scart
endif

# LCD 
LCD ?= vfd

ifeq ($(LCD), lcd)
NHD2_OPTS += --enable-lcd
endif

ifeq ($(LCD), 4-digits)
NHD2_OPTS += --enable-4digits
endif

# FKEYS
FKEY ?=

ifeq ($(FKEYS), fkeys)
NHD2_OPTS += --enable-functionkeys
endif

NHD2_PATCHES =

$(D)/neutrino2.do_prepare: $(NHD2_DEPS)
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/neutrino2
	[ -d "$(ARCHIVE)/neutrino2.git" ] && \
	(cd $(ARCHIVE)/neutrino2.git; git pull;); \
	[ -d "$(ARCHIVE)/neutrino2.git" ] || \
	git clone https://github.com/mohousch/neutrino2.git $(ARCHIVE)/neutrino2.git; \
	cp -ra $(ARCHIVE)/neutrino2.git $(SOURCE_DIR)/neutrino2; \
	set -e; cd $(SOURCE_DIR)/neutrino2/nhd2-exp; \
		$(call apply_patches,$(NHD2_PATCHES))
	@touch $@

$(D)/neutrino2.config.status: $(D)/neutrino2.do_prepare
	cd $(SOURCE_DIR)/neutrino2/nhd2-exp; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--enable-silent-rules \
			--enable-maintainer-mode \
			--with-boxtype=$(BOXTYPE) \
			$(NHD2_OPTS) \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CPPFLAGS="$(NHD2_CPPFLAGS)" LDFLAGS="$(TARGET_LDFLAGS)"
	@touch $@

$(D)/neutrino2.do_compile: $(D)/neutrino2.config.status
	cd $(SOURCE_DIR)/neutrino2/nhd2-exp; \
		$(MAKE) all
	@touch $@

$(D)/neutrino2: $(D)/neutrino2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/nhd2-exp install DESTDIR=$(TARGET_DIR)
	make $(TARGET_DIR)/.version
	touch $(D)/$(notdir $@)
	$(TUXBOX_CUSTOMIZE)

neutrino2-clean:
	rm -f $(D)/neutrino2
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/nhd2-exp clean

neutrino2-distclean:
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/nhd2-exp distclean
	rm -rf $(SOURCE_DIR)/neutrino2/nhd2-exp/config.status
	rm -f $(D)/neutrino2*
	
#
# neutrino2 plugins
#
NHD2_PLUGINS_PATCHES =

$(D)/neutrino2-plugins.do_prepare: $(D)/neutrino2.do_prepare
	$(START_BUILD)
	set -e; cd $(SOURCE_DIR)/neutrino2/plugins; \
		$(call apply_patches, $(NHD2_PLUGINS_PATCHES))
	@touch $@

$(D)/neutrino2-plugins.config.status: neutrino2
	cd $(SOURCE_DIR)/neutrino2/plugins; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure $(SILENT_OPT) \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--enable-silent-rules \
			--with-boxtype=$(BOXTYPE) \
			$(NHD2_OPTS) \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CPPFLAGS="$(CPPFLAGS) -I$(driverdir) -I$(KERNEL_DIR)/include -I$(TARGET_DIR)/include" \
			LDFLAGS="$(TARGET_LDFLAGS)"
	@touch $@

$(D)/neutrino2-plugins.do_compile: $(D)/neutrino2-plugins.config.status
	cd $(SOURCE_DIR)/neutrino2/plugins; \
	$(MAKE) top_srcdir=$(SOURCE_DIR)/neutrino2/nhd2-exp
	@touch $@

$(D)/neutrino2-plugins: $(D)/neutrino2-plugins.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins install DESTDIR=$(TARGET_DIR)
	touch $(D)/$(notdir $@)
	$(TUXBOX_CUSTOMIZE)

neutrino2-plugins-clean:
	rm -f $(D)/neutrino2-plugins
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins clean

neutrino2-plugins-distclean:
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins distclean
	rm -f $(SOURCE_DIR)/neutrino2/plugins/config.status
	rm -f $(D)/neutrino2-plugins*
	
#
# release-NHD2
#
release-NHD2: release-NONE $(D)/neutrino2 $(D)/neutrino2-plugins
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


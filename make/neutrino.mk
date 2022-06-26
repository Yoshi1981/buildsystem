#
# Makefile to build NEUTRINO
#
$(TARGET_DIR)/.version:
	echo "distro=$(FLAVOUR)" > $@
	echo "imagename=`sed -n 's/\#define PACKAGE_NAME "//p' $(N_OBJDIR)/config.h | sed 's/"//'`" >> $@
	echo "imageversion=`sed -n 's/\#define PACKAGE_VERSION "//p' $(N_OBJDIR)/config.h | sed 's/"//'`" >> $@
	echo "homepage=https://github.com/Duckbox-Developers" >> $@
	echo "creator=$(MAINTAINER)" >> $@
	echo "docs=https://github.com/Duckbox-Developers" >> $@
	echo "forum=https://github.com/Duckbox-Developers/neutrino-ddt" >> $@
	echo "version=0200`date +%Y%m%d%H%M`" >> $@
	echo "git=`git log | grep "^commit" | wc -l`" >> $@

NEUTRINO_DEPS  = $(D)/bootstrap 
NEUTRINO_DEPS += $(D)/ncurses 
NEUTRINO_DEPS += $(LIRC) 
NEUTRINO_DEPS += $(D)/libcurl
NEUTRINO_DEPS += $(D)/libpng 
NEUTRINO_DEPS += $(D)/libjpeg 
NEUTRINO_DEPS += $(D)/giflib 
NEUTRINO_DEPS += $(D)/freetype
NEUTRINO_DEPS += $(D)/alsa_utils 
NEUTRINO_DEPS += $(D)/ffmpeg
NEUTRINO_DEPS += $(D)/libfribidi 
NEUTRINO_DEPS += $(D)/libsigc 
NEUTRINO_DEPS += $(D)/libdvbsi 
NEUTRINO_DEPS += $(D)/libusb
NEUTRINO_DEPS += $(D)/pugixml 
NEUTRINO_DEPS += $(D)/libopenthreads
NEUTRINO_DEPS += $(D)/lua $(D)/luaexpat $(D)/luacurl $(D)/luasocket $(D)/luafeedparser $(D)/luasoap $(D)/luajson
#NEUTRINO_DEPS += $(LOCAL_NEUTRINO_DEPS)

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), atevio7500 spark spark7162 ufs912 ufs913 ufs910))
NEUTRINO_DEPS += $(D)/ntfs_3g
ifneq ($(BOXTYPE), $(filter $(BOXTYPE), ufs910))
NEUTRINO_DEPS += $(D)/mtd_utils $(D)/parted
endif
#NEUTRINO_DEPS +=  $(D)/minidlna
endif

ifeq ($(BOXARCH), arm)
NEUTRINO_DEPS += $(D)/gst_plugins_dvbmediasink
NEUTRINO_DEPS += $(D)/ntfs_3g
NEUTRINO_DEPS += $(D)/mc
endif

ifeq ($(WLAN), neutrino-wlandriver)
NEUTRINO_DEPS += $(D)/wpa_supplicant $(D)/wireless_tools
endif

NEUTRINO_DEPS2 = $(D)/libid3tag $(D)/libmad $(D)/flac

N_CFLAGS       = -Wall -W -Wshadow -pipe -Os
N_CFLAGS      += -D__KERNEL_STRICT_NAMES
N_CFLAGS      += -D__STDC_FORMAT_MACROS
N_CFLAGS      += -D__STDC_CONSTANT_MACROS
N_CFLAGS      += -fno-strict-aliasing -funsigned-char -ffunction-sections -fdata-sections
#N_CFLAGS      += -DCPU_FREQ
#N_CFLAGS      += $(LOCAL_NEUTRINO_CFLAGS)

N_CPPFLAGS     = -I$(TARGET_DIR)/usr/include
ifeq ($(BOXARCH), arm)
N_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
N_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
N_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
N_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
N_CPPFLAGS    += -I$(CROSS_BASE)/$(TARGET)/sys-root/usr/include
endif
ifeq ($(BOXARCH), sh4)
N_CPPFLAGS    += -I$(DRIVER_DIR)/bpamem
N_CPPFLAGS    += -I$(KERNEL_DIR)/include
endif
N_CPPFLAGS    += -ffunction-sections -fdata-sections

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), spark spark7162))
N_CPPFLAGS += -I$(DRIVER_DIR)/frontcontroller/aotom_spark
endif

N_CONFIG_OPTS  = $(LOCAL_NEUTRINO_BUILD_OPTIONS)
N_CONFIG_OPTS += --enable-freesatepg
N_CONFIG_OPTS += --enable-lua
N_CONFIG_OPTS += --enable-giflib
N_CONFIG_OPTS += --with-tremor
N_CONFIG_OPTS += --enable-ffmpegdec
#N_CONFIG_OPTS += --enable-pip
#N_CONFIG_OPTS += --disable-webif
#N_CONFIG_OPTS += --disable-upnp
#N_CONFIG_OPTS += --disable-tangos
N_CONFIG_OPTS += --enable-pugixml
ifeq ($(BOXARCH), arm)
N_CONFIG_OPTS += --enable-reschange
endif

#ifeq ($(EXTERNAL_LCD), both)
N_CONFIG_OPTS += --enable-graphlcd
NEUTRINO_DEPS += $(D)/graphlcd
N_CONFIG_OPTS += --enable-lcd4linux
NEUTRINO_DEPS += $(D)/lcd4linux
#endif

MACHINE := $(BOXTYPE)
ifeq ($(BOXARCH), arm)
MACHINE = hd51
endif
ifeq ($(BOXARCH), mips)
MACHINE = vuduo
endif

N_CONFIG_OPTS += \
	--with-boxtype=$(MACHINE) \
	--with-libdir=/usr/lib \
	--with-datadir=/usr/share/tuxbox \
	--with-fontdir=/usr/share/fonts \
	--with-configdir=/var/tuxbox/config \
	--with-gamesdir=/var/tuxbox/games \
	--with-iconsdir=/usr/share/tuxbox/neutrino/icons \
	--with-iconsdir_var=/var/tuxbox/icons \
	--with-luaplugindir=/var/tuxbox/plugins \
	--with-localedir=/usr/share/tuxbox/neutrino/locale \
	--with-localedir_var=/var/tuxbox/locale \
	--with-plugindir=/var/tuxbox/plugins \
	--with-plugindir_var=/var/tuxbox/plugins \
	--with-private_httpddir=/usr/share/tuxbox/neutrino/httpd \
	--with-public_httpddir=/var/tuxbox/httpd \
	--with-themesdir=/usr/share/tuxbox/neutrino/themes \
	--with-themesdir_var=/var/tuxbox/themes \
	--with-webtvdir=/share/tuxbox/neutrino/webtv \
	--with-webtvdir_var=/var/tuxbox/plugins/webtv \
	PKG_CONFIG=$(PKG_CONFIG) \
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)"


OBJDIR = $(BUILD_TMP)
N_OBJDIR = $(OBJDIR)/neutrino
LH_OBJDIR = $(OBJDIR)/libstb-hal

#
# DDT
#
NEUTRINO = neutrino-ddt
N_BRANCH = master
N_URL = https://github.com/Duckbox-Developers/neutrino-ddt.git
LIBSTB-HAL = libstb-hal-ddt
LH_BRANCH = master
HAL_URL = https://github.com/Duckbox-Developers/libstb-hal-ddt.git

#
# tuxbox
#
#NEUTRINO ?= gui-neutrino
#N_BRANCH ?= master
#N_URL ?= https://github.com/tuxbox-neutrino/$(NEUTRINO).git
#LIBSTB-HAL ?= library-stb-hal
#LH_BRANCH ?= mpx
#HAL_URL ?= https://github.com/tuxbox-neutrino/$(LIBSTB-HAL).git

#
#
#
#NEUTRINO = neutrino-tangos
#N_BRANCH = master
#N_URL = https://github.com/TangoCash/neutrino-tangos.git
#LIBSTB-HAL = libstb-hal-tangos
#LH_BRANCH = master
#HAL_URL = https://github.com/TangoCash/libstb-hal-tangos.git

#
# ni
#
#NEUTRINO = ni-neutrino
#N_BRANCH = master
#N_URL = https://github.com/neutrino-images/ni-neutrino.git
#LIBSTB-HAL = ni-libstb-hal
#LH_BRANCH = master
#HAL_URL = https://github.com/neutrino-images/ni-libstb-hal.git

#
# libstb-hal
#
LIBSTB_HAL_PATCHES =

$(D)/libstb-hal.do_prepare:
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/$(LIBSTB-HAL)
	rm -rf $(LH_OBJDIR)
	[ -d "$(ARCHIVE)/$(LIBSTB-HAL).git" ] && \
	(cd $(ARCHIVE)/$(LIBSTB-HAL).git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/$(LIBSTB-HAL).git" ] || \
	git clone $(HAL_URL) $(ARCHIVE)/$(LIBSTB-HAL).git; \
	cp -ra $(ARCHIVE)/$(LIBSTB-HAL).git $(SOURCE_DIR)/$(LIBSTB-HAL);\
	set -e; cd $(SOURCE_DIR)/$(LIBSTB-HAL); \
		$(call apply_patches,$(LIBSTB_HAL_PATCHES))
	@touch $@

$(D)/libstb-hal.config.status: | $(NEUTRINO_DEPS)
	rm -rf $(LH_OBJDIR); \
	test -d $(LH_OBJDIR) || mkdir -p $(LH_OBJDIR); \
	cd $(LH_OBJDIR); \
		$(SOURCE_DIR)/$(LIBSTB-HAL)/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/$(LIBSTB-HAL)/configure --enable-silent-rules \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			--with-target=cdk \
			--with-boxtype=$(MACHINE) \
			--enable-silent-rules \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)"
	@touch $@

$(D)/libstb-hal.do_compile: $(D)/libstb-hal.config.status
	cd $(SOURCE_DIR)/$(LIBSTB-HAL); \
		$(MAKE) -C $(LH_OBJDIR) all DESTDIR=$(TARGET_DIR)
	@touch $@

$(D)/libstb-hal: $(D)/libstb-hal.do_prepare $(D)/libstb-hal.do_compile
	$(MAKE) -C $(LH_OBJDIR) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

libstb-hal-clean:
	rm -f $(D)/libstb-hal
	rm -f $(D)/libstb-hal.config.status
	cd $(LH_OBJDIR); \
		$(MAKE) -C $(LH_OBJDIR) distclean

libstb-hal-distclean:
	rm -rf $(LH_OBJDIR)
	rm -f $(D)/libstb-hal*

#
# neutrino
#
NEUTRINO_PATCHES =

$(D)/neutrino.do_prepare: | $(NEUTRINO_DEPS) $(D)/libstb-hal
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/$(NEUTRINO)
	rm -rf $(N_OBJDIR)
	[ -d "$(ARCHIVE)/$(NEUTRINO).git" ] && \
	(cd $(ARCHIVE)/$(NEUTRINO).git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/$(NEUTRINO).git" ] || \
	git clone $(N_URL) $(ARCHIVE)/$(NEUTRINO).git; \
	cp -ra $(ARCHIVE)/$(NEUTRINO).git $(SOURCE_DIR)/$(NEUTRINO); \
	set -e; cd $(SOURCE_DIR)/$(NEUTRINO); \
		$(call apply_patches,$(NEUTRINO_PATCHES))
	@touch $@

$(D)/neutrino.config.status:
	rm -rf $(N_OBJDIR)
	test -d $(N_OBJDIR) || mkdir -p $(N_OBJDIR); \
	cd $(N_OBJDIR); \
		$(SOURCE_DIR)/$(NEUTRINO)/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/$(NEUTRINO)/configure --enable-silent-rules \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(N_CONFIG_OPTS) \
			--with-stb-hal-includes=$(SOURCE_DIR)/$(LIBSTB-HAL)/include \
			--with-stb-hal-build=$(LH_OBJDIR)
	@touch $@

$(SOURCE_DIR)/$(NEUTRINO)/src/gui/version.h:
	@rm -f $@; \
	echo '#define BUILT_DATE "'`date`'"' > $@
	@if test -d $(SOURCE_DIR)/$(LIBSTB-HAL) ; then \
		pushd $(SOURCE_DIR)/$(LIBSTB-HAL) ; \
		HAL_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(SOURCE_DIR)/$(NEUTRINO) ; \
		NMP_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(BASE_DIR) ; \
		DDT_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		echo '#define VCS "DDT-rev'$$DDT_REV'_HAL-rev'$$HAL_REV'_NMP-rev'$$NMP_REV'"' >> $@ ; \
	fi

$(D)/neutrino.do_compile: $(D)/neutrino.config.status $(SOURCE_DIR)/$(NEUTRINO)/src/gui/version.h
	cd $(SOURCE_DIR)/$(NEUTRINO); \
		$(MAKE) -C $(N_OBJDIR) all
	@touch $@

$(D)/neutrino: $(D)/neutrino.do_prepare $(D)/neutrino.do_compile
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(TARGET_DIR); \
	rm -f $(TARGET_DIR)/.version
	make $(TARGET_DIR)/.version
	$(TOUCH)

neutrino-clean:
	rm -f $(D)/neutrino
	rm -f $(D)/neutrino.config.status
	rm -f $(SOURCE_DIR)/$(NEUTRINO)/src/gui/version.h
	cd $(N_OBJDIR); \
		$(MAKE) -C $(N_OBJDIR) distclean

neutrino-distclean: libstb-hal-distclean
	rm -rf $(N_OBJDIR)
	rm -f $(D)/neutrino*

#
# neutrino-plugins
#
NEUTRINO_PLUGINS  = $(D)/neutrino-plugins
NEUTRINO_PLUGINS += $(D)/neutrino-plugins-scripts-lua
NEUTRINO_PLUGINS += $(D)/neutrino-plugins-mediathek
NEUTRINO_PLUGINS += $(D)/neutrino-plugins-xupnpd
NEUTRINO_PLUGINS_PATCHES =

NP_OBJDIR = $(BUILD_TMP)/neutrino-plugins

ifeq ($(BOXARCH), sh4)
EXTRA_CPPFLAGS_MP_PLUGINS = -DMARTII
endif

$(D)/neutrino-plugins.do_prepare:
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/neutrino-plugins
	set -e; if [ -d $(ARCHIVE)/neutrino-plugins.git ]; \
		then cd $(ARCHIVE)/neutrino-plugins.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/Duckbox-Developers/neutrino-ddt-plugins.git neutrino-plugins.git; \
		fi
	cp -ra $(ARCHIVE)/neutrino-plugins.git $(SOURCE_DIR)/neutrino-plugins
ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mips))
	sed -i -e 's#shellexec fx2#shellexec#g' $(SOURCE_DIR)/neutrino-plugins/Makefile.am
endif
	set -e; cd $(SOURCE_DIR)/neutrino-plugins; \
		$(call apply_patches, $(NEUTRINO_PLUGINS_PATCHES))
	@touch $@

$(D)/neutrino-plugins.config.status: $(D)/bootstrap
	rm -rf $(NP_OBJDIR); \
	test -d $(NP_OBJDIR) || mkdir -p $(NP_OBJDIR); \
	cd $(NP_OBJDIR); \
		$(SOURCE_DIR)/neutrino-plugins/autogen.sh $(SILENT_OPT) && automake --add-missing $(SILENT_OPT); \
		$(BUILDENV) \
		$(SOURCE_DIR)/neutrino-plugins/configure $(SILENT_OPT) \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			--enable-silent-rules \
			--with-target=cdk \
			--include=/usr/include \
			--enable-maintainer-mode \
			--with-boxtype=$(MACHINE) \
			--with-plugindir=/var/tuxbox/plugins \
			--with-libdir=/usr/lib \
			--with-datadir=/usr/share/tuxbox \
			--with-fontdir=/usr/share/fonts \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CPPFLAGS="$(N_CPPFLAGS) $(EXTRA_CPPFLAGS_MP_PLUGINS) -DNEW_LIBCURL" \
			LDFLAGS="$(TARGET_LDFLAGS) -L$(NP_OBJDIR)/fx2/lib/.libs"
	@touch $@

$(D)/neutrino-plugins.do_compile: $(D)/neutrino-plugins.config.status
	$(MAKE) -C $(NP_OBJDIR) DESTDIR=$(TARGET_DIR)
	@touch $@

$(D)/neutrino-plugins: $(D)/neutrino-plugins.do_prepare $(D)/neutrino-plugins.do_compile
	$(MAKE) -C $(NP_OBJDIR) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

neutrino-plugins-clean:
	rm -f $(D)/neutrino-plugins
	rm -f $(D)/neutrino-plugin
	rm -f $(D)/neutrino-plugin.config.status
	cd $(NP_OBJDIR); \
		$(MAKE) -C $(NP_OBJDIR) clean

neutrino-plugins-distclean:
	rm -rf $(NP_OBJDIR)
	rm -f $(D)/neutrino-plugin*

#
# neutrino-plugins-xupnpd
#
$(D)/neutrino-plugins-xupnpd: $(D)/xupnpd $(D)/lua $(D)/neutrino-plugins-scripts-lua
	rm $(TARGET_DIR)/usr/share/xupnpd/plugins/staff/xupnpd_18plus.lua
	install -m 644 $(ARCHIVE)/neutrino-plugin-scripts-lua.git/xupnpd/xupnpd_18plus.lua ${TARGET_DIR}/usr/share/xupnpd/plugins/
	install -m 644 $(ARCHIVE)/neutrino-plugin-scripts-lua.git/xupnpd/xupnpd_cczwei.lua ${TARGET_DIR}/usr/share/xupnpd/plugins/
	: install -m 644 $(ARCHIVE)/neutrino-plugin-scripts-lua.git/xupnpd/xupnpd_coolstream.lua ${TARGET_DIR}/usr/share/xupnpd/plugins/
	install -m 644 $(ARCHIVE)/neutrino-plugin-scripts-lua.git/xupnpd/xupnpd_youtube.lua ${TARGET_DIR}/usr/share/xupnpd/plugins/
	$(TOUCH)

#
# neutrino-plugins-scripts-lua
#
$(D)/neutrino-plugins-scripts-lua: $(D)/bootstrap
	$(START_BUILD)
	$(REMOVE)/neutrino-plugin-scripts-lua
	set -e; if [ -d $(ARCHIVE)/neutrino-plugin-scripts-lua.git ]; \
		then cd $(ARCHIVE)/neutrino-plugin-scripts-lua.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/Duckbox-Developers/plugin-scripts-lua.git neutrino-plugin-scripts-lua.git; \
		fi
	cp -ra $(ARCHIVE)/neutrino-plugin-scripts-lua.git/plugins $(BUILD_TMP)/neutrino-plugin-scripts-lua
	$(CHDIR)/neutrino-plugin-scripts-lua; \
		install -d $(TARGET_DIR)/var/tuxbox/plugins
#		cp -R $(BUILD_TMP)/neutrino-plugin-scripts-lua/favorites2bin/* $(TARGET_DIR)/var/tuxbox/plugins/
		cp -R $(BUILD_TMP)/neutrino-plugin-scripts-lua/ard_mediathek/* $(TARGET_DIR)/var/tuxbox/plugins/
		cp -R $(BUILD_TMP)/neutrino-plugin-scripts-lua/mtv/* $(TARGET_DIR)/var/tuxbox/plugins/
		cp -R $(BUILD_TMP)/neutrino-plugin-scripts-lua/netzkino/* $(TARGET_DIR)/var/tuxbox/plugins/
	$(REMOVE)/neutrino-plugin-scripts-lua
	$(TOUCH)
#
# neutrino-mediathek
#
$(D)/neutrino-plugins-mediathek:
	$(START_BUILD)
	$(REMOVE)/neutrino-plugins-mediathek
	set -e; if [ -d $(ARCHIVE)/neutrino-plugins-mediathek.git ]; \
		then cd $(ARCHIVE)/neutrino-plugins-mediathek.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/Duckbox-Developers/mediathek.git neutrino-plugins-mediathek.git; \
		fi
	cp -ra $(ARCHIVE)/neutrino-plugins-mediathek.git $(BUILD_TMP)/neutrino-plugins-mediathek
	install -d $(TARGET_DIR)/var/tuxbox/plugins
	$(CHDIR)/neutrino-plugins-mediathek; \
		cp -a plugins/* $(TARGET_DIR)/var/tuxbox/plugins/; \
#		cp -a share $(TARGET_DIR)/usr/
		rm -f $(TARGET_DIR)/var/tuxbox/plugins/neutrino-mediathek/livestream.lua
	$(REMOVE)/neutrino-plugins-mediathek
	$(TOUCH)
	
#
# release-NEUTRINO
#
release-NEUTRINO: release-NONE $(D)/neutrino $(D)/neutrino-plugins \
	$(D)/neutrino-plugins-scripts-lua $(D)/neutrino-plugins-mediathek $(D)/neutrino-plugins-xupnpd
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


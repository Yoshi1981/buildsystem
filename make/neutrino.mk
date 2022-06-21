#
# Makefile to build NEUTRINO
#
$(TARGET_DIR)/var/etc/.version:
	echo "imagename=Neutrino MP" > $@
	echo "homepage=https://github.com/Duckbox-Developers" >> $@
	echo "creator=$(MAINTAINER)" >> $@
	echo "docs=https://github.com/Duckbox-Developers" >> $@
	echo "forum=https://github.com/Duckbox-Developers/neutrino-mp-cst-next" >> $@
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

N_CONFIG_OPTS += \
	--with-boxtype=$(BOXTYPE) \
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
N_OBJDIR = $(OBJDIR)/neutrino-mp
LH_OBJDIR = $(OBJDIR)/libstb-hal

#
# libstb-hal-cst-next
#
NEUTRINO_MP_LIBSTB_CST_NEXT_PATCHES =

$(D)/libstb-hal-ddt.do_prepare:
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/libstb-hal-ddt
	rm -rf $(SOURCE_DIR)/libstb-hal-ddt.org
	rm -rf $(LH_OBJDIR)
	[ -d "$(ARCHIVE)/libstb-hal-ddt.git" ] && \
	(cd $(ARCHIVE)/libstb-hal-ddt.git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/libstb-hal-ddt.git" ] || \
	git clone https://github.com/Duckbox-Developers/libstb-hal-ddt.git $(ARCHIVE)/libstb-hal-ddt.git; \
	cp -ra $(ARCHIVE)/libstb-hal-ddt.git $(SOURCE_DIR)/libstb-hal-ddt;\
#	cp -ra $(SOURCE_DIR)/libstb-hal-ddt $(SOURCE_DIR)/libstb-hal-cst-next.org
	set -e; cd $(SOURCE_DIR)/libstb-hal-ddt; \
		$(call apply_patches,$(NEUTRINO_MP_LIBSTB_CST_NEXT_PATCHES))
	@touch $@

$(D)/libstb-hal-ddt.config.status: | $(NEUTRINO_DEPS)
	rm -rf $(LH_OBJDIR); \
	test -d $(LH_OBJDIR) || mkdir -p $(LH_OBJDIR); \
	cd $(LH_OBJDIR); \
		$(SOURCE_DIR)/libstb-hal-ddt/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/libstb-hal-ddt/configure --enable-silent-rules \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--prefix= \
			--with-target=cdk \
			--with-boxtype=$(BOXTYPE) \
			--enable-silent-rules \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)"
	@touch $@

$(D)/libstb-hal-ddt.do_compile: $(D)/libstb-hal-ddt.config.status
	cd $(SOURCE_DIR)/libstb-hal-ddt; \
		$(MAKE) -C $(LH_OBJDIR) all DESTDIR=$(TARGET_DIR)
	@touch $@

$(D)/libstb-hal-ddt: $(D)/libstb-hal-ddt.do_prepare $(D)/libstb-hal-ddt.do_compile
	$(MAKE) -C $(LH_OBJDIR) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

libstb-hal-ddt-clean:
	rm -f $(D)/libstb-hal-ddt
	rm -f $(D)/libstb-hal-ddt.config.status
	cd $(LH_OBJDIR); \
		$(MAKE) -C $(LH_OBJDIR) distclean

libstb-hal-ddt-distclean:
	rm -rf $(LH_OBJDIR)
	rm -f $(D)/libstb-hal-ddt*

#
# neutrino-ddt
#
NEUTRINO_MP_CST_NEXT_PATCHES =

$(D)/neutrino-ddt.do_prepare: | $(NEUTRINO_DEPS) $(D)/libstb-hal-ddt
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/neutrino-ddt
#	rm -rf $(SOURCE_DIR)/neutrino-mp-cst-next.org
	rm -rf $(N_OBJDIR)
	[ -d "$(ARCHIVE)/neutrino-ddt.git" ] && \
	(cd $(ARCHIVE)/neutrino-ddt.git; git pull; cd "$(BUILD_TMP)";); \
	[ -d "$(ARCHIVE)/neutrino-ddt.git" ] || \
	git clone https://github.com/Duckbox-Developers/neutrino-ddt.git $(ARCHIVE)/neutrino-ddt.git; \
	cp -ra $(ARCHIVE)/neutrino-ddt.git $(SOURCE_DIR)/neutrino-ddt; \
#	cp -ra $(SOURCE_DIR)/neutrino-mp-cst-next $(SOURCE_DIR)/neutrino-mp-cst-next.org
	set -e; cd $(SOURCE_DIR)/neutrino-ddt; \
		$(call apply_patches,$(NEUTRINO_MP_CST_NEXT_PATCHES))
	@touch $@

$(D)/neutrino-ddt.config.status:
	rm -rf $(N_OBJDIR)
	test -d $(N_OBJDIR) || mkdir -p $(N_OBJDIR); \
	cd $(N_OBJDIR); \
		$(SOURCE_DIR)/neutrino-ddt/autogen.sh; \
		$(BUILDENV) \
		$(SOURCE_DIR)/neutrino-ddt/configure --enable-silent-rules \
			--build=$(BUILD) \
			--host=$(TARGET) \
			$(N_CONFIG_OPTS) \
			--with-stb-hal-includes=$(SOURCE_DIR)/libstb-hal-ddt/include \
			--with-stb-hal-build=$(LH_OBJDIR)
	@touch $@

$(SOURCE_DIR)/neutrino-ddt/src/gui/version.h:
	@rm -f $@; \
	echo '#define BUILT_DATE "'`date`'"' > $@
	@if test -d $(SOURCE_DIR)/libstb-hal-ddt ; then \
		pushd $(SOURCE_DIR)/libstb-hal-ddt ; \
		HAL_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(SOURCE_DIR)/neutrino-ddt ; \
		NMP_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		pushd $(BASE_DIR) ; \
		DDT_REV=$$(git log | grep "^commit" | wc -l) ; \
		popd ; \
		echo '#define VCS "DDT-rev'$$DDT_REV'_HAL-rev'$$HAL_REV'_NMP-rev'$$NMP_REV'"' >> $@ ; \
	fi

$(D)/neutrino-ddt.do_compile: $(D)/neutrino-ddt.config.status $(SOURCE_DIR)/neutrino-ddt/src/gui/version.h
	cd $(SOURCE_DIR)/neutrino-ddt; \
		$(MAKE) -C $(N_OBJDIR) all
	@touch $@

$(D)/neutrino-ddt: $(D)/neutrino-ddt.do_prepare $(D)/neutrino-ddt.do_compile
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(TARGET_DIR); \
	rm -f $(TARGET_DIR)/var/etc/.version
	make $(TARGET_DIR)/var/etc/.version
	$(TOUCH)

neutrino-ddt-clean: neutrino-cdkroot-clean
	rm -f $(D)/neutrino-ddt
	rm -f $(D)/neutrino-ddt.config.status
	rm -f $(SOURCE_DIR)/neutrino-ddt/src/gui/version.h
	cd $(N_OBJDIR); \
		$(MAKE) -C $(N_OBJDIR) distclean

neutrino-ddt-distclean: neutrino-cdkroot-clean
	rm -rf $(N_OBJDIR)
	rm -f $(D)/neutrino-ddt*

neutrino-cdkroot-clean:
	[ -e $(TARGET_DIR)/usr/local/bin ] && cd $(TARGET_DIR)/usr/local/bin && find -name '*' -delete || true
	[ -e $(TARGET_DIR)/usr/local/share/iso-codes ] && cd $(TARGET_DIR)/usr/local/share/iso-codes && find -name '*' -delete || true
	[ -e $(TARGET_DIR)/usr/share/tuxbox/neutrino ] && cd $(TARGET_DIR)/usr/share/tuxbox/neutrino && find -name '*' -delete || true
	[ -e $(TARGET_DIR)/usr/share/fonts ] && cd $(TARGET_DIR)/usr/share/fonts && find -name '*' -delete || true
	[ -e $(TARGET_DIR)/var/tuxbox ] && cd $(TARGET_DIR)/var/tuxbox && find -name '*' -delete || true
	
#
# release-NEUTRINO-DDT
#
release-NEUTRINO-DDT: release-NONE $(D)/neutrino-ddt
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


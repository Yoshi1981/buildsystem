#
# NEUTRINO
#
N_OBJDIR = $(BUILD_TMP)/neutrino
LH_OBJDIR = $(BUILD_TMP)/libstb-hal

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
NEUTRINO_DEPS += $(D)/e2fsprogs
NEUTRINO_DEPS += $(D)/ncurses  
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
NEUTRINO_DEPS += $(D)/libid3tag
NEUTRINO_DEPS += $(D)/libmad
NEUTRINO_DEPS += $(D)/flac
#ifeq ($(LUA), lua)
NEUTRINO_DEPS += $(D)/lua 
NEUTRINO_DEPS += $(D)/luaexpat 
NEUTRINO_DEPS += $(D)/luacurl 
NEUTRINO_DEPS += $(D)/luasocket 
NEUTRINO_DEPS += $(D)/luafeedparser 
NEUTRINO_DEPS += $(D)/luasoap 
NEUTRINO_DEPS += $(D)/luajson
#endif

NEUTRINO_CFLAGS       = -Wall -W -Wshadow -pipe -Os
NEUTRINO_CFLAGS      += -D__KERNEL_STRICT_NAMES
NEUTRINO_CFLAGS      += -D__STDC_FORMAT_MACROS
NEUTRINO_CFLAGS      += -D__STDC_CONSTANT_MACROS
NEUTRINO_CFLAGS      += -fno-strict-aliasing -funsigned-char -ffunction-sections -fdata-sections

NEUTRINO_CPPFLAGS     = -I$(TARGET_DIR)/usr/include
NEUTRINO_CPPFLAGS    += -I$(CROSS_DIR)/$(TARGET)/sys-root/usr/include

ifeq ($(BOXARCH), sh4)
NEUTRINO_CPPFLAGS    += -I$(KERNEL_DIR)/include
NEUTRINO_CPPFLAGS    += -I$(DRIVER_DIR)/include
NEUTRINO_CPPFLAGS    += -I$(DRIVER_DIR)/bpamem
endif

NEUTRINO_CPPFLAGS    += -ffunction-sections -fdata-sections

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), spark spark7162))
NEUTRINO_CPPFLAGS += -I$(DRIVER_DIR)/frontcontroller/aotom_spark
endif

NEUTRINO_CONFIG_OPTS = --enable-freesatepg
NEUTRINO_CONFIG_OPTS += --enable-lua
NEUTRINO_CONFIG_OPTS += --enable-giflib
NEUTRINO_CONFIG_OPTS += --with-tremor
NEUTRINO_CONFIG_OPTS += --enable-ffmpegdec
#NEUTRINO_CONFIG_OPTS += --enable-pip
NEUTRINO_CONFIG_OPTS += --enable-pugixml

ifeq ($(BOXARCH), arm)
NEUTRINO_CONFIG_OPTS += --enable-reschange
endif

ifeq ($(GSTREAMER), gstreamer)
LH_CONFIG_OPTS += --enable-gstreamer_10
NEUTRINO_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
NEUTRINO_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
NEUTRINO_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
NEUTRINO_CPPFLAGS    += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
endif

ifeq ($(GRAPHLCD), graphlcd)
NEUTRINO_CONFIG_OPTS += --with-graphlcd
endif

ifeq ($(LCD4LINUX), lcd4linux)
NEUTRINO_CONFIG_OPTS += --with-lcd4linux
endif

MACHINE = $(BOXTYPE)
ifeq ($(BOXARCH), arm)
MACHINE = hd51
endif
ifeq ($(BOXARCH), mipsel)
MACHINE = vuduo
endif

NEUTRINO_CONFIG_OPTS += \
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
	CFLAGS="$(NEUTRINO_CFLAGS)" CXXFLAGS="$(NEUTRINO_CFLAGS)" CPPFLAGS="$(NEUTRINO_CPPFLAGS)"

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
			$(LH_CONFIG_OPTS) \
			--with-boxtype=$(MACHINE) \
			--enable-silent-rules \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CFLAGS="$(NEUTRINO_CFLAGS)" CXXFLAGS="$(NEUTRINO_CFLAGS)" CPPFLAGS="$(NEUTRINO_CPPFLAGS)"
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
NEUTRINO_PATCHES = neutrino-ddt.patch

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
			$(NEUTRINO_CONFIG_OPTS) \
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
	rm -f $(D)/neutrino.do_compile
	$(MAKE) -C $(N_OBJDIR) clean
	rm -f $(D)/neutrino
	rm -f $(SOURCE_DIR)/$(NEUTRINO)/src/gui/version.h

neutrino-distclean: libstb-hal-distclean
	rm -f $(D)/neutrino*
	$(MAKE) -C $(N_OBJDIR) distclean
	rm -rf $(N_OBJDIR)

#
# neutrino-plugins
#
NEUTRINO_PLUGINS  = $(D)/neutrino-plugins
NEUTRINO_PLUGINS += $(D)/neutrino-plugins-scripts-lua
NEUTRINO_PLUGINS += $(D)/neutrino-plugins-mediathek
#NEUTRINO_PLUGINS += $(D)/neutrino-plugins-xupnpd

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
ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mipsel))
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
			CPPFLAGS="$(NEUTRINO_CPPFLAGS) $(EXTRA_CPPFLAGS_MP_PLUGINS) -DNEW_LIBCURL" \
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
release-NEUTRINO: release-NONE $(D)/neutrino $(NEUTRINO_PLUGINS)
	install -d $(RELEASE_DIR)/usr/share/iso-codes
	install -d $(RELEASE_DIR)/usr/share/tuxbox
	install -d $(RELEASE_DIR)/var/tuxbox
	install -d $(RELEASE_DIR)/var/tuxbox/config/{webtv,zapit}
	install -d $(RELEASE_DIR)/var/tuxbox/plugins
	install -d $(RELEASE_DIR)/var/httpd
	cp -af $(TARGET_DIR)/usr/local/bin/neutrino $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/backup.sh $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/install.sh $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/luaclient $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/pzapit $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/rcsim $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/restore.sh $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/sectionsdcontrol $(RELEASE_DIR)/usr/local/bin/
	cp -dp $(TARGET_DIR)/.version $(RELEASE_DIR)/
	cp -aR $(TARGET_DIR)/usr/share/tuxbox/neutrino $(RELEASE_DIR)/usr/share/tuxbox
#	cp -aR $(TARGET_DIR)/usr/share/tuxbox/sokoban $(RELEASE_DIR)/usr/share/tuxbox
	cp -aR $(TARGET_DIR)/usr/share/fonts $(RELEASE_DIR)/usr/share/
	cp -aR $(TARGET_DIR)/var/tuxbox/* $(RELEASE_DIR)/var/tuxbox
	cp -dp $(TARGET_DIR)/.version $(RELEASE_DIR)/
	
#
#
#
PHONY += $(TARGET_DIR)/.version	


#
# NEUTRINO2
#
NEUTRINO2_DEPS  = $(D)/bootstrap
NEUTRINO2_DEPS += $(D)/e2fsprogs
NEUTRINO2_DEPS += $(D)/ncurses 
NEUTRINO2_DEPS += $(D)/libcurl
NEUTRINO2_DEPS += $(D)/libpng 
NEUTRINO2_DEPS += $(D)/libjpeg 
NEUTRINO2_DEPS += $(D)/giflib 
NEUTRINO2_DEPS += $(D)/freetype
NEUTRINO2_DEPS += $(D)/ffmpeg
NEUTRINO2_DEPS += $(D)/libfribidi
NEUTRINO2_DEPS += $(D)/libid3tag
NEUTRINO2_DEPS += $(D)/libmad
NEUTRINO2_DEPS += $(D)/libvorbisidec
NEUTRINO2_DEPS += $(D)/flac
NEUTRINO2_DEPS += $(D)/libopenthreads
NEUTRINO2_DEPS += $(D)/libass

#
# CFLAGS / CPPFLAGS
#
NEUTRINO2_CFLAGS       = -Wall -W -Wshadow -pipe -Os
NEUTRINO2_CFLAGS      += -D__KERNEL_STRICT_NAMES
NEUTRINO2_CFLAGS      += -D__STDC_FORMAT_MACROS
NEUTRINO2_CFLAGS      += -D__STDC_CONSTANT_MACROS
NEUTRINO2_CFLAGS      += -fno-strict-aliasing -funsigned-char -ffunction-sections -fdata-sections

NEUTRINO2_CPPFLAGS     = -I$(TARGET_DIR)/usr/include
NEUTRINO2_CPPFLAGS    += -ffunction-sections -fdata-sections
NEUTRINO2_CPPFLAGS    += -I$(CROSS_DIR)/$(TARGET)/sys-root/usr/include

ifeq ($(BOXARCH), sh4)
NEUTRINO2_CPPFLAGS    += -I$(KERNEL_DIR)/include
NEUTRINO2_CPPFLAGS    += -I$(DRIVER_DIR)/include
NEUTRINO2_CPPFLAGS    += -I$(DRIVER_DIR)/bpamem
endif

ifeq ($(BOXTYPE), $(filter $(BOXTYPE), spark spark7162))
NEUTRINO2_CPPFLAGS += -I$(DRIVER_DIR)/frontcontroller/aotom_spark
endif

NEUTRINO2_CONFIG_OPTS =

ifeq ($(GSTREAMER), gstreamer)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-1.0)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-audio-1.0)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs gstreamer-video-1.0)
NEUTRINO2_CPPFLAGS     += $(shell $(PKG_CONFIG) --cflags --libs glib-2.0)
NEUTRINO2_CONFIG_OPTS += --enable-gstreamer --with-gstversion=1.0
endif

ifeq ($(PYTHON), python)
NEUTRINO2_CONFIG_OPTS += --enable-python PYTHON_CPPFLAGS="-I$(TARGET_DIR)/usr/include/python2.7" PYTHON_LIBS="-L$(TARGET_DIR)/usr/lib -lpython2.7" PYTHON_SITE_PKG="$(TARGET_DIR)/usr/lib/python2.7/site-packages"
endif

ifeq ($(LUA), lua)
NEUTRINO2_CONFIG_OPTS += --enable-lua
endif

ifeq ($(CICAM), ci-cam)
NEUTRINO2_CONFIG_OPTS += --enable-ci
endif

ifeq ($(SCART), scart)
NEUTRINO2_CONFIG_OPTS += --enable-scart
endif

ifeq ($(LCD), lcd)
NEUTRINO2_CONFIG_OPTS += --enable-lcd
endif

ifeq ($(LCD), 4-digits)
NEUTRINO2_CONFIG_OPTS += --enable-4digits
endif

ifeq ($(FKEYS), fkeys)
NEUTRINO2_CONFIG_OPTS += --enable-functionkeys
endif

ifeq ($(GRAPHLCD), graphlcd)
NEUTRINO2_CONFIG_OPTS += --with-graphlcd
endif

ifeq ($(LCD4LINUX), lcd4linux)
NEUTRINO2_CONFIG_OPTS += --with-lcd4linux
endif

NEUTRINO2_PATCHES =

$(D)/neutrino2.do_prepare: $(NEUTRINO2_DEPS)
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/neutrino2
	[ -d "$(ARCHIVE)/neutrino2.git" ] && \
	(cd $(ARCHIVE)/neutrino2.git; git pull;); \
	[ -d "$(ARCHIVE)/neutrino2.git" ] || \
	git clone https://github.com/mohousch/neutrino2.git $(ARCHIVE)/neutrino2.git; \
	cp -ra $(ARCHIVE)/neutrino2.git $(SOURCE_DIR)/neutrino2; \
	set -e; cd $(SOURCE_DIR)/neutrino2/neutrino2; \
		$(call apply_patches,$(NEUTRINO2_PATCHES))
	@touch $@

$(D)/neutrino2.config.status: $(D)/neutrino2.do_prepare
	cd $(SOURCE_DIR)/neutrino2/neutrino2; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--enable-silent-rules \
			--enable-maintainer-mode \
			--with-boxtype=$(BOXTYPE) \
			$(NEUTRINO2_CONFIG_OPTS) \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CFLAGS="$(NEUTRINO2_CFLAGS)" CXXFLAGS="$(NEUTRINO2_CFLAGS)" CPPFLAGS="$(NEUTRINO2_CPPFLAGS)" LDFLAGS="$(TARGET_LDFLAGS)"
	@touch $@

$(D)/neutrino2.do_compile: $(D)/neutrino2.config.status
	cd $(SOURCE_DIR)/neutrino2/neutrino2; \
		$(MAKE) all
	@touch $@

$(D)/neutrino2: $(D)/neutrino2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/neutrino2 install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

neutrino2-clean:
	rm -f $(D)/neutrino2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/neutrino2 clean
	rm -f $(D)/neutrino2

neutrino2-distclean:
	rm -f $(D)/neutrino2*
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/neutrino2 distclean
	
#
# neutrino2 plugins
#
N2_PLUGINS_PATCHES =

$(D)/neutrino2-plugins.do_prepare: $(D)/neutrino2.do_prepare
	$(START_BUILD)
	set -e; cd $(SOURCE_DIR)/neutrino2/plugins; \
		$(call apply_patches, $(N2_PLUGINS_PATCHES))
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
			$(NEUTRINO2_CONFIG_OPTS) \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CFLAGS="$(NEUTRINO2_CFLAGS)" CXXFLAGS="$(NEUTRINO2_CFLAGS)" CPPFLAGS="$(NEUTRINO2_CPPFLAGS) -I$(driverdir) -I$(KERNEL_DIR)/include -I$(TARGET_DIR)/include" \
			LDFLAGS="$(TARGET_LDFLAGS)"
	@touch $@

$(D)/neutrino2-plugins.do_compile: $(D)/neutrino2-plugins.config.status
	cd $(SOURCE_DIR)/neutrino2/plugins; \
	$(MAKE) top_srcdir=$(SOURCE_DIR)/neutrino2/neutrino2
	@touch $@

$(D)/neutrino2-plugins: $(D)/neutrino2-plugins.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins install DESTDIR=$(TARGET_DIR)
	touch $(D)/$(notdir $@)
	$(TUXBOX_CUSTOMIZE)

neutrino2-plugins-clean:
	rm -f $(D)/neutrino2-plugins
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins clean

neutrino2-plugins-distclean:
	rm -f $(D)/neutrino2-plugins*
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/plugins distclean
	rm -f $(SOURCE_DIR)/neutrino2/plugins/config.status
	
#
# release-NEUTRINO2
#
release-NEUTRINO2: release-NONE $(D)/neutrino2 $(D)/neutrino2-plugins
	install -d $(RELEASE_DIR)/usr/share/iso-codes
	install -d $(RELEASE_DIR)/usr/share/tuxbox
	install -d $(RELEASE_DIR)/var/tuxbox
	install -d $(RELEASE_DIR)/var/tuxbox/config/{webtv,zapit}
	install -d $(RELEASE_DIR)/var/tuxbox/plugins
	install -d $(RELEASE_DIR)/var/httpd
	cp -af $(TARGET_DIR)/usr/local/bin/neutrino $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/backup.sh $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/init_hdd.sh $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/install.sh $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/pzapit $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/restore.sh $(RELEASE_DIR)/usr/local/bin/
	cp -af $(TARGET_DIR)/usr/local/bin/sectionsdcontrol $(RELEASE_DIR)/usr/local/bin/
	cp -aR $(TARGET_DIR)/usr/share/tuxbox/neutrino2 $(RELEASE_DIR)/usr/share/tuxbox
	cp -aR $(TARGET_DIR)/var/tuxbox/* $(RELEASE_DIR)/var/tuxbox
	


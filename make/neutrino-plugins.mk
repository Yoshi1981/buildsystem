#
# neutrinohd2 plugins
#
NEUTRINO_HD2_PLUGINS_PATCHES =

$(D)/neutrinohd2-plugins.do_prepare:
	$(START_BUILD)
	rm -rf $(SOURCE_DIR)/neutrinohd2-plugins
	ln -s $(SOURCE_DIR)/neutrinohd2.git/plugins $(SOURCE_DIR)/neutrinohd2-plugins
	set -e; cd $(SOURCE_DIR)/neutrinohd2-plugins; \
		$(call apply_patches, $(NEUTRINO_HD2_PLUGINS_PATCHES))
	@touch $@

$(D)/neutrinohd2-plugins.config.status: $(D)/bootstrap neutrino
	cd $(SOURCE_DIR)/neutrinohd2-plugins; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure $(SILENT_OPT) \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--with-boxtype=$(BOXTYPE) \
			--with-plugindir=/var/tuxbox/plugins \
			--with-datadir=/usr/share/tuxbox \
			--with-configdir=/var/tuxbox/config \
			--with-localedir=/var/tuxbox/locale \
			--enable-silent-rules \
			$(NHD2_OPTS) \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CPPFLAGS="$(CPPFLAGS) -I$(driverdir) -I$(KERNEL_DIR)/include -I$(TARGET_DIR)/include" \
			LDFLAGS="$(TARGET_LDFLAGS)"
	@touch $@

$(D)/neutrinohd2-plugins.do_compile: $(D)/neutrinohd2-plugins.config.status
	cd $(SOURCE_DIR)/neutrinohd2-plugins; \
	$(MAKE) top_srcdir=$(SOURCE_DIR)/neutrinohd2
	@touch $@

$(D)/neutrinohd2-plugins.build: neutrinohd2-plugins.do_prepare neutrinohd2-plugins.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrinohd2-plugins install DESTDIR=$(TARGET_DIR) top_srcdir=$(SOURCE_DIR)/neutrinohd2
	$(TOUCH)

$(D)/neutrino-plugins: $(D)/neutrinohd2.do_prepare $(D)/neutrinohd2.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrinohd2 install DESTDIR=$(TARGET_DIR)
	make $(TARGET_DIR)/.version
	touch $(D)/$(notdir $@)
	make neutrinohd2-plugins.build
	$(TUXBOX_CUSTOMIZE)

neutrino-plugins-clean:
	rm -f $(D)/neutrino-plugins
	$(MAKE) -C $(SOURCE_DIR)/neutrinohd2-plugins clean

neutrino-plugins-distclean:
	-$(MAKE) -C $(SOURCE_DIR)/neutrinohd2-plugins distclean
	rm -f $(SOURCE_DIR)/neutrinohd2-plugins/config.status
	rm -f $(D)/neutrinohd2-plugins.build
	rm -f $(D)/neutrinohd2-plugins.config.status
	rm -f $(D)/neutrinohd2-plugins.do_prepare
	rm -f $(D)/neutrinohd2-plugins.do_compile



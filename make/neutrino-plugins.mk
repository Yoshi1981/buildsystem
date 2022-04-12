#
# neutrinohd2 plugins
#
NEUTRINO_HD2_PLUGINS_PATCHES =

$(D)/neutrinohd2-plugins.do_prepare: $(D)/neutrinohd2.do_prepare
	$(START_BUILD)
	set -e; cd $(SOURCE_DIR)/neutrinohd2/plugins; \
		$(call apply_patches, $(NEUTRINO_HD2_PLUGINS_PATCHES))
	@touch $@

$(D)/neutrinohd2-plugins.config.status: $(D)/bootstrap neutrino
	cd $(SOURCE_DIR)/neutrinohd2/plugins; \
		./autogen.sh; \
		$(BUILDENV) \
		./configure $(SILENT_OPT) \
			--host=$(TARGET) \
			--build=$(BUILD) \
			--with-boxtype=$(BOXTYPE) \
			--enable-silent-rules \
			$(NHD2_OPTS) \
			PKG_CONFIG=$(PKG_CONFIG) \
			PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
			CPPFLAGS="$(CPPFLAGS) -I$(driverdir) -I$(KERNEL_DIR)/include -I$(TARGET_DIR)/include" \
			LDFLAGS="$(TARGET_LDFLAGS)"
	@touch $@

$(D)/neutrinohd2-plugins.do_compile: $(D)/neutrinohd2-plugins.config.status
	cd $(SOURCE_DIR)/neutrinohd2/plugins; \
	$(MAKE) top_srcdir=$(SOURCE_DIR)/neutrinohd2/nhd2-exp
	@touch $@

$(D)/neutrino-plugins: $(D)/neutrinohd2-plugins.do_compile
	$(MAKE) -C $(SOURCE_DIR)/neutrinohd2/plugins install DESTDIR=$(TARGET_DIR)

	touch $(D)/$(notdir $@)
	$(TUXBOX_CUSTOMIZE)

neutrino-plugins-clean:
	rm -f $(D)/neutrino-plugins
	$(MAKE) -C $(SOURCE_DIR)/neutrinohd2/plugins clean

neutrino-plugins-distclean:
	$(MAKE) -C $(SOURCE_DIR)/neutrinohd2/plugins distclean
	rm -f $(SOURCE_DIR)/neutrinohd2/plugins/config.status
	rm -f $(D)/neutrinohd2-plugins*



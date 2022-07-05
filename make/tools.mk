#
# tools-clean
#
tools-clean:
	rm -f $(D)/tools-*
	-$(MAKE) -C $(APPS_DIR)/tools/aio-grab-$(BOXARCH) clean
	-$(MAKE) -C $(APPS_DIR)/tools/showiframe-$(BOXARCH) clean
ifeq ($(BOXARCH), sh4)
	-$(MAKE) -C $(APPS_DIR)/tools/satfind clean
	-$(MAKE) -C $(APPS_DIR)/tools/spf_tool clean
	-$(MAKE) -C $(APPS_DIR)/tools/devinit clean
	-$(MAKE) -C $(APPS_DIR)/tools/evremote2 clean
	-$(MAKE) -C $(APPS_DIR)/tools/fp_control clean
	-$(MAKE) -C $(APPS_DIR)/tools/flashtool-fup clean
	-$(MAKE) -C $(APPS_DIR)/tools/flashtool-mup clean
	-$(MAKE) -C $(APPS_DIR)/tools/flashtool_mup clean
	-$(MAKE) -C $(APPS_DIR)/tools/flashtool-pad clean
	-$(MAKE) -C $(APPS_DIR)/tools/hotplug clean
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), ipbox55 ipbox99 ipbox9900 cuberevo cuberevo_mini cuberevo_mini2 cuberevo_250hd cuberevo_2000hd cuberevo_3000hd))
	-$(MAKE) -C $(APPS_DIR)/tools/ipbox_eeprom clean
endif
	-$(MAKE) -C $(APPS_DIR)/tools/stfbcontrol clean
	-$(MAKE) -C $(APPS_DIR)/tools/streamproxy clean
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), tf7700))
	-$(MAKE) -C $(APPS_DIR)/tools/tfd2mtd clean
	-$(MAKE) -C $(APPS_DIR)/tools/tffpctl clean
endif
	-$(MAKE) -C $(APPS_DIR)/tools/ustslave clean
	-$(MAKE) -C $(APPS_DIR)/tools/vfdctl clean
	-$(MAKE) -C $(APPS_DIR)/tools/wait4button clean
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vusolo4k))
	-$(MAKE) -C $(APPS_DIR)/tools/initfb clean
endif
ifneq ($(wildcard $(APPS_DIR)/tools/own-tools),)
	-$(MAKE) -C $(APPS_DIR)/tools/own-tools clean
endif

#
# tools-distclean
#
tools-distclean:
	rm -f $(D)/tools-*
	-$(MAKE) -C $(APPS_DIR)/tools/aio-grab-$(BOXARCH) distclean
	-$(MAKE) -C $(APPS_DIR)/tools/showiframe-$(BOXARCH) distclean
ifeq ($(BOXARCH), sh4)
	-$(MAKE) -C $(APPS_DIR)/tools/satfind distclean
	-$(MAKE) -C $(APPS_DIR)/tools/spf_tool distclean
	-$(MAKE) -C $(APPS_DIR)/tools/devinit distclean
	-$(MAKE) -C $(APPS_DIR)/tools/evremote2 distclean
	-$(MAKE) -C $(APPS_DIR)/tools/fp_control distclean
	-$(MAKE) -C $(APPS_DIR)/tools/flashtool-fup distclean
	-$(MAKE) -C $(APPS_DIR)/tools/flashtool-mup distclean
	-$(MAKE) -C $(APPS_DIR)/tools/flashtool_mup distclean
	-$(MAKE) -C $(APPS_DIR)/tools/flashtool-pad distclean
	-$(MAKE) -C $(APPS_DIR)/tools/hotplug distclean
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), ipbox55 ipbox99 ipbox9900 cuberevo cuberevo_mini cuberevo_mini2 cuberevo_250hd cuberevo_2000hd cuberevo_3000hd))
	-$(MAKE) -C $(APPS_DIR)/tools/ipbox_eeprom distclean
endif
	-$(MAKE) -C $(APPS_DIR)/tools/stfbcontrol distclean
	-$(MAKE) -C $(APPS_DIR)/tools/streamproxy distclean
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), tf7700))
	-$(MAKE) -C $(APPS_DIR)/tools/tfd2mtd distclean
	-$(MAKE) -C $(APPS_DIR)/tools/tffpctl distclean
endif
	-$(MAKE) -C $(APPS_DIR)/tools/ustslave distclean
	-$(MAKE) -C $(APPS_DIR)/tools/vfdctl distclean
	-$(MAKE) -C $(APPS_DIR)/tools/wait4button distclean
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vusolo4k))
	-$(MAKE) -C $(APPS_DIR)/tools/initfb distclean
endif
ifneq ($(wildcard $(APPS_DIR)/tools/own-tools),)
	-$(MAKE) -C $(APPS_DIR)/tools/own-tools distclean
endif

#
# aio-grab
#
$(D)/tools-aio-grab: $(D)/bootstrap $(D)/libpng $(D)/libjpeg
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/aio-grab-$(BOXARCH); \
		$(CONFIGURE_TOOLS) CPPFLAGS="$(CPPFLAGS) -I$(DRIVER_DIR)/bpamem" \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# devinit
#
$(D)/tools-devinit: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/devinit; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# evremote2
#
$(D)/tools-evremote2: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/evremote2; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# fp_control
#
$(D)/tools-fp_control: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/fp_control; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# flashtool-fup
#
$(D)/tools-flashtool-fup: $(D)/directories
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/flashtool-fup; \
		./autogen.sh; \
		./configure \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(HOST_DIR)
	$(TOUCH)

#
# flashtool-mup
#
$(D)/tools-flashtool-mup: $(D)/directories
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/flashtool-mup; \
		./autogen.sh; \
		./configure \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(HOST_DIR)
	$(TOUCH)

#
# flashtool_mup-box
#
$(D)/tools_flashtool_mup:
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/flashtool_mup; \
		$(CONFIGURE_TOOLS) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# flashtool-pad
#
$(D)/tools-flashtool-pad: $(D)/directories
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/flashtool-pad; \
		./autogen.sh; \
		./configure \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(HOST_DIR)
	$(TOUCH)

#
# hotplug
#
$(D)/tools-hotplug: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/hotplug; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# initfb
#
$(D)/tools-initfb: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/initfb; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# ipbox_eeprom
#
$(D)/tools-ipbox_eeprom: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/ipbox_eeprom; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# libeplayer3
#
$(D)/tools-libeplayer3: $(D)/bootstrap $(D)/ffmpeg $(D)/libass
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/libeplayer3; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)
	
#
# exteplayer3
#
EXTEPLAYER3 := exteplayer3
ifeq ($(BOXARCH), sh4)
EXTEPLAYER3 := exteplayer3-sh4
endif
$(D)/tools-exteplayer3: $(D)/bootstrap $(D)/ffmpeg $(D)/libass
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/$(EXTEPLAYER3); \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# libmme_host
#
$(D)/tools-libmme_host: $(D)/bootstrap $(D)/driver
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/libmme_host; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE) DRIVER_TOPDIR=$(DRIVER_DIR); \
		$(MAKE) install DESTDIR=$(TARGET_DIR) DRIVER_TOPDIR=$(DRIVER_DIR)
	$(TOUCH)

#
# libmme_image
#
$(D)/tools-libmme_image: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/libmme_image; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE) DRIVER_TOPDIR=$(DRIVER_DIR); \
		$(MAKE) install DESTDIR=$(TARGET_DIR) DRIVER_TOPDIR=$(DRIVER_DIR)
	$(TOUCH)

#
# minimon
#
$(D)/tools-minimon: $(D)/bootstrap $(D)/libjpeg_turbo
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/minimon; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE) KERNEL_DIR=$(KERNEL_DIR) TARGET=$(TARGET) TARGET_DIR=$(TARGET_DIR); \
		$(MAKE) install KERNEL_DIR=$(KERNEL_DIR) TARGET=$(TARGET) TARGET_DIR=$(TARGET_DIR) DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# satfind
#
$(D)/tools-satfind: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/satfind; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# showiframe
#
$(D)/tools-showiframe: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/showiframe-$(BOXARCH); \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# spf_tool
#
$(D)/tools-spf_tool: $(D)/bootstrap $(D)/libusb
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/spf_tool; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# stfbcontrol
#
$(D)/tools-stfbcontrol: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/stfbcontrol; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# streamproxy
#
$(D)/tools-streamproxy: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/streamproxy; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# tfd2mtd
#
$(D)/tools-tfd2mtd: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/tfd2mtd; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# tffpctl
#
$(D)/tools-tffpctl: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/tffpctl; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# ustslave
#
$(D)/tools-ustslave: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/ustslave; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# vfdctl
#
ifeq ($(BOXTYPE), spark7162)
EXTRA_CPPFLAGS=-DHAVE_SPARK7162_HARDWARE
endif

$(D)/tools-vfdctl: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/vfdctl; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE) CPPFLAGS="$(EXTRA_CPPFLAGS)"; \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)

#
# wait4button
#
$(D)/tools-wait4button: $(D)/bootstrap
	$(START_BUILD)
	set -e; cd $(APPS_DIR)/tools/wait4button; \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGET_DIR)
	$(TOUCH)
	
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
# TOOLS
#
TOOLS  = $(D)/tools-aio-grab
TOOLS += $(D)/tools-satfind
TOOLS += $(D)/tools-showiframe
ifeq ($(BOXARCH), sh4)
TOOLS += $(D)/tools-devinit
TOOLS += $(D)/tools-evremote2
TOOLS += $(D)/tools-fp_control
TOOLS += $(D)/tools-flashtool-fup
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), ufs912))
TOOLS += $(D)/tools_flashtool_mup
endif
TOOLS += $(D)/tools-flashtool-mup
TOOLS += $(D)/tools-flashtool-pad
TOOLS += $(D)/tools-hotplug
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), ipbox55 ipbox99 ipbox9900 cuberevo cuberevo_mini cuberevo_mini2 cuberevo_250hd cuberevo_2000hd cuberevo_3000hd))
TOOLS += $(D)/tools-ipbox_eeprom
endif
TOOLS += $(D)/tools-stfbcontrol
TOOLS += $(D)/tools-streamproxy
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), tf7700))
TOOLS += $(D)/tools-tfd2mtd
TOOLS += $(D)/tools-tffpctl
endif
TOOLS += $(D)/tools-ustslave
TOOLS += $(D)/tools-vfdctl
TOOLS += $(D)/tools-wait4button
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vusolo4k))
TOOLS += $(D)/tools-initfb
endif

$(D)/tools: $(TOOLS)
	@touch $@



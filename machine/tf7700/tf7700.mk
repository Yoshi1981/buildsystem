BOXARCH = sh4
OPTIMIZATIONS ?= size
WLAN ?= 
MEDIAFW ?= buildinplayer
INTERFACE ?=lua
CICAM = ci-cam
SCART = scart
LCD = vfd
FKEYS =

#
# kernel
#
KERNEL_STM ?= p0217

ifeq ($(KERNEL_STM), p0209)
KERNEL_VER             = 2.6.32.46_stm24_0209
KERNEL_REVISION        = 8c676f1a85935a94de1fb103c0de1dd25ff69014
STM_KERNEL_HEADERS_VER = 2.6.32.46-47
P0209                  = p0209
endif

ifeq ($(KERNEL_STM), p0217)
KERNEL_VER             = 2.6.32.71_stm24_0217
KERNEL_REVISION        = 3ec500f4212f9e4b4d2537c8be5ea32ebf68c43b
STM_KERNEL_HEADERS_VER = 2.6.32.46-48
P0217                  = p0217
endif

split_version=$(subst _, ,$(1))
KERNEL_UPSTREAM    =$(word 1,$(call split_version,$(KERNEL_VER)))
KERNEL_STM        :=$(word 2,$(call split_version,$(KERNEL_VER)))
KERNEL_LABEL      :=$(word 3,$(call split_version,$(KERNEL_VER)))
KERNEL_RELEASE    :=$(subst ^0,,^$(KERNEL_LABEL))
KERNEL_STM_LABEL  :=_$(KERNEL_STM)_$(KERNEL_LABEL)
KERNEL_DIR         =$(BUILD_TMP)/linux-sh4-$(KERNEL_VER)
KERNELNAME         = uImage

#
# Patches Kernel 24
#
COMMON_PATCHES_24 = \
		linux-sh4-makefile_stm24.patch \
		linux-stm-gpio-fix-build-CONFIG_BUG.patch \
		linux-kbuild-generate-modules-builtin_stm24_$(KERNEL_LABEL).patch \
		linux-sh4-linuxdvb_stm24_$(KERNEL_LABEL).patch \
		linux-sh4-sound_stm24_$(KERNEL_LABEL).patch \
		linux-sh4-time_stm24_$(KERNEL_LABEL).patch \
		linux-sh4-init_mm_stm24_$(KERNEL_LABEL).patch \
		linux-sh4-copro_stm24_$(KERNEL_LABEL).patch \
		linux-sh4-strcpy_stm24_$(KERNEL_LABEL).patch \
		linux-sh4-ext23_as_ext4_stm24_$(KERNEL_LABEL).patch \
		linux-sh4-bpa2_procfs_stm24_$(KERNEL_LABEL).patch \
		linux-ftdi_sio.c_stm24_$(KERNEL_LABEL).patch \
		linux-sh4-lzma-fix_stm24_$(KERNEL_LABEL).patch \
		linux-tune_stm24.patch \
		linux-net_stm24.patch \
		linux-sh4-permit_gcc_command_line_sections_stm24.patch \
		linux-sh4-mmap_stm24.patch \
		linux-defined_is_deprecated_timeconst.pl_stm24_$(KERNEL_LABEL).patch \
		$(if $(P0217),linux-patch_swap_notify_core_support_stm24_$(KERNEL_LABEL).patch) \
		$(if $(P0209),linux-sh4-dwmac_stm24_$(KERNEL_LABEL).patch)

TF7700_PATCHES_24 = $(COMMON_PATCHES_24) \
		linux-sh4-tf7700_setup_stm24_$(KERNEL_LABEL).patch \
		linux-usbwait123_stm24.patch \
		linux-sh4-stmmac_stm24_$(KERNEL_LABEL).patch \
		linux-sh4-i2c-st40-pio_stm24_$(KERNEL_LABEL).patch \
		$(if $(P0209),linux-sh4-sata-v06_stm24_$(KERNEL_LABEL).patch)

KERNEL_PATCHES_24  = $(TF7700_PATCHES_24)

KERNEL_PATCHES = $(KERNEL_PATCHES_24)
KERNEL_CONFIG = linux-sh4-$(subst _stm24_,_,$(KERNEL_VER))_$(BOXTYPE).config

$(D)/kernel.do_prepare: $(PATCHES)/$(BOXARCH)/$(KERNEL_CONFIG) \
	$(if $(KERNEL_PATCHES),$(KERNEL_PATCHES:%=$(PATCHES)/$(BOXARCH)/stm24/%))
	$(START_BUILD)
	rm -rf $(KERNEL_DIR)
	REPO=https://github.com/Duckbox-Developers/linux-sh4-2.6.32.71.git;protocol=https;branch=stmicro; \
	[ -d "$(ARCHIVE)/linux-sh4-2.6.32.71.git" ] && \
	(echo "Updating STlinux kernel source"; cd $(ARCHIVE)/linux-sh4-2.6.32.71.git; git pull;); \
	[ -d "$(ARCHIVE)/linux-sh4-2.6.32.71.git" ] || \
	(echo "Getting STlinux kernel source"; git clone -n $$REPO $(ARCHIVE)/linux-sh4-2.6.32.71.git); \
	(echo "Copying kernel source code to build environment"; cp -ra $(ARCHIVE)/linux-sh4-2.6.32.71.git $(KERNEL_DIR)); \
	(echo "Applying patch level P$(KERNEL_LABEL)"; cd $(KERNEL_DIR); git checkout -q $(KERNEL_REVISION))
	set -e; cd $(KERNEL_DIR); \
		for i in $(KERNEL_PATCHES); do \
			echo -e "==> $(TERM_RED)Applying Patch:$(TERM_NORMAL) $$i"; \
			$(PATCH)/$(BOXARCH)/stm24/$$i; \
		done
	install -m 644 $(PATCHES)/$(BOXARCH)/$(KERNEL_CONFIG) $(KERNEL_DIR)/.config
	sed -i "s#^\(CONFIG_EXTRA_FIRMWARE_DIR=\).*#\1\"$(BASE_DIR)/root/lib/integrated_firmware\"#" $(KERNEL_DIR)/.config
	-rm $(KERNEL_DIR)/localversion*
	echo "$(KERNEL_STM_LABEL)" > $(KERNEL_DIR)/localversion-stm
ifeq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug))
	@echo "Configuring kernel for debug."
	@grep -v "CONFIG_PRINTK" "$(KERNEL_DIR)/.config" > $(KERNEL_DIR)/.config.tmp
	cp $(KERNEL_DIR)/.config.tmp $(KERNEL_DIR)/.config
	@echo "CONFIG_PRINTK=y" >> $(KERNEL_DIR)/.config
	@echo "CONFIG_PRINTK_TIME=y" >> $(KERNEL_DIR)/.config
endif
ifeq ($(WLAN), $(filter $(WLAN), wlandriver))
	@echo "Using kernel wireless"
	@grep -v "CONFIG_WIRELESS" "$(KERNEL_DIR)/.config" > $(KERNEL_DIR)/.config.tmp
	cp $(KERNEL_DIR)/.config.tmp $(KERNEL_DIR)/.config
	@echo "CONFIG_WIRELESS=y" >> $(KERNEL_DIR)/.config
	@echo "# CONFIG_CFG80211 is not set" >> $(KERNEL_DIR)/.config
	@echo "# CONFIG_WIRELESS_OLD_REGULATORY is not set" >> $(KERNEL_DIR)/.config
	@echo "CONFIG_WIRELESS_EXT=y" >> $(KERNEL_DIR)/.config
	@echo "CONFIG_WIRELESS_EXT_SYSFS=y" >> $(KERNEL_DIR)/.config
	@echo "# CONFIG_LIB80211 is not set" >> $(KERNEL_DIR)/.config
	@echo "CONFIG_WLAN=y" >> $(KERNEL_DIR)/.config
	@echo "# CONFIG_WLAN_PRE80211 is not set" >> $(KERNEL_DIR)/.config
	@echo "CONFIG_WLAN_80211=y" >> $(KERNEL_DIR)/.config
	@echo "# CONFIG_LIBERTAS is not set" >> $(KERNEL_DIR)/.config
	@echo "# CONFIG_USB_ZD1201 is not set" >> $(KERNEL_DIR)/.config
	@echo "# CONFIG_HOSTAP is not set" >> $(KERNEL_DIR)/.config
endif
	@touch $@

$(D)/kernel.do_compile: $(D)/kernel.do_prepare
	set -e; cd $(KERNEL_DIR); \
		$(MAKE) -C $(KERNEL_DIR) ARCH=sh oldconfig
		$(MAKE) -C $(KERNEL_DIR) ARCH=sh include/asm
		$(MAKE) -C $(KERNEL_DIR) ARCH=sh include/linux/version.h
		$(MAKE) -C $(KERNEL_DIR) ARCH=sh CROSS_COMPILE=$(TARGET)- $(KERNELNAME) modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=sh CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
		$(DEPMOD) -ae -b $(TARGET_DIR) -F $(KERNEL_DIR)/System.map -r $(KERNEL_VER)
	@touch $@

KERNEL = $(D)/kernel
$(D)/kernel: $(D)/bootstrap host_u_boot_tools $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/arch/sh/boot/$(KERNELNAME) $(BOOT_DIR)/vmlinux.ub
	install -m 644 $(KERNEL_DIR)/vmlinux $(TARGET_DIR)/boot/vmlinux-sh4-$(KERNEL_VER)
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-$(BOXARCH)-$(KERNEL_VER)
	cp $(KERNEL_DIR)/arch/sh/boot/$(KERNELNAME) $(TARGET_DIR)/boot/
	$(DEPMOD) -ae -b $(TARGET_DIR) -F $(KERNEL_DIR)/System.map -r $(KERNEL_VER)
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# TF7700 installer
#
TFINSTALLER_DIR := $(HOSTAPPS_DIR)/tfinstaller

tfinstaller: $(D)/bootstrap $(TFINSTALLER_DIR)/u-boot.ftfd $(D)/kernel
	$(START_BUILD)
	$(MAKE) $(MAKE_OPTS) -C $(TFINSTALLER_DIR) HOST_DIR=$(HOST_DIR) BASE_DIR=$(BASE_DIR) KERNEL_DIR=$(KERNEL_DIR)
	$(TOUCH)

$(TFINSTALLER_DIR)/u-boot.ftfd: $(D)/uboot $(TFINSTALLER_DIR)/tfpacker
	$(START_BUILD)
	$(TFINSTALLER_DIR)/tfpacker $(BUILD_TMP)/u-boot-$(UBOOT_VER)/u-boot.bin $(TFINSTALLER_DIR)/u-boot.ftfd
	$(TFINSTALLER_DIR)/tfpacker -t $(BUILD_TMP)/u-boot-$(UBOOT_VER)/u-boot.bin $(TFINSTALLER_DIR)/Enigma_Installer.tfd
	$(REMOVE)/u-boot-$(UBOOT_VER)
	$(TOUCH)

$(TFINSTALLER_DIR)/tfpacker:
	$(START_BUILD)
	$(MAKE) -C $(TFINSTALLER_DIR) tfpacker
	$(TOUCH)

$(D)/tfkernel:
	$(START_BUILD)
	cd $(KERNEL_DIR); \
		$(MAKE) $(if $(TF7700),TF7700=y) ARCH=sh CROSS_COMPILE=$(TARGET)- $(KERNELNAME)
	$(TOUCH)

#
# u-boot
#
UBOOT_VER = 1.3.1
UBOOT_PATCH  =  u-boot-$(UBOOT_VER).patch
ifeq ($(BOXTYPE), tf7700)
UBOOT_PATCH += u-boot-$(UBOOT_VER)-tf7700.patch
endif

$(ARCHIVE)/u-boot-$(UBOOT_VER).tar.bz2:
	$(WGET) ftp://ftp.denx.de/pub/u-boot/u-boot-$(UBOOT_VER).tar.bz2

$(D)/uboot: bootstrap $(ARCHIVE)/u-boot-$(UBOOT_VER).tar.bz2
	$(START_BUILD)
	$(REMOVE)/u-boot-$(UBOOT_VER)
	$(UNTAR)/u-boot-$(UBOOT_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/u-boot-$(UBOOT_VER); \
		$(call apply_patches,$(UBOOT_PATCH)); \
		$(MAKE) $(BOXTYPE)_config; \
		$(MAKE)
	$(TOUCH)


#
# driver
#
DRIVER_PLATFORM   = TF7700=tf7700
DRIVER_PLATFORM   += $(WLANDRIVER)

#
# driver-symlink
#
driver-symlink:
	cp $(DRIVER_DIR)/stgfb/stmfb/linux/drivers/video/stmfb.h $(TARGET_DIR)/usr/include/linux
	cp $(DRIVER_DIR)/player2/linux/include/linux/dvb/stm_ioctls.h $(TARGET_DIR)/usr/include/linux/dvb
	touch $(D)/$(notdir $@)

#
# driver
#
driver: $(D)/driver
$(D)/driver: $(DRIVER_DIR)/Makefile $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	$(MAKE) -C $(KERNEL_DIR) ARCH=sh CONFIG_DEBUG_SECTION_MISMATCH=y \
		CONFIG_MODULES_PATH=$(CROSS_DIR)/target \
		KERNEL_LOCATION=$(KERNEL_DIR) \
		DRIVER_TOPDIR=$(DRIVER_DIR) \
		M=$(DRIVER_DIR) \
		$(DRIVER_PLATFORM) \
		CROSS_COMPILE=$(TARGET)- \
		modules
	$(MAKE) -C $(KERNEL_DIR) ARCH=sh CONFIG_DEBUG_SECTION_MISMATCH=y \
		CONFIG_MODULES_PATH=$(CROSS_DIR)/target \
		KERNEL_LOCATION=$(KERNEL_DIR) \
		DRIVER_TOPDIR=$(DRIVER_DIR) \
		M=$(DRIVER_DIR) \
		$(DRIVER_PLATFORM) \
		CROSS_COMPILE=$(TARGET)- \
		BIN_DEST=$(TARGET_DIR)/bin \
		INSTALL_MOD_PATH=$(TARGET_DIR) \
		modules_install
	$(DEPMOD) -ae -b $(TARGET_DIR) -F $(KERNEL_DIR)/System.map -r $(KERNEL_VER)
	$(TOUCH)

#
# release
#
release-tf7700:
	$(MAKE) tfinstaller
	cp $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/frontcontroller/tffp/tffp.ko $(RELEASE_DIR)/lib/modules/
	cp $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/frontends/*.ko $(RELEASE_DIR)/lib/modules/
	cp $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/stgfb/stmfb/stmcore-display-stx7109c3.ko $(RELEASE_DIR)/lib/modules/
	cp $(SKEL_ROOT)/boot/video_7109.elf $(RELEASE_DIR)/lib/firmware/video.elf
	cp $(SKEL_ROOT)/boot/audio_7100.elf $(RELEASE_DIR)/lib/firmware/audio.elf
	cp $(SKEL_ROOT)/lib/firmware/dvb-fe-cx24116.fw $(RELEASE_DIR)/lib/firmware/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_$(FLAVOUR) $(RELEASE_DIR)/etc/init.d/rcS
	install -m 0644 $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/init.d/
	cp $(BASE_DIR)/machine/$(BOXTYPE)/files/fw_env.config $(RELEASE_DIR)/etc/


#
# flashimage
#
flash-image-tf7700:
	cd $(FLASH_DIR)/tf7700 && $(SUDOCMD) ./tf7700.sh $(MAINTAINER)



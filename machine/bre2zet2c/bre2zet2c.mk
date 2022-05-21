BOXARCH = mips
OPTIMIZATIONS ?= size
WLAN ?= 
LUA ?=lua
PYTHON ?=
FLAVOUR ?= NHD2
MEDIAFW ?= gstreamer
CICAM ?= ci-cam
SCART ?=
LCD ?= 4-digits
FKEYS ?=

#
# kernel
#
KERNEL_VER             = 4.1.24
KERNEL_DATE            = 20170220
KERNEL_SRC 		= broadmedia-linux-$(KERNEL_VER)-$(KERNEL_DATE).tar.xz
KERNEL_URL		= http://source.mynonpublic.com/broadmedia/$(KERNERL_SRC)
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNELNAME             = vmlinux
CUSTOM_KERNEL_VER      = $(KERNEL_VER)

KERNEL_PATCHES_MIPSEL  = \
			0001-regmap-add-regmap_write_bits.patch \
			0002-af9035-fix-device-order-in-ID-list.patch \
			0003-Add-support-for-dvb-usb-stick-Hauppauge-WinTV-soloHD.patch \
			0004-af9035-add-USB-ID-07ca-0337-AVerMedia-HD-Volar-A867.patch \
			0005-Add-support-for-EVOLVEO-XtraTV-stick.patch \
			0006-dib8000-Add-support-for-Mygica-Geniatech-S2870.patch \
			0007-dib0700-add-USB-ID-for-another-STK8096-PVR-ref-desig.patch \
			0008-add-Hama-Hybrid-DVB-T-Stick-support.patch \
			0009-Add-Terratec-H7-Revision-4-to-DVBSky-driver.patch \
			0010-media-Added-support-for-the-TerraTec-T1-DVB-T-USB-tu.patch \
			0011-media-tda18250-support-for-new-silicon-tuner.patch \
			0012-media-dib0700-add-support-for-Xbox-One-Digital-TV-Tu.patch \
			0013-mn88472-Fix-possible-leak-in-mn88472_init.patch \
			0014-staging-media-Remove-unneeded-parentheses.patch \
			0015-staging-media-mn88472-simplify-NULL-tests.patch \
			0016-mn88472-fix-typo.patch \
			0017-mn88472-finalize-driver.patch \
			kernel-add-support-for-gcc6.patch \
			kernel-add-support-for-gcc7.patch \
			kernel-add-support-for-gcc8.patch \
			kernel-add-support-for-gcc9.patch \
			kernel-add-support-for-gcc10.patch \
			kernel-add-support-for-gcc11.patch \
			0001-Support-TBS-USB-drivers-for-4.1-kernel.patch \
			0001-TBS-fixes-for-4.1-kernel.patch \
			0001-STV-Add-PLS-support.patch \
			0001-STV-Add-SNR-Signal-report-parameters.patch \
			blindscan2.patch \
			0001-stv090x-optimized-TS-sync-control.patch \
			0002-log2-give-up-on-gcc-constant-optimizations.patch \
			move-default-dialect-to-SMB3.patch

KERNEL_PATCHES = $(KERNEL_PATCHES_MIPSEL)

$(ARCHIVE)/$(KERNEL_SRC):
	$(WGET) $(KERNEL_URL)/$(KERNEL_SRC)

$(D)/kernel.do_prepare: $(ARCHIVE)/$(KERNEL_SRC) $(BASE_DIR)/machine/$(BOXTYPE)/files/$(KERNEL_CONFIG)
	$(START_BUILD)
	rm -rf $(KERNEL_DIR)
	$(UNTAR)/$(KERNEL_SRC)
	set -e; cd $(KERNEL_DIR); \
		for i in $(KERNEL_PATCHES); do \
			echo -e "==> $(TERM_RED)Applying Patch:$(TERM_NORMAL) $$i"; \
			$(APATCH) $(BASE_DIR)/machine/$(BOXTYPE)/patches/$$i; \
		done
	install -m 644 $(BASE_DIR)/machine/$(BOXTYPE)/files/$(KERNEL_CONFIG) $(KERNEL_DIR)/.config
ifeq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug))
	@echo "Using kernel debug"
	@grep -v "CONFIG_PRINTK" "$(KERNEL_DIR)/.config" > $(KERNEL_DIR)/.config.tmp
	cp $(KERNEL_DIR)/.config.tmp $(KERNEL_DIR)/.config
	@echo "CONFIG_PRINTK=y" >> $(KERNEL_DIR)/.config
	@echo "CONFIG_PRINTK_TIME=y" >> $(KERNEL_DIR)/.config
endif
	@touch $@

$(D)/kernel.do_compile: $(D)/kernel.do_prepare
	set -e; cd $(KERNEL_DIR); \
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips oldconfig
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips CROSS_COMPILE=$(TARGET)- $(KERNELNAME) modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=mips CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	@touch $@

KERNEL = $(D)/kernel
$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/$(KERNELNAME) $(TARGET_DIR)/boot/
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-$(BOXARCH)-$(KERNEL_VER)
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# driver
#
DRIVER_VER = 4.1.24
DRIVER_DATE = 20170623
DRIVER_SRC 		= bre2zet2c-drivers-$(DRIVER_VER)-6.3.0-$(DRIVER_DATE).zip
DRIVER_URL		= http://source.mynonpublic.com/broadmedia

$(ARCHIVE)/$(DRIVER_SRC):
	$(WGET) $(DRIVER_URL)/$(DRIVER_SRC)

driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(TOUCH)

#
# release
#
release-bre2zet2c:
	cp $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/*.ko $(RELEASE_DIR)/lib/modules/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_$(FLAVOUR) $(RELEASE_DIR)/etc/init.d/rcS

#
# flashimage
#
FLASHIMAGE_PREFIX = bre2ze_t2c

flash-image-bre2zet2c:
	# Create final USB-image
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)/$(BOXTYPE)
	# splash
	cp $(SKEL_ROOT)/boot/splash.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	echo "rename this file to 'force' to force an update without confirmation" > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/noforce;
	# kernel
	gzip -9c < "$(TARGET_DIR)/boot/vmlinux" > "$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel.bin"
	# rootfs
	mkfs.ubifs -r $(RELEASE_DIR) -o $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ubi -m 2048 -e 126976 -c 8092
	echo '[ubifs]' > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'mode=ubi' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'image=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ubi' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_id=0' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_type=dynamic' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_name=rootfs' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_flags=autoresize' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	ubinize -o $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.bin -m 2048 -p 128KiB $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	rm -f $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ubi
	rm -f $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(FLASH_DIR)/$(BOXTYPE)/$(BOXTYPE)_$(FLAVOUR)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)



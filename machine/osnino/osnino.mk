BOXARCH = mips
OPTIMIZATIONS ?= size
WLAN ?=
LUA ?=lua
PYTHON ?=
FLAVOUR ?= neutrino 
MEDIAFW ?= gstreamer
CICAM ?= ci-cam
SCART ?= scart
LCD ?= 4-digits
FKEYS ?=

#
# kernel
#
KERNEL_VER             = 4.8.17
KERNEL_SRC             = linux-edision-$(KERNEL_VER).tar.xz
KERNEL_URL             = http://source.mynonpublic.com/edision
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNELNAME             = vmlinux
CUSTOM_KERNEL_VER      = $(KERNEL_VER)

KERNEL_PATCHES_MIPSEL  = \
		0001-Support-TBS-USB-drivers-for-4.6-kernel.patch \
		0001-TBS-fixes-for-4.6-kernel.patch \
		0001-STV-Add-PLS-support.patch \
		0001-STV-Add-SNR-Signal-report-parameters.patch \
		blindscan2.patch \
		0001-stv090x-optimized-TS-sync-control.patch \
		0002-log2-give-up-on-gcc-constant-optimizations.patch \
		0003-cp1emu-do-not-use-bools-for-arithmetic.patch \
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
DRIVER_VER = 4.8.17
DRIVER_DATE = 20201104
DRIVER_SRC = $(BOXTYPE)-drivers-$(DRIVER_VER)-$(DRIVER_DATE).zip
DRIVER_URL = http://source.mynonpublic.com/edision

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
release-osnino:
	cp $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/*.ko $(RELEASE_DIR)/lib/modules/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_$(FLAVOUR) $(RELEASE_DIR)/etc/init.d/rcS

#
# flashimage
#
FLASHIMAGE_PREFIX = edision/osnino

flash-image-osnino:
	# Create final USB-image
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)/$(BOXTYPE)
	# splash
	cp $(SKEL_ROOT)/boot/splash.bin $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	echo "rename this file to 'force' to force an update without confirmation" > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/noforce;
	# kernel
	gzip -9c < "$(TARGET_DIR)/boot/vmlinux" > "$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel.bin"
	# rootfs
	mkfs.ubifs -r $(RELEASE_DIR) -o $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ubi -m 2048 -e 126976 -c 4096 -F
	echo '[ubifs]' > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'mode=ubi' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'image=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ubi' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_id=0' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_type=dynamic' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_name=rootfs' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo 'vol_flags=autoresize' >> $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	ubinize -o $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.bin -m 2048 -p 128KiB $(IMAGE_BUILD_DIR)/$(VUDUO_PREFIX)/ubinize.cfg
	rm -f $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.ubi
	rm -f $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/ubinize.cfg
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(FLASH_DIR)/$(BOXTYPE)/$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)*
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)


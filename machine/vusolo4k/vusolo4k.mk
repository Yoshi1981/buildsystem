BOXARCH = arm
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
KERNEL_VER             = 3.14.28-1.8
KERNEL_SRC_VER         = 3.14-1.8
KERNEL_SRC             = stblinux-${KERNEL_SRC_VER}.tar.bz2
#KERNEL_URL             = http://archive.vuplus.com/download/kernel
KERNEL_URL		= http://code.vuplus.com/download/release/kernel
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux
KERNELNAME             = zImage
CUSTOM_KERNEL_VER      = $(KERNEL_SRC_VER)

KERNEL_PATCHES_ARM     = \
			bcm_genet_disable_warn.patch \
		    	linux_dvb-core.patch \
		    	rt2800usb_fix_warn_tx_status_timeout_to_dbg.patch \
			usb_core_hub_msleep.patch \
		    	rtl8712_fix_build_error.patch \
		    	kernel-add-support-for-gcc6.patch \
		    	kernel-add-support-for-gcc7.patch \
		    	kernel-add-support-for-gcc8.patch \
		    	kernel-add-support-for-gcc9.patch \
		    	kernel-add-support-for-gcc10.patch \
		    	kernel-add-support-for-gcc11.patch \
		    	0001-Support-TBS-USB-drivers.patch \
		    	0001-STV-Add-PLS-support.patch \
		    	0001-STV-Add-SNR-Signal-report-parameters.patch \
		    	0001-stv090x-optimized-TS-sync-control.patch \
		    	blindscan2.patch \
		    	genksyms_fix_typeof_handling.patch \
		    	0001-tuners-tda18273-silicon-tuner-driver.patch \
		    	01-10-si2157-Silicon-Labs-Si2157-silicon-tuner-driver.patch \
		    	02-10-si2168-Silicon-Labs-Si2168-DVB-T-T2-C-demod-driver.patch \
		    	0003-cxusb-Geniatech-T230-support.patch \
		    	CONFIG_DVB_SP2.patch \
		    	dvbsky.patch \
		    	rtl2832u-2.patch \
		    	0004-log2-give-up-on-gcc-constant-optimizations.patch \
		    	0005-uaccess-dont-mark-register-as-const.patch \
		    	0006-makefile-disable-warnings.patch \
		    	move-default-dialect-to-SMB3.patch \
		    	fix-multiple-defs-yyloc.patch

KERNEL_PATCHES = $(KERNEL_PATCHES_ARM)

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
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm oldconfig
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- $(KERNELNAME) modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	@touch $@

KERNEL = $(D)/kernel
$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/arch/arm/boot/$(KERNELNAME) $(BOOT_DIR)/vmlinux
	install -m 644 $(KERNEL_DIR)/vmlinux $(TARGET_DIR)/boot/vmlinux-arm-$(KERNEL_VER)
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-arm-$(KERNEL_VER)
	cp $(KERNEL_DIR)/arch/arm/boot/$(KERNELNAME) $(TARGET_DIR)/boot/
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# driver
#
DRIVER_VER = 3.14.28
DRIVER_DATE = 20180702
DRIVER_REV = r0
DRIVER_SRC = vuplus-dvb-proxy-$(BOXTYPE)-$(DRIVER_VER)-$(DRIVER_DATE).$(DRIVER_REV).tar.gz
#DRIVER_URL = http://archive.vuplus.com/download/build_support/vuplus
DRIVER_URL = http://code.vuplus.com/download/release/vuplus-dvb-proxy

$(ARCHIVE)/$(DRIVER_SRC):
	$(WGET) $(DRIVER_URL)/$(DRIVER_SRC)

driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	tar -xf $(ARCHIVE)/$(DRIVER_SRC) -C $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	$(MAKE) platform_util
	$(MAKE) libgles
	$(MAKE) vmlinuz_initrd
	$(TOUCH)

#
# platform util
#
UTIL_VER = 17.1
UTIL_DATE = 20180702
UTIL_REV = r0
UTIL_SRC = platform-util-$(BOXTYPE)-$(UTIL_VER)-$(UTIL_DATE).$(UTIL_REV).tar.gz
UTIL_URL = http://archive.vuplus.com/download/build_support/vuplus

$(ARCHIVE)/$(UTIL_SRC):
	$(WGET) $(UTIL_URL)/$(UTIL_SRC)

$(D)/platform_util: $(D)/bootstrap $(ARCHIVE)/$(UTIL_SRC)
	$(START_BUILD)
	$(UNTAR)/$(UTIL_SRC)
	install -m 0755 $(BUILD_TMP)/platform-util-$(BOXTYPE)/* $(TARGET_DIR)/usr/bin
	$(REMOVE)/platform-util-$(BOXTYPE)
	$(TOUCH)

#
# libgles
#
GLES_VER = 17.1
GLES_DATE = 20180702
GLES_REV = r0
GLES_SRC = libgles-$(BOXTYPE)-$(GLES_VER)-$(GLES_DATE).$(GLES_REV).tar.gz
GLES_URL = http://archive.vuplus.com/download/build_support/vuplus

$(ARCHIVE)/$(GLES_SRC):
	$(WGET) $(GLES_URL)/$(GLES_SRC)

$(D)/libgles: $(D)/bootstrap $(ARCHIVE)/$(GLES_SRC)
	$(START_BUILD)
	$(UNTAR)/$(GLES_SRC)
	install -m 0755 $(BUILD_TMP)/libgles-$(BOXTYPE)/lib/* $(TARGET_DIR)/usr/lib
	ln -sf libv3ddriver.so $(TARGET_DIR)/usr/lib/libEGL.so
	ln -sf libv3ddriver.so $(TARGET_DIR)/usr/lib/libGLESv2.so
	cp -a $(BUILD_TMP)/libgles-$(BOXTYPE)/include/* $(TARGET_DIR)/usr/include
	$(REMOVE)/libgles-$(BOXTYPE)
	$(TOUCH)

#
# vmlinuz initrd
#
INITRD_DATE = 20170209
INITRD_SRC = vmlinuz-initrd_$(BOXTYPE)_$(INITRD_DATE).tar.gz
INITRD_URL = http://archive.vuplus.com/download/kernel

$(ARCHIVE)/$(INITRD_SRC):
	$(WGET) $(INITRD_URL)/$(INITRD_SRC)

$(D)/vmlinuz_initrd: $(D)/bootstrap $(ARCHIVE)/$(INITRD_SRC)
	$(START_BUILD)
	tar -xf $(ARCHIVE)/$(INITRD_SRC) -C $(TARGET_DIR)/boot

#
# release
#
release-vusolo4k:
	cp $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/*.ko $(RELEASE_DIR)/lib/modules/
	cp $(TARGET_DIR)/boot/vmlinuz-initrd-7366c0 $(RELEASE_DIR)/boot/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_$(FLAVOUR) $(RELEASE_DIR)/etc/init.d/rcS

#
# flashimage
#
VUSOLO4K_IMAGE_NAME = disk
VUSOLO4K_BOOT_IMAGE = boot.img
VUSOLO4K_IMAGE_LINK = $(VUSOLO4K_IMAGE_NAME).ext4
VUSOLO4K_IMAGE_ROOTFS_SIZE = 294912
FLASHIMAGE_PREFIX = vuplus/solo4k

# emmc image
EMMC_IMAGE_SIZE = 3817472
EMMC_IMAGE = $(IMAGE_BUILD_DIR)/$(VUSOLO4K_IMAGE_NAME).img

# partition sizes
BLOCK_SIZE = 512
BLOCK_SECTOR = 2
IMAGE_ROOTFS_ALIGNMENT = 1024
BOOT_PARTITION_SIZE = 3072
KERNEL_PARTITION_OFFSET = $(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \+ $(BOOT_PARTITION_SIZE))
KERNEL_PARTITION_SIZE = 8192
ROOTFS_PARTITION_OFFSET = $(shell expr $(KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))

# partition sizes multi
# without swap data partition 819200
ROOTFS_PARTITION_SIZE_MULTI = 768000
# 51200 * 4
SWAP_DATA_PARTITION_SIZE = 204800

SECOND_KERNEL_PARTITION_OFFSET = $(shell expr $(ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SIZE_MULTI))
SECOND_ROOTFS_PARTITION_OFFSET = $(shell expr $(SECOND_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))

THIRD_KERNEL_PARTITION_OFFSET = $(shell expr $(SECOND_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SIZE_MULTI))
THIRD_ROOTFS_PARTITION_OFFSET = $(shell expr $(THIRD_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))

FOURTH_KERNEL_PARTITION_OFFSET = $(shell expr $(THIRD_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SIZE_MULTI))
FOURTH_ROOTFS_PARTITION_OFFSET = $(shell expr $(FOURTH_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))

SWAP_DATA_PARTITION_OFFSET = $(shell expr $(FOURTH_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SIZE_MULTI))

SWAP_PARTITION_OFFSET = $(shell expr $(SWAP_DATA_PARTITION_OFFSET) \+ $(SWAP_DATA_PARTITION_SIZE))

flash-image-vusolo4k-multi-disk: $(D)/host_resize2fs
	rm -rf $(IMAGE_BUILD_DIR)
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)/$(BOXTYPE)
	# Create a sparse image block
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(VUSOLO4K_IMAGE_LINK) seek=$(shell expr $(VUSOLO4K_IMAGE_ROOTFS_SIZE) \* $(BLOCK_SECTOR)) count=0 bs=$(BLOCK_SIZE)
	$(HOST_DIR)/bin/mkfs.ext4 -F $(IMAGE_BUILD_DIR)/$(VUSOLO4K_IMAGE_LINK) -d $(RELEASE_DIR)
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	$(HOST_DIR)/bin/fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(VUSOLO4K_IMAGE_LINK) || [ $? -le 3 ]
	dd if=/dev/zero of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) count=0 seek=$(shell expr $(EMMC_IMAGE_SIZE) \* $(BLOCK_SECTOR))
	parted -s $(EMMC_IMAGE) mklabel gpt
	parted -s $(EMMC_IMAGE) unit KiB mkpart boot fat16 $(IMAGE_ROOTFS_ALIGNMENT) $(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \+ $(BOOT_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel1 $(KERNEL_PARTITION_OFFSET) $(shell expr $(KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs1 ext4 $(ROOTFS_PARTITION_OFFSET) $(shell expr $(ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SIZE_MULTI))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel2 $(SECOND_KERNEL_PARTITION_OFFSET) $(shell expr $(SECOND_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs2 ext4 $(SECOND_ROOTFS_PARTITION_OFFSET) $(shell expr $(SECOND_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SIZE_MULTI))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel3 $(THIRD_KERNEL_PARTITION_OFFSET) $(shell expr $(THIRD_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs3 ext4 $(THIRD_ROOTFS_PARTITION_OFFSET) $(shell expr $(THIRD_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SIZE_MULTI))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel4 $(FOURTH_KERNEL_PARTITION_OFFSET) $(shell expr $(FOURTH_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs4 ext4 $(FOURTH_ROOTFS_PARTITION_OFFSET) $(shell expr $(FOURTH_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SIZE_MULTI))
	parted -s $(EMMC_IMAGE) unit KiB mkpart swapdata ext4 $(SWAP_DATA_PARTITION_OFFSET) $(shell expr $(SWAP_DATA_PARTITION_OFFSET) \+ $(SWAP_DATA_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart swap linux-swap $(SWAP_PARTITION_OFFSET) $(shell expr $(EMMC_IMAGE_SIZE) \- 1024)
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(VUSOLO4K_BOOT_IMAGE) bs=$(BLOCK_SIZE) count=$(shell expr $(BOOT_PARTITION_SIZE) \* $(BLOCK_SECTOR))
	mkfs.msdos -S 512 $(IMAGE_BUILD_DIR)/$(VUSOLO4K_BOOT_IMAGE)
	dd conv=notrunc if=$(IMAGE_BUILD_DIR)/$(VUSOLO4K_BOOT_IMAGE) of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \* $(BLOCK_SECTOR))
	#dd conv=notrunc if=$(TARGET_DIR)/boot/zImage.dtb of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(KERNEL_PARTITION_OFFSET) \* $(BLOCK_SECTOR))
	$(HOST_DIR)/bin/resize2fs $(IMAGE_BUILD_DIR)/$(VUSOLO4K_IMAGE_LINK) $(ROOTFS_PARTITION_SIZE_MULTI)k
	# Truncate on purpose
	dd if=$(IMAGE_BUILD_DIR)/$(VUSOLO4K_IMAGE_LINK) of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(ROOTFS_PARTITION_OFFSET) \* $(BLOCK_SECTOR)) count=$(shell expr $(VUSOLO4K_IMAGE_ROOTFS_SIZE) \* $(BLOCK_SECTOR))
	mv $(IMAGE_BUILD_DIR)/disk.img $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/

flash-image-vusolo4k-multi-rootfs:
	# Create final USB-image
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)/$(BOXTYPE)
	cp $(TARGET_DIR)/boot/vmlinuz-initrd-7366c0 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/initrd_auto.bin
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel_auto.bin
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=zImage* --exclude=vmlinuz-initrd* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	echo This file forces a reboot after the update. > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/reboot.update
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(FLASH_DIR)/$(BOXTYPE)/$(BOXTYPE)_$(FLAVOUR)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/initrd_auto.bin $(FLASHIMAGE_PREFIX)/kernel_auto.bin $(FLASHIMAGE_PREFIX)/reboot.update $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

flash-image-vusolo4k-online:
	# Create final USB-image
	mkdir -p $(IMAGE_BUILD_DIR)/$(BOXTYPE)
	mkdir -p $(FLASH_DIR)/$(BOXTYPE)
	cp $(TARGET_DIR)/boot/vmlinuz-initrd-7366c0 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/initrd_auto.bin
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(BOXTYPE)/kernel_auto.bin
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar --exclude=zImage* --exclude=vmlinuz-initrd* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(BOXTYPE)/rootfs.tar
	echo This file forces a reboot after the update. > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/reboot.update
	echo $(BOXTYPE)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion
	cd $(IMAGE_BUILD_DIR)/$(BOXTYPE) && \
	tar -cvzf $(FLASH_DIR)/$(BOXTYPE)/$(BOXTYPE)_$(FLAVOUR)_$(shell date '+%d.%m.%Y-%H.%M')_online.tgz rootfs.tar.bz2 initrd_auto.bin kernel_auto.bin reboot.update imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)


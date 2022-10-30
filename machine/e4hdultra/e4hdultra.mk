BOXARCH = arm
CICAM = ci-cam
SCART = scart
LCD = lcd
FKEYS =fkeys

#
# kernel
#
KERNEL_VER             = 4.10.12
KERNEL_DATE            = 20180424
KERNEL_SRC             = linux-$(KERNEL_VER)-arm.tar.gz
KERNEL_URL             = http://source.mynonpublic.com/gfutures
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNELNAME             = zImage
CUSTOM_KERNEL_VER      = $(KERNEL_VER)-arm

KERNEL_PATCHES_ARM = \
		TBS-fixes-for-4.10-kernel.patch \
		0001-Support-TBS-USB-drivers-for-4.6-kernel.patch \
		0001-TBS-fixes-for-4.6-kernel.patch \
		0001-STV-Add-PLS-support.patch \
		0001-STV-Add-SNR-Signal-report-parameters.patch \
		blindscan2.patch \
		dvbs2x.patch \
		0001-stv090x-optimized-TS-sync-control.patch \
		reserve_dvb_adapter_0.patch \
		blacklist_mmc0.patch \
		export_pmpoweroffprepare.patch \
		fix-multiple-defs-yyloc.patch \
		v3-1-3-media-si2157-Add-support-for-Si2141-A10.patch \
		v3-2-3-media-si2168-add-support-for-Si2168-D60.patch \
		v3-3-3-media-dvbsky-MyGica-T230C-support.patch \
		v3-3-4-media-dvbsky-MyGica-T230C-support.patch \
		v3-3-5-media-dvbsky-MyGica-T230C-support.patch \
		0002-cp1emu-do-not-use-bools-for-arithmetic.patch \
		move-default-dialect-to-SMB3.patch \
		add-more-devices-rtl8xxxu.patch \
		0005-xbox-one-tuner-4.10.patch \
		0006-dvb-media-tda18250-support-for-new-silicon-tuner.patch
		
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
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- $(KERNEL_DTB_VER) zImage modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	@touch $@

KERNEL = $(D)/kernel
$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/arch/arm/boot/zImage $(BOOT_DIR)/vmlinux
	install -m 644 $(KERNEL_DIR)/vmlinux $(TARGET_DIR)/boot/vmlinux-arm-$(KERNEL_VER)
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-arm-$(KERNEL_VER)
	cp $(KERNEL_DIR)/arch/arm/boot/zImage $(TARGET_DIR)/boot/
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)
	
#
# driver
#
DRIVER_DATE = 20191101
DRIVER_VER = 4.10.12-$(DRIVER_DATE)
DRIVER_SRC = e4hd-drivers-$(DRIVER_VER).zip
DRIVER_URL = http://source.mynonpublic.com/ceryon

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
release-e4hdultra:
	cp $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/*.ko $(RELEASE_DIR)/lib/modules/
	cp $(TARGET_DIR)/boot/zImage $(RELEASE_DIR)/boot/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_$(GUI) $(RELEASE_DIR)/etc/init.d/rcS

#
# flashimage
#
FLASHIMAGE_PREFIX = e4hd

# general
FLASH_IMAGE_NAME = disk
FLASH_BOOT_IMAGE = boot.img
FLASH_IMAGE_LINK = $(FLASH_IMAGE_NAME).ext4
FLASH_IMAGE_ROOTFS_SIZE = 294912

# emmc image
EMMC_IMAGE_SIZE = 3817472
EMMC_IMAGE = $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_NAME).img

# partition sizes
BLOCK_SIZE = 512
BLOCK_SECTOR = 2
IMAGE_ROOTFS_ALIGNMENT = 1024
BOOT_PARTITION_SIZE = 3072
KERNEL_PARTITION_SIZE = 8192
SWAP_PARTITION_SIZE = 262144
# partition size single
# without storage partition 819200 each
# 51200 * 4
STORAGE_PARTITION_SIZE = 204800
ROOTFS_PARTITION_SINGLE_SIZE = 768000
# linuxrootfs1
ROOTFS_PARTITION_MULTI_SIZE = 1048576
# linuxrootfs2-4
# MULTI_ROOTFS_PARTITION_SIZE = 2468864 - 204800 = 2264064
ALL_KERNEL_SIZE = $(shell expr 4 \* $(KERNEL_PARTITION_SIZE))
MULTI_ROOTFS_PARTITION_SIZE = $(shell expr $(EMMC_IMAGE_SIZE) \- $(BLOCK_SECTOR) \* $(IMAGE_ROOTFS_ALIGNMENT) \- $(BOOT_PARTITION_SIZE) \- $(ALL_KERNEL_SIZE) \- $(ROOTFS_PARTITION_MULTI_SIZE) \- $(SWAP_PARTITION_SIZE) \- $(STORAGE_PARTITION_SIZE))

KERNEL_PARTITION_OFFSET = $(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \+ $(BOOT_PARTITION_SIZE))
ROOTFS_PARTITION_OFFSET = $(shell expr $(KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))

#calc the offsets (single)
SECOND_KERNEL_PARTITION_OFFSET = $(shell expr $(ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
SECOND_ROOTFS_PARTITION_OFFSET = $(shell expr $(SECOND_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
THIRD_KERNEL_PARTITION_OFFSET = $(shell expr $(SECOND_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
THIRD_ROOTFS_PARTITION_OFFSET = $(shell expr $(THIRD_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
FOURTH_KERNEL_PARTITION_OFFSET = $(shell expr $(THIRD_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
FOURTH_ROOTFS_PARTITION_OFFSET = $(shell expr $(FOURTH_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
SWAP_PARTITION_OFFSET = $(shell expr $(FOURTH_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
STORAGE_PARTITION_OFFSET = $(shell expr $(SWAP_PARTITION_OFFSET) \+ $(SWAP_PARTITION_SIZE))

#calc the offsets (multi)
SECOND_KERNEL_PARTITION_OFFSET_NL = $(shell expr $(ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_MULTI_SIZE))
THIRD_KERNEL_PARTITION_OFFSET_NL = $(shell expr $(SECOND_KERNEL_PARTITION_OFFSET_NL) \+ $(KERNEL_PARTITION_SIZE))
FOURTH_KERNEL_PARTITION_OFFSET_NL = $(shell expr $(THIRD_KERNEL_PARTITION_OFFSET_NL) \+ $(KERNEL_PARTITION_SIZE))
SWAP_PARTITION_OFFSET_NL = $(shell expr $(FOURTH_KERNEL_PARTITION_OFFSET_NL) \+ $(KERNEL_PARTITION_SIZE))
MULTI_ROOTFS_PARTITION_OFFSET = $(shell expr $(SWAP_PARTITION_OFFSET_NL) \+ $(SWAP_PARTITION_SIZE))
STORAGE_PARTITION_OFFSET_NL = $(shell expr $(MULTI_ROOTFS_PARTITION_OFFSET) \+ $(MULTI_ROOTFS_PARTITION_SIZE))

flash-image-$(BOXTYPE)-multi-disk: $(D)/host_resize2fs
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)
	#
	cp $(SKEL_ROOT)/boot/lcdflashing.bmp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/; \
	# kernel
	cp $(TARGET_DIR)/boot/zImage* $(IMAGE_BUILD_DIR)/
	# Create a sparse image block
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) seek=$(shell expr $(FLASH_IMAGE_ROOTFS_SIZE) \* $(BLOCK_SECTOR)) count=0 bs=$(BLOCK_SIZE)
	$(HOST_DIR)/bin/mkfs.ext4 -F $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) -d $(RELEASE_DIR)
	# move kernel files back to $(RELEASE_DIR)/boot
#	mv -f $(IMAGE_BUILD_DIR)/zImage* $(RELEASE_DIR)/boot/
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	$(HOST_DIR)/bin/fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) || [ $? -le 3 ]
	dd if=/dev/zero of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) count=0 seek=$(shell expr $(EMMC_IMAGE_SIZE) \* $(BLOCK_SECTOR))
	parted -s $(EMMC_IMAGE) mklabel gpt
	parted -s $(EMMC_IMAGE) unit KiB mkpart boot fat16 $(IMAGE_ROOTFS_ALIGNMENT) $(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \+ $(BOOT_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel1 $(KERNEL_PARTITION_OFFSET) $(shell expr $(KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs1 ext4 $(ROOTFS_PARTITION_OFFSET) $(shell expr $(ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel2 $(SECOND_KERNEL_PARTITION_OFFSET) $(shell expr $(SECOND_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs2 ext4 $(SECOND_ROOTFS_PARTITION_OFFSET) $(shell expr $(SECOND_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel3 $(THIRD_KERNEL_PARTITION_OFFSET) $(shell expr $(THIRD_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs3 ext4 $(THIRD_ROOTFS_PARTITION_OFFSET) $(shell expr $(THIRD_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel4 $(FOURTH_KERNEL_PARTITION_OFFSET) $(shell expr $(FOURTH_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs4 ext4 $(FOURTH_ROOTFS_PARTITION_OFFSET) $(shell expr $(FOURTH_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart swap linux-swap $(SWAP_PARTITION_OFFSET) $(shell expr $(SWAP_PARTITION_OFFSET) \+ $(SWAP_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart storage ext4 $(STORAGE_PARTITION_OFFSET) 100%
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) bs=$(BLOCK_SIZE) count=$(shell expr $(BOOT_PARTITION_SIZE) \* $(BLOCK_SECTOR))
	mkfs.msdos -S 512 $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE)
	echo "boot emmcflash0.kernel1 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p3 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "boot emmcflash0.kernel1 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p3 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_1
	echo "boot emmcflash0.kernel2 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p5 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_2
	echo "boot emmcflash0.kernel3 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p7 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_3
	echo "boot emmcflash0.kernel4 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p9 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_4
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_1 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_2 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_3 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_4 ::
	dd conv=notrunc if=$(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \* $(BLOCK_SECTOR))
	dd conv=notrunc if=$(RELEASE_DIR)/boot/zImage of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(KERNEL_PARTITION_OFFSET) \* $(BLOCK_SECTOR))
	$(HOST_DIR)/bin/resize2fs $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) $(ROOTFS_PARTITION_SINGLE_SIZE)k
	# Truncate on purpose
	dd if=$(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(ROOTFS_PARTITION_OFFSET) \* $(BLOCK_SECTOR)) count=$(shell expr $(FLASH_IMAGE_ROOTFS_SIZE) \* $(BLOCK_SECTOR))
	mv $(IMAGE_BUILD_DIR)/disk.img $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cd $(IMAGE_BUILD_DIR) && \
	echo $(BOXTYPE)_$(GUI)_$(shell date '+%d%m%Y-%H%M%S') > $(FLASHIMAGE_PREFIX)/imageversion
	zip -r $(FLASH_DIR)/$(BOXTYPE)_$(GUI)_$(shell date '+%d.%m.%Y-%H.%M')_recovery_emmc_multi.zip $(FLASHIMAGE_PREFIX)/disk.img $(FLASHIMAGE_PREFIX)/imageversion $(FLASHIMAGE_PREFIX)/lcdflashing.bmp
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)
	
#
# disk
#
flash-image-$(BOXTYPE)-disk: $(D)/host_resize2fs
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)
	cp $(SKEL_ROOT)/boot/lcdflashing.bmp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/; \
	# kernel
	cp $(TARGET_DIR)/boot/zImage* $(IMAGE_BUILD_DIR)/
	# Create a sparse image block
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) seek=$(shell expr $(FLASH_IMAGE_ROOTFS_SIZE) \* $(BLOCK_SECTOR)) count=0 bs=$(BLOCK_SIZE)
	$(HOST_DIR)/bin/mkfs.ext4 -F $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) -d $(RELEASE_DIR)
	# move kernel files back to $(RELEASE_DIR)/boot
#	mv -f $(IMAGE_BUILD_DIR)/zImage* $(RELEASE_DIR)/boot/
	# Error codes 0-3 indicate successfull operation of fsck (no errors or errors corrected)
	$(HOST_DIR)/bin/fsck.ext4 -pvfD $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) || [ $? -le 3 ]
	dd if=/dev/zero of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) count=0 seek=$(shell expr $(EMMC_IMAGE_SIZE) \* $(BLOCK_SECTOR))
	parted -s $(EMMC_IMAGE) mklabel gpt
	parted -s $(EMMC_IMAGE) unit KiB mkpart boot fat16 $(IMAGE_ROOTFS_ALIGNMENT) $(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \+ $(BOOT_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel1 $(KERNEL_PARTITION_OFFSET) $(shell expr $(KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs1 ext4 $(ROOTFS_PARTITION_OFFSET) $(shell expr $(ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel2 $(SECOND_KERNEL_PARTITION_OFFSET) $(shell expr $(SECOND_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs2 ext4 $(SECOND_ROOTFS_PARTITION_OFFSET) $(shell expr $(SECOND_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel3 $(THIRD_KERNEL_PARTITION_OFFSET) $(shell expr $(THIRD_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs3 ext4 $(THIRD_ROOTFS_PARTITION_OFFSET) $(shell expr $(THIRD_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart kernel4 $(FOURTH_KERNEL_PARTITION_OFFSET) $(shell expr $(FOURTH_KERNEL_PARTITION_OFFSET) \+ $(KERNEL_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart rootfs4 ext4 $(FOURTH_ROOTFS_PARTITION_OFFSET) $(shell expr $(FOURTH_ROOTFS_PARTITION_OFFSET) \+ $(ROOTFS_PARTITION_SINGLE_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart swap linux-swap $(SWAP_PARTITION_OFFSET) $(shell expr $(SWAP_PARTITION_OFFSET) \+ $(SWAP_PARTITION_SIZE))
	parted -s $(EMMC_IMAGE) unit KiB mkpart storage ext4 $(STORAGE_PARTITION_OFFSET) 100%
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) bs=$(BLOCK_SIZE) count=$(shell expr $(BOOT_PARTITION_SIZE) \* $(BLOCK_SECTOR))
	mkfs.msdos -S 512 $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE)
	echo "boot emmcflash0.kernel1 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p3 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "boot emmcflash0.kernel1 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p3 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_1
	echo "boot emmcflash0.kernel2 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p5 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_2
	echo "boot emmcflash0.kernel3 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p7 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_3
	echo "boot emmcflash0.kernel4 'brcm_cma=504M@264M brcm_cma=192M@768M brcm_cma=1024M@2048M root=/dev/mmcblk0p9 rw rootwait $(BOXTYPE)_4.boxmode=5'" > $(IMAGE_BUILD_DIR)/STARTUP_4
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_1 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_2 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_3 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_4 ::
	dd conv=notrunc if=$(IMAGE_BUILD_DIR)/$(FLASH_BOOT_IMAGE) of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(IMAGE_ROOTFS_ALIGNMENT) \* $(BLOCK_SECTOR))
	dd conv=notrunc if=$(TARGET_DIR)/boot/zImage of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(KERNEL_PARTITION_OFFSET) \* $(BLOCK_SECTOR))
	$(HOST_DIR)/bin/resize2fs $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) $(ROOTFS_PARTITION_SINGLE_SIZE)k
	# Truncate on purpose
	dd if=$(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK) of=$(EMMC_IMAGE) bs=$(BLOCK_SIZE) seek=$(shell expr $(ROOTFS_PARTITION_OFFSET) \* $(BLOCK_SECTOR)) count=$(shell expr $(FLASH_IMAGE_ROOTFS_SIZE) \* $(BLOCK_SECTOR))
	mv $(IMAGE_BUILD_DIR)/disk.img $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cd $(RELEASE_DIR); \
	echo $(BOXTYPE)_$(GUI)_$(shell date '+%d%m%Y-%H%M%S') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(FLASH_DIR)/$(BOXTYPE)_$(GUI)_$(shell date '+%d.%m.%Y-%H.%M')_recovery_emmc.zip $(FLASHIMAGE_PREFIX)/disk.img $(FLASHIMAGE_PREFIX)/imageversion $(FLASHIMAGE_PREFIX)/lcdflashing.bmp
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# multi-rootfs
#
flash-image-$(BOXTYPE)-multi-rootfs:

#
# rootfs
#
flash-image-$(BOXTYPE)-rootfs:
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)
	cp $(SKEL_ROOT)/boot/lcdflashing.bmp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel.bin
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=zImage* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	echo $(BOXTYPE)_$(GUI)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(FLASH_DIR)/$(BOXTYPE)_$(GUI)_$(shell date '+%d.%m.%Y-%H.%M')_usb.zip $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/kernel.bin $(FLASHIMAGE_PREFIX)/imageversion $(FLASHIMAGE_PREFIX)/lcdflashing.bmp
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# online
#
flash-image-$(BOXTYPE)-online:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)
	cp $(SKEL_ROOT)/boot/lcdflashing.bmp $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/
	cp $(TARGET_DIR)/boot/zImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/kernel.bin
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=zImage* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	echo $(BOXTYPE)_$(GUI)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR)/ && \
	tar -cvzf $(FLASH_DIR)/$(BOXTYPE)_$(GUI)_$(shell date '+%d.%m.%Y-%H.%M')_online.tgz $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/kernel.bin $(FLASHIMAGE_PREFIX)/imageversion $(FLASHIMAGE_PREFIX)/lcdflashing.bmp
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)


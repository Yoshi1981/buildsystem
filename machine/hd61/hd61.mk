BOXARCH = arm
OPTIMIZATIONS ?= size
WLAN ?=
LUA ?=lua
PYTHON ?=
FLAVOUR ?= NHD2 
MEDIAFW ?= gstreamer
CICAM ?= ci-cam
SCART ?= scart
LCD ?= 4-digits
FKEYS ?=

#
# kernel
#
KERNEL_VER             = 4.4.35
KERNEL_DATE            = 20181228
KERNEL_SRC             = linux-$(KERNEL_VER)-$(KERNEL_DATE)-arm.tar.gz
KERNEL_URL             = http://source.mynonpublic.com/gfutures
KERNEL_CONFIG          = defconfig
KERNEL_DIR             = $(BUILD_TMP)/linux-$(KERNEL_VER)
KERNEL_DTB_VER         = hi3798mv200.dtb
KERNELNAME             = uImage

CUSTOM_KERNEL_VER      = $(KERNEL_VER)-$(KERNEL_DATE)-arm

KERNEL_PATCHES_ARM = \
		0002-log2-give-up-on-gcc-constant-optimizations.patch \
		0003-dont-mark-register-as-const.patch \
		0001-remote.patch \
		HauppaugeWinTV-dualHD.patch \
		dib7000-linux_4.4.179.patch \
		dvb-usb-linux_4.4.179.patch \
		wifi-linux_4.4.183.patch \
		move-default-dialect-to-SMB3.patch \
		0004-linux-fix-buffer-size-warning-error.patch \
		modules_mark__inittest__exittest_as__maybe_unused.patch \
		includelinuxmodule_h_copy__init__exit_attrs_to_initcleanup_module.patch \
		Backport_minimal_compiler_attributes_h_to_support_GCC_9.patch \
		0005-xbox-one-tuner-4.4.patch \
		0006-dvb-media-tda18250-support-for-new-silicon-tuner.patch \
		0007-dvb-mn88472-staging.patch \
		mn88472_reset_stream_ID_reg_if_no_PLP_given.patch

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
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- $(KERNEL_DTB_VER) $(KERNELNAME) modules
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	@touch $@

KERNEL = $(D)/kernel
$(D)/kernel: $(D)/bootstrap $(D)/kernel.do_compile
	install -m 644 $(KERNEL_DIR)/vmlinux $(TARGET_DIR)/boot/vmlinux-arm-$(KERNEL_VER)
	install -m 644 $(KERNEL_DIR)/System.map $(TARGET_DIR)/boot/System.map-arm-$(KERNEL_VER)
	cp $(KERNEL_DIR)/arch/arm/boot/uImage $(TARGET_DIR)/boot/
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/build || true
	rm $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/source || true
	$(TOUCH)

#
# driver
#
DRIVER_DATE = 20200731
DRIVER_VER = 4.4.35
DRIVER_SRC = hd61-drivers-$(DRIVER_VER)-$(DRIVER_DATE).zip
DRIVER_URL = http://source.mynonpublic.com/gfutures

PLAYERLIB_DATE = 20200622
PLAYERLIB_SRC = gfutures-libs-3798mv200-$(PLAYERLIB_DATE).zip
PLAYERLIB_URL = http://source.mynonpublic.com/gfutures

LIBGLES_DATE = 20181201
LIBGLES_SRC = hd61-mali-$(LIBGLES_DATE).zip
LIBGLES_HEADERS = libgles-mali-utgard-headers.zip
LIBGLES_URL = http://downloads.mutant-digital.net

MALI_MODULE_VER = DX910-SW-99002-r7p0-00rel0
MALI_MODULE_SRC = $(MALI_MODULE_VER).tgz
MALI_MODULE_PATCH = 0001-hi3798mv200-support.patch
MALI_MODULE_URL = https://developer.arm.com/-/media/Files/downloads/mali-drivers/kernel/mali-utgard-gpu

$(ARCHIVE)/$(DRIVER_SRC):
	$(WGET) $(DRIVER_URL)/$(DRIVER_SRC)

$(ARCHIVE)/$(PLAYERLIB_SRC):
	$(WGET) $(PLAYERLIB_URL)/$(PLAYERLIB_SRC)

$(ARCHIVE)/$(LIBGLES_SRC):
	$(WGET) $(LIBGLES_URL)/$(KERNEL_TYPE)/$(LIBGLES_SRC)

$(ARCHIVE)/$(MALI_MODULE_SRC):
	$(WGET) $(MALI_MODULE_URL)/$(MALI_MODULE_SRC);name=driver

driver: $(D)/driver
$(D)/driver: $(ARCHIVE)/$(DRIVER_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	install -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	unzip -o $(ARCHIVE)/$(DRIVER_SRC) -d $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra
	install -d $(TARGET_DIR)/bin
	mv $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/turnoff_power $(TARGET_DIR)/bin
	ls $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra | sed s/.ko//g > $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/modules.default
	#$(MAKE) install-v3ddriver
	#$(MAKE) install-v3ddriver-header
	$(MAKE) install-hisiplayer-preq
	$(MAKE) install-hisiplayer-libs
	#$(MAKE) mali-gpu-modul
	$(TOUCH)

#
# v3driver
#
$(D)/install-v3ddriver: $(ARCHIVE)/$(LIBGLES_SRC)
	install -d $(TARGET_LIB_DIR)
	unzip -o $(ARCHIVE)/$(LIBGLES_SRC) -d $(TARGET_LIB_DIR)
	ln -sf libMali.so $(TARGET_LIB_DIR)/libmali.so
	ln -sf libMali.so $(TARGET_LIB_DIR)/libEGL.so.1.4
	ln -sf libEGL.so.1.4 $(TARGET_LIB_DIR)/libEGL.so.1
	ln -sf libEGL.so.1 $(TARGET_LIB_DIR)/libEGL.so
	ln -sf libMali.so $(TARGET_LIB_DIR)/libGLESv1_CM.so.1.1
	ln -sf libGLESv1_CM.so.1.1 $(TARGET_LIB_DIR)/libGLESv1_CM.so.1
	ln -sf libGLESv1_CM.so.1 $(TARGET_LIB_DIR)/libGLESv1_CM.so
	ln -sf libMali.so $(TARGET_LIB_DIR)/libGLESv2.so.2.0
	ln -sf libGLESv2.so.2.0 $(TARGET_LIB_DIR)/libGLESv2.so.2
	ln -sf libGLESv2.so.2 $(TARGET_LIB_DIR)/libGLESv2.so
	ln -sf libMali.so $(TARGET_LIB_DIR)/libgbm.so

#
# v3driver-headers
#
$(D)/install-v3ddriver-header: $(ARCHIVE)/$(LIBGLES_HEADERS)
	install -d $(TARGET_INCLUDE_DIR)
	unzip -o $(PATCHES)/$(LIBGLES_HEADERS) -d $(TARGET_INCLUDE_DIR)
	install -d $(TARGET_LIB_DIR)/pkgconfig
	cp $(PATCHES)/glesv2.pc $(TARGET_LIB_DIR)/pkgconfig
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glesv2.pc
	cp $(PATCHES)/glesv1_cm.pc $(TARGET_LIB_DIR)/pkgconfig
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/glesv1_cm.pc
	cp $(PATCHES)/egl.pc $(TARGET_LIB_DIR)/pkgconfig
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/egl.pc

#
# hisiplayer-libs
#
$(D)/install-hisiplayer-libs: $(ARCHIVE)/$(PLAYERLIB_SRC)
	install -d $(BUILD_TMP)/hiplay
	unzip -o $(ARCHIVE)/$(PLAYERLIB_SRC) -d $(BUILD_TMP)/hiplay
	install -d $(TARGET_LIB_DIR)/hisilicon
	install -m 0755 $(BUILD_TMP)/hiplay/hisilicon/* $(TARGET_LIB_DIR)/hisilicon
	install -m 0755 $(BUILD_TMP)/hiplay/ffmpeg/* $(TARGET_LIB_DIR)/hisilicon
	#install -m 0755 $(BUILD_TMP)/hiplay/glibc/* $(TARGET_LIB_DIR)/hisilicon
	ln -sf /lib/ld-linux-armhf.so.3 $(TARGET_LIB_DIR)/hisilicon/ld-linux.so
	$(REMOVE)/hiplay

$(D)/install-hisiplayer-preq: $(D)/zlib $(D)/libpng $(D)/freetype $(D)/libcurl $(D)/libxml2 $(D)/libjpeg_turbo2 $(D)/harfbuzz

$(D)/mali-gpu-modul: $(ARCHIVE)/$(MALI_MODULE_SRC) $(D)/bootstrap $(D)/kernel
	$(START_BUILD)
	$(REMOVE)/$(MALI_MODULE_VER)
	$(UNTAR)/$(MALI_MODULE_SRC)
	$(CHDIR)/$(MALI_MODULE_VER); \
		$(call apply_patches, $(MALI_MODULE_PATCH)); \
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- \
		M=$(BUILD_TMP)/$(MALI_MODULE_VER)/driver/src/devicedrv/mali \
		EXTRA_CFLAGS="-DCONFIG_MALI_SHARED_INTERRUPTS=y \
		-DCONFIG_MALI400=m \
		-DCONFIG_MALI450=y \
		-DCONFIG_MALI_DVFS=y \
		-DCONFIG_GPU_AVS_ENABLE=y" \
		CONFIG_MALI_SHARED_INTERRUPTS=y \
		CONFIG_MALI400=m \
		CONFIG_MALI450=y \
		CONFIG_MALI_DVFS=y \
		CONFIG_GPU_AVS_ENABLE=y ; \
		$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TARGET)- \
		M=$(BUILD_TMP)/$(MALI_MODULE_VER)/driver/src/devicedrv/mali \
		EXTRA_CFLAGS="-DCONFIG_MALI_SHARED_INTERRUPTS=y \
		-DCONFIG_MALI400=m \
		-DCONFIG_MALI450=y \
		-DCONFIG_MALI_DVFS=y \
		-DCONFIG_GPU_AVS_ENABLE=y" \
		CONFIG_MALI_SHARED_INTERRUPTS=y \
		CONFIG_MALI400=m \
		CONFIG_MALI450=y \
		CONFIG_MALI_DVFS=y \
		CONFIG_GPU_AVS_ENABLE=y \
		DEPMOD=$(DEPMOD) INSTALL_MOD_PATH=$(TARGET_DIR) modules_install
	ls $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra | sed s/.ko//g > $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/modules.default
	$(REMOVE)/$(MALI_MODULE_VER)
	$(TOUCH)

#
# release
#
release-hd61:
	cp $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/*.ko $(RELEASE_DIR)/lib/modules/
	install -m 0755 $(SKEL_ROOT)/bin/showiframe $(RELEASE_DIR)/bin
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/halt $(RELEASE_DIR)/etc/init.d/
	cp -f $(BASE_DIR)/machine/$(BOXTYPE)/files/fstab $(RELEASE_DIR)/etc/
	install -m 0755 $(BASE_DIR)/machine/$(BOXTYPE)/files/rcS_$(FLAVOUR) $(RELEASE_DIR)/etc/init.d/rcS

#
# flashimage
#
FLASHIMAGE_PREFIX = hd61

# general
FLASH_IMAGE_NAME = disk
FLASH_BOOT_IMAGE = bootoptions.img
FLASH_IMAGE_LINK = $(FLASH_IMAGE_NAME).ext4

FLASH_BOOTOPTIONS_PARTITION_SIZE = 32768
FLASH_IMAGE_ROOTFS_SIZE = 1024M

FLASH_BOOTARGS_DATE = 20200504
FLASH_BOOTARGS_SRC = hd61-bootargs-$(FLASH_BOOTARGS_DATE).zip
FLASH_PARTITONS_DATE = 20200319
FLASH_PARTITONS_SRC = hd61-partitions-$(FLASH_PARTITONS_DATE).zip
FLASH_RECOVERY_DATE = 20200424
FLASH_RECOVERY_SRC = hd61-recovery-$(FLASH_RECOVERY_DATE).zip

$(ARCHIVE)/$(FLASH_BOOTARGS_SRC):
	$(WGET) http://source.mynonpublic.com/gfutures/$(FLASH_BOOTARGS_SRC)

$(ARCHIVE)/$(FLASH_PARTITONS_SRC):
	$(WGET) http://source.mynonpublic.com/gfutures/$(FLASH_PARTITONS_SRC)

$(ARCHIVE)/$(FLASH_RECOVERY_SRC):
	$(WGET) http://downloads.mutant-digital.net/hd61/$(FLASH_RECOVERY_SRC)

#
# multi-disk
#
flash-image-hd61-multi-disk: $(ARCHIVE)/$(FLASH_BOOTARGS_SRC) $(ARCHIVE)/$(FLASH_PARTITONS_SRC) $(ARCHIVE)/$(FLASH_RECOVERY_SRC)
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)/$(BOXTYPE)
	unzip -o $(ARCHIVE)/$(FLASH_BOOTARGS_SRC) -d $(IMAGE_BUILD_DIR)
	unzip -o $(ARCHIVE)/$(FLASH_PARTITONS_SRC) -d $(IMAGE_BUILD_DIR)
	unzip -o $(ARCHIVE)/$(FLASH_RECOVERY_SRC) -d $(IMAGE_BUILD_DIR)
	install -m 0755 $(IMAGE_BUILD_DIR)/bootargs-8gb.bin $(RELEASE_DIR)/usr/share/bootargs.bin
	install -m 0755 $(IMAGE_BUILD_DIR)/fastboot.bin $(RELEASE_DIR)/usr/share/fastboot.bin
	if [ -e $(RELEASE_DIR)/boot/logo.img ]; then \
		cp -rf $(RELEASE_DIR)/boot/logo.img $(IMAGE_BUILD_DIR)/$(BOXTYPE); \
	fi
	echo "$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_RECOVERY" > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/recoveryversion
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) bs=1024 count=$(FLASH_BOOTOPTIONS_PARTITION_SIZE)
	mkfs.msdos -S 512 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE)
	echo "bootcmd=setenv bootargs \$$(bootargs) \$$(bootargs_common); mmc read 0 0x1000000 0x3BD000 0x8000; bootm 0x1000000; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "bootargs=root=/dev/mmcblk0p23 rootsubdir=linuxrootfs1 rootfstype=ext4 kernel=/dev/mmcblk0p19" >> $(IMAGE_BUILD_DIR)/STARTUP
	echo "bootcmd=setenv vfd_msg andr;setenv bootargs \$$(bootargs) \$$(bootargs_common); run bootcmd_android; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_ANDROID
	echo "bootargs=androidboot.selinux=disable androidboot.serialno=0123456789" >> $(IMAGE_BUILD_DIR)/STARTUP_ANDROID
	echo "bootcmd=setenv vfd_msg andr;setenv bootargs \$$(bootargs) \$$(bootargs_common); run bootcmd_android; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_ANDROID_DISABLE_LINUXSE
	echo "bootargs=androidboot.selinux=disable androidboot.serialno=0123456789" >> $(IMAGE_BUILD_DIR)/STARTUP_ANDROID_DISABLE_LINUXSE
	echo "bootcmd=setenv bootargs \$$(bootargs) \$$(bootargs_common); mmc read 0 0x1000000 0x3BD000 0x8000; bootm 0x1000000; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_1
	echo "bootargs=root=/dev/mmcblk0p23 rootsubdir=linuxrootfs1 rootfstype=ext4 kernel=/dev/mmcblk0p19" >> $(IMAGE_BUILD_DIR)/STARTUP_LINUX_1
	echo "bootcmd=setenv bootargs \$$(bootargs) \$$(bootargs_common); mmc read 0 0x1000000 0x3C5000 0x8000; bootm 0x1000000; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_2
	echo "bootargs=root=/dev/mmcblk0p23 rootsubdir=linuxrootfs2 rootfstype=ext4 kernel=/dev/mmcblk0p20" >> $(IMAGE_BUILD_DIR)/STARTUP_LINUX_2
	echo "bootcmd=setenv bootargs \$$(bootargs) \$$(bootargs_common); mmc read 0 0x1000000 0x3CD000 0x8000; bootm 0x1000000; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_3
	echo "bootargs=root=/dev/mmcblk0p23 rootsubdir=linuxrootfs3 rootfstype=ext4 kernel=/dev/mmcblk0p21" >> $(IMAGE_BUILD_DIR)/STARTUP_LINUX_3
	echo "bootcmd=setenv bootargs \$$(bootargs) \$$(bootargs_common); mmc read 0 0x1000000 0x3D5000 0x8000; bootm 0x1000000; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_4
	echo "bootargs=root=/dev/mmcblk0p23 rootsubdir=linuxrootfs4 rootfstype=ext4 kernel=/dev/mmcblk0p22" >> $(IMAGE_BUILD_DIR)/STARTUP_LINUX_4
	echo "bootcmd=setenv bootargs \$$(bootargs_common); mmc read 0 0x1000000 0x1000 0x9000; bootm 0x1000000" > $(IMAGE_BUILD_DIR)/STARTUP_RECOVERY
	echo "bootcmd=setenv bootargs \$$(bootargs_common); mmc read 0 0x1000000 0x1000 0x9000; bootm 0x1000000" > $(IMAGE_BUILD_DIR)/STARTUP_ONCE
	echo "imageurl https://raw.githubusercontent.com/oe-alliance/bootmenu/master/$(BOXTYPE)/images" > $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "# " >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "iface eth0" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "dhcp yes" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "# " >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "# for static config leave out 'dhcp yes' and add the following settings:" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "# " >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "#ip 192.168.178.10" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "#netmask 255.255.255.0" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "#gateway 192.168.178.1" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "#dns 192.168.178.1" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_ANDROID ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_ANDROID_DISABLE_LINUXSE ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_1 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_2 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_3 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_4 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_RECOVERY ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/bootmenu.conf ::
	mv $(IMAGE_BUILD_DIR)/bootargs-8gb.bin $(IMAGE_BUILD_DIR)/bootargs.bin
	mv $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/bootargs-8gb.bin $(IMAGE_BUILD_DIR)/$(BOXTYPE)/bootargs.bin
	echo boot-recovery > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/misc-boot.img
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/uImage
	rm -rf $(IMAGE_BUILD_DIR)/STARTUP*
	rm -rf $(IMAGE_BUILD_DIR)/*.txt
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/*.txt
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK)
	echo "To access the recovery image press immediately by power-up the frontpanel button or hold down a remote button key untill the display says boot" > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/recovery.txt
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(FLASH_DIR)/$(BOXTYPE)/$(BOXTYPE)_$(FLAVOUR)_$(shell date '+%d.%m.%Y-%H.%M')_recovery_emmc_multi.zip *
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)
	
#
# disk
#
flash-image-hd61-disk: $(ARCHIVE)/$(FLASH_BOOTARGS_SRC) $(ARCHIVE)/$(FLASH_PARTITONS_SRC) $(ARCHIVE)/$(FLASH_RECOVERY_SRC)
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)/$(BOXTYPE)
	unzip -o $(ARCHIVE)/$(FLASH_BOOTARGS_SRC) -d $(IMAGE_BUILD_DIR)
	unzip -o $(ARCHIVE)/$(FLASH_PARTITONS_SRC) -d $(IMAGE_BUILD_DIR)
	unzip -o $(ARCHIVE)/$(FLASH_RECOVERY_SRC) -d $(IMAGE_BUILD_DIR)
	install -m 0755 $(IMAGE_BUILD_DIR)/bootargs-8gb.bin $(RELEASE_DIR)/usr/share/bootargs.bin
	install -m 0755 $(IMAGE_BUILD_DIR)/fastboot.bin $(RELEASE_DIR)/usr/share/fastboot.bin
	if [ -e $(RELEASE_DIR)/boot/logo.img ]; then \
		cp -rf $(RELEASE_DIR)/boot/logo.img $(IMAGE_BUILD_DIR)/$(BOXTYPE); \
	fi
	echo "$(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M')_RECOVERY" > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/recoveryversion
	dd if=/dev/zero of=$(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) bs=1024 count=$(FLASH_BOOTOPTIONS_PARTITION_SIZE)
	mkfs.msdos -S 512 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE)
	echo "bootcmd=setenv bootargs \$$(bootargs) \$$(bootargs_common); mmc read 0 0x1000000 0x3BD000 0x8000; bootm 0x1000000; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP
	echo "bootargs=root=/dev/mmcblk0p23 rootsubdir=linuxrootfs1 rootfstype=ext4 kernel=/dev/mmcblk0p19" >> $(IMAGE_BUILD_DIR)/STARTUP
	echo "bootcmd=setenv vfd_msg andr;setenv bootargs \$$(bootargs) \$$(bootargs_common); run bootcmd_android; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_ANDROID
	echo "bootargs=androidboot.selinux=disable androidboot.serialno=0123456789" >> $(IMAGE_BUILD_DIR)/STARTUP_ANDROID
	echo "bootcmd=setenv vfd_msg andr;setenv bootargs \$$(bootargs) \$$(bootargs_common); run bootcmd_android; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_ANDROID_DISABLE_LINUXSE
	echo "bootargs=androidboot.selinux=disable androidboot.serialno=0123456789" >> $(IMAGE_BUILD_DIR)/STARTUP_ANDROID_DISABLE_LINUXSE
	echo "bootcmd=setenv bootargs \$$(bootargs) \$$(bootargs_common); mmc read 0 0x1000000 0x3BD000 0x8000; bootm 0x1000000; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_1
	echo "bootargs=root=/dev/mmcblk0p23 rootsubdir=linuxrootfs1 rootfstype=ext4 kernel=/dev/mmcblk0p19" >> $(IMAGE_BUILD_DIR)/STARTUP_LINUX_1
	echo "bootcmd=setenv bootargs \$$(bootargs) \$$(bootargs_common); mmc read 0 0x1000000 0x3C5000 0x8000; bootm 0x1000000; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_2
	echo "bootargs=root=/dev/mmcblk0p23 rootsubdir=linuxrootfs2 rootfstype=ext4 kernel=/dev/mmcblk0p20" >> $(IMAGE_BUILD_DIR)/STARTUP_LINUX_2
	echo "bootcmd=setenv bootargs \$$(bootargs) \$$(bootargs_common); mmc read 0 0x1000000 0x3CD000 0x8000; bootm 0x1000000; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_3
	echo "bootargs=root=/dev/mmcblk0p23 rootsubdir=linuxrootfs3 rootfstype=ext4 kernel=/dev/mmcblk0p21" >> $(IMAGE_BUILD_DIR)/STARTUP_LINUX_3
	echo "bootcmd=setenv bootargs \$$(bootargs) \$$(bootargs_common); mmc read 0 0x1000000 0x3D5000 0x8000; bootm 0x1000000; run bootcmd_fallback" > $(IMAGE_BUILD_DIR)/STARTUP_LINUX_4
	echo "bootargs=root=/dev/mmcblk0p23 rootsubdir=linuxrootfs4 rootfstype=ext4 kernel=/dev/mmcblk0p22" >> $(IMAGE_BUILD_DIR)/STARTUP_LINUX_4
	echo "bootcmd=setenv bootargs \$$(bootargs_common); mmc read 0 0x1000000 0x1000 0x9000; bootm 0x1000000" > $(IMAGE_BUILD_DIR)/STARTUP_RECOVERY
	echo "bootcmd=setenv bootargs \$$(bootargs_common); mmc read 0 0x1000000 0x1000 0x9000; bootm 0x1000000" > $(IMAGE_BUILD_DIR)/STARTUP_ONCE
	echo "imageurl https://raw.githubusercontent.com/oe-alliance/bootmenu/master/$(BOXTYPE)/images" > $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "# " >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "iface eth0" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "dhcp yes" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "# " >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "# for static config leave out 'dhcp yes' and add the following settings:" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "# " >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "#ip 192.168.178.10" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "#netmask 255.255.255.0" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "#gateway 192.168.178.1" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	echo "#dns 192.168.178.1" >> $(IMAGE_BUILD_DIR)/bootmenu.conf
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_ANDROID ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_ANDROID_DISABLE_LINUXSE ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_1 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_2 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_3 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_LINUX_4 ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/STARTUP_RECOVERY ::
	mcopy -i $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/$(FLASH_BOOT_IMAGE) -v $(IMAGE_BUILD_DIR)/bootmenu.conf ::
	mv $(IMAGE_BUILD_DIR)/bootargs-8gb.bin $(IMAGE_BUILD_DIR)/bootargs.bin
	mv $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/bootargs-8gb.bin $(IMAGE_BUILD_DIR)/$(BOXTYPE)/bootargs.bin
	echo boot-recovery > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/misc-boot.img
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/uImage
	rm -rf $(IMAGE_BUILD_DIR)/STARTUP*
	rm -rf $(IMAGE_BUILD_DIR)/*.txt
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/*.txt
	rm -rf $(IMAGE_BUILD_DIR)/$(FLASH_IMAGE_LINK)
	echo "To access the recovery image press immediately by power-up the frontpanel button or hold down a remote button key untill the display says boot" > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/recovery.txt
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(FLASH_DIR)/$(BOXTYPE)/$(BOXTYPE)_$(FLAVOUR)_$(shell date '+%d.%m.%Y-%H.%M')_recovery_emmc.zip *
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)
	
#
# multi-rootfs
#

#
# rootfs
#
flash-image-hd61-rootfs:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	mkdir -p $(FLASH_DIR)/$(BOXTYPE)
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/uImage
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=uImage* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	echo "$(BOXTYPE)_multiroot_usb_$(shell date '+%d.%m.%Y-%H.%M')" > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	echo "$(BOXTYPE)_multiroot_usb_$(shell date '+%d.%m.%Y-%H.%M')_emmc.zip" > $(IMAGE_BUILD_DIR)/unforce_$(BOXTYPE).txt; \
	echo "Rename the unforce_$(BOXTYPE).txt to force_$(BOXTYPE).txt and move it to the root of your usb-stick" > $(IMAGE_BUILD_DIR)/force_$(BOXTYPE)_READ.ME; \
	echo "When you enter the recovery menu then it will force to install the image $$(cat $(IMAGE_BUILD_DIR)/$(BOXTYPE)/imageversion).zip in the image-slot1" >> $(IMAGE_BUILD_DIR)/force_$(BOXTYPE)_READ.ME; \
	cd $(IMAGE_BUILD_DIR) && \
	zip -r $(FLASH_DIR)/$(BOXTYPE)/$(BOXTYPE)_$(FLAVOUR)_$(shell date '+%d.%m.%Y-%H.%M')_mmc.zip unforce_$(BOXTYPE).txt force_$(BOXTYPE)_READ.ME $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/uImage $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)

#
# online
#
flash-image-hd61-online:
	rm -rf $(IMAGE_BUILD_DIR) || true
	mkdir -p $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)
	cp $(TARGET_DIR)/boot/uImage $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/uImage
	cd $(RELEASE_DIR); \
	tar -cvf $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar --exclude=uImage* . > /dev/null 2>&1; \
	bzip2 $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/rootfs.tar
	echo $(BOXTYPE)_$(shell date '+%d.%m.%Y-%H.%M') > $(IMAGE_BUILD_DIR)/$(FLASHIMAGE_PREFIX)/imageversion
	cd $(IMAGE_BUILD_DIR) && \
	tar -cvzf $(FLASH_DIR)/$(BOXTYPE)/$(BOXTYPE)_$(FLAVOUR)_$(shell date '+%d.%m.%Y-%H.%M')_online.tgz $(FLASHIMAGE_PREFIX)/rootfs.tar.bz2 $(FLASHIMAGE_PREFIX)/uImage $(FLASHIMAGE_PREFIX)/imageversion
	# cleanup
	rm -rf $(IMAGE_BUILD_DIR)




#
# flashimage
#
flashimage: release-$(FLAVOUR)
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), fortis_hdbox octagon1008 ufs910 ufs922 ipbox55 ipbox9900 cuberevo cuberevo_mini cuberevo_mini2 cuberevo_250hd cuberevo_2000hd cuberevo_3000hd))
	$(MAKE) flash-image-$(BOXTYPE)
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), spark spark7162))
	$(MAKE) flash-image-$(BOXTYPE)
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), atevio7500))
	$(MAKE) flash-image-atevio7500
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), ufs912))
	$(MAKE) flash-image-ufs912
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), ufs913))
	$(MAKE) flash-image-ufs913
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), tf7700))
	$(MAKE) flash-image-tf7700
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), hd51))
	$(MAKE) flash-image-hd51-multi-disk flash-image-hd51-multi-rootfs
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), hd60))
	$(MAKE) flash-image-hd60-multi-disk
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vusolo4k))
	$(MAKE) flash-image-vusolo4k-multi-disk flash-image-vusolo4k-multi-rootfs
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vusolo4k))
	$(MAKE) flash-image-vusolo4k-multi-rootfs
endif
ifeq ($(BOXTYPE), vuduo)
	$(MAKE) flash-image-vuduo
endif
ifeq ($(BOXTYPE), gb800se)
	$(MAKE) flash-image-gb800se
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), osnino osninoplus osninopro))
	$(MAKE) flash-image-$(BOXTYPE)
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), osmio4k osmio4kplus osmini4k))
	$(MAKE) flash-image-$(BOXTYPE)-multi-disk flash-image-$(BOXTYPE)-multi-rootfs
endif
ifeq ($(BOXTYPE), bre2ze4k)
	$(MAKE) flash-image-bre2ze4k-multi-disk flash-image-bre2ze4k-multi-rootfs
endif
ifeq ($(BOXTYPE), bre2zet2c)
	$(MAKE) flash-image-bre2zet2c
endif
ifeq ($(BOXTYPE), h7)
	$(MAKE) flash-image-h7-multi-disk flash-image-h7-multi-rootfs
endif
ifeq ($(BOXTYPE), hd61)
	$(MAKE) flash-image-hd61-multi-disk flash-image-hd61-multi-rootfs
endif
ifeq ($(BOXTYPE), vuduo2)
	$(MAKE) flash-image-vuduo2
endif
ifeq ($(BOXTYPE), vuduo4k)
	$(MAKE) flash-image-vuduo4k-multi-rootfs
endif
ifeq ($(BOXTYPE), vuultimo4k)
	$(MAKE) flash-image-vuultimo4k-multi-rootfs
endif
ifeq ($(BOXTYPE), vuuno4k)
	$(MAKE) flash-image-vuuno4k-multi-rootfs
endif
ifeq ($(BOXTYPE), vuuno4kse)
	$(MAKE) flash-image-vuuno4kse-multi-rootfs
endif
ifeq ($(BOXTYPE), vuzero4k)
	$(MAKE) flash-image-vuzero4k-multi-rootfs
endif
	$(TUXBOX_CUSTOMIZE)

#
# online-image
#
online-image: release
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), hd51))
	$(MAKE) flash-image-hd51-online
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), vusolo4k))
	$(MAKE) flash-image-vusolo4k-online
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), osmio4k osmio4kplus osmini4k))
	$(MAKE) flash-image-$(BOXTYPE)-online
endif
ifeq ($(BOXTYPE), bre2ze4k)
	$(MAKE) flash-image-bre2ze4k-online
endif
ifeq ($(BOXTYPE), h7)
	$(MAKE) flash-image-h7-online
endif
ifeq ($(BOXTYPE), hd61)
	$(MAKE) flash-image-hd61-online
endif
ifeq ($(BOXTYPE), vuduo4k)
	$(MAKE) flash-image-vuduo4k-online
endif
ifeq ($(BOXTYPE), vuultimo4k)
	$(MAKE) flash-image-vuultimo4k-online
endif
ifeq ($(BOXTYPE), vuuno4k)
	$(MAKE) flash-image-vuuno4k-online
endif
ifeq ($(BOXTYPE), vuuno4kse)
	$(MAKE) flash-image-vuuno4kse-online
endif
ifeq ($(BOXTYPE), vuzero4k)
	$(MAKE) flash-image-vuzero4k-online
endif
	$(TUXBOX_CUSTOMIZE)

#
# flash-clean
#
flash-clean:
ifeq ($(BOXARCH), sh4)
	cd $(FLASH_DIR)/nor_flash && $(SUDOCMD) rm -rf ./tmp ./out
	cd $(FLASH_DIR)/spark7162 && $(SUDOCMD) rm -rf ./tmp ./out
	cd $(FLASH_DIR)/atevio7500 && $(SUDOCMD) rm -rf ./tmp ./out
	cd $(FLASH_DIR)/ufs912 && $(SUDOCMD) rm -rf ./tmp ./out
	cd $(FLASH_DIR)/ufs913 && $(SUDOCMD) rm -rf ./tmp ./out
	cd $(FLASH_DIR)/tf7700 && $(SUDOCMD) rm -rf ./tmp ./out
else
	cd $(FLASH_DIR)/$(BOXTYPE) && rm -rf *.*
endif



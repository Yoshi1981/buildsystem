#
#
#
ifeq ($(WLAN), wlandriver)
WLANDRIVER = WLANDRIVER=wlandriver
endif

#
# driver
#
driver: $(D)/driver

#
# driver-symlink
#
ifeq ($(BOXARCH), sh4)
driver-symlink:
	cp $(DRIVER_DIR)/stgfb/stmfb/linux/drivers/video/stmfb.h $(TARGET_DIR)/usr/include/linux
	cp $(DRIVER_DIR)/player2/linux/include/linux/dvb/stm_ioctls.h $(TARGET_DIR)/usr/include/linux/dvb
	touch $(D)/$(notdir $@)
endif

#
# driver-clean
#
driver-clean:
ifeq ($(BOXARCH), sh4)
	$(MAKE) -C $(DRIVER_DIR) ARCH=sh KERNEL_LOCATION=$(KERNEL_DIR) distclean
	rm -f $(D)/driver-symlink
else
	rm -f $(TARGET_DIR)/lib/modules/$(KERNEL_VER)/extra/*
endif
	rm -f $(D)/driver



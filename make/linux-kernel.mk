#
# KERNEL-HEADERS
#
$(D)/kernel-headers: $(D)/kernel.do_prepare
	cd $(KERNEL_DIR) && \
		$(INSTALL) -d $(TARGET_DIR)/usr/include && \
		cp -a include/linux $(TARGET_DIR)/usr/include 
#&& \
#		cp -a include/asm-sh $(TARGET_DIR)/usr/include/asm && \
#		cp -a include/asm-generic $(TARGET_DIR)/usr/include && \
#		cp -a include/mtd $(TARGET_DIR)/usr/include
	touch $@


#
# kernel-distclean
#
kernel-distclean:
	rm -f $(D)/kernel
	rm -f $(D)/kernel.do_compile
	rm -f $(D)/kernel.do_prepare

#
# kernel-clean
#
kernel-clean:
	-$(MAKE) -C $(KERNEL_DIR) clean
	rm -f $(D)/kernel
	rm -f $(D)/kernel.do_compile
	rm -f $(TARGET_DIR)/boot/$(KERNELNAME)

#
# Helper
#
kernel.menuconfig kernel.xconfig: \
kernel.%: $(D)/kernel
ifeq ($(BOXARCH), sh4)
	$(MAKE) -C $(KERNEL_DIR) ARCH=sh CROSS_COMPILE=$(TARGET)- $*
else
	$(MAKE) -C $(KERNEL_DIR) ARCH=$(BOXARCH) CROSS_COMPILE=$(TARGET)- $*
endif
	@echo ""
	@echo "You have to edit $(PATCHES)/$(BOXARCH)/$(KERNEL_CONFIG) m a n u a l l y to make changes permanent !!!"
	@echo ""
	diff $(KERNEL_DIR)/.config.old $(KERNEL_DIR)/.config
	@echo ""


#
# system-tools
#
SYSTEM_TOOLS  = $(D)/busybox
SYSTEM_TOOLS += $(D)/sysvinit
SYSTEM_TOOLS += $(D)/util_linux
SYSTEM_TOOLS += $(D)/e2fsprogs
SYSTEM_TOOLS += $(D)/hdidle
SYSTEM_TOOLS += $(D)/portmap
ifneq ($(BOXTYPE), $(filter $(BOXTYPE), ufs910 ufs922))
SYSTEM_TOOLS += $(D)/jfsutils
SYSTEM_TOOLS += $(D)/nfs_utils
endif
SYSTEM_TOOLS += $(D)/vsftpd
SYSTEM_TOOLS += $(D)/autofs
SYSTEM_TOOLS += $(D)/udpxy
SYSTEM_TOOLS += $(D)/dvbsnoop
SYSTEM_TOOLS += $(D)/fbshot
ifeq ($(BOXARCH), $(filter $(BOXARCH), arm mips))
SYSTEM_TOOLS += $(D)/ofgwrite
endif
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), atevio7500 spark spark7162 ufs912 ufs913))
	SYSTEM_TOOLS += $(D)/ntfs_3g
ifneq ($(BOXTYPE), $(filter $(BOXTYPE), ufs910))
	SYSTEM_TOOLS += $(D)/mtd_utils 
	SYSTEM_TOOLS += $(D)/gptfdisk
endif
endif
ifeq ($(BOXARCH), arm)
	SYSTEM_TOOLS += $(D)/ntfs_3g 
	SYSTEM_TOOLS += $(D)/gptfdisk
	SYSTEM_TOOLS += $(D)/mc 
endif

$(D)/system-tools: $(SYSTEM_TOOLS)
	@touch $@

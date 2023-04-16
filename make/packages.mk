#
# libupnp-ipk
#
libupnp-ipk: $(D)/bootstrap $(ARCHIVE)/$(LIBUPNP_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/libupnp-$(LIBUPNP_VER)
	$(UNTAR)/$(LIBUPNP_SOURCE)
	$(CHDIR)/libupnp-$(LIBUPNP_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/libupnp-$(LIBUPNP_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/libupnp && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/libupnp_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# minidlna-ipk
#	
minidlna-ipk: $(D)/bootstrap $(D)/zlib $(D)/sqlite $(D)/libexif $(D)/libjpeg $(D)/libid3tag $(D)/libogg $(D)/libvorbis $(D)/flac $(D)/ffmpeg $(ARCHIVE)/$(MINIDLNA_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/minidlna-$(MINIDLNA_VER)
	$(UNTAR)/$(MINIDLNA_SOURCE)
	$(CHDIR)/minidlna-$(MINIDLNA_VER); \
		$(call apply_patches, $(MINIDLNA_PATCH)); \
		autoreconf -fi $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install prefix=/usr DESTDIR=$(PKGPREFIX)
	$(REMOVE)/minidlna-$(MINIDLNA_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/minidlna && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/minidlna_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# fbshot-ipk
#
fbshot-ipk: $(D)/bootstrap $(D)/libpng $(ARCHIVE)/$(FBSHOT_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/fbshot-$(FBSHOT_VER)
	$(UNTAR)/$(FBSHOT_SOURCE)
	$(CHDIR)/fbshot-$(FBSHOT_VER); \
		$(call apply_patches, $(FBSHOT_PATCH)); \
		sed -i s~'gcc'~"$(TARGET)-gcc $(TARGET_CFLAGS) $(TARGET_LDFLAGS)"~ Makefile; \
		sed -i 's/strip fbshot/$(TARGET)-strip fbshot/' Makefile; \
		$(MAKE) all; \
		install -D -m 755 fbshot $(PKGPREFIX)/bin/fbshot
	$(REMOVE)/fbshot-$(FBSHOT_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/fbshot && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/fbshot_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# samba-ipk
#	
samba-ipk: $(D)/bootstrap $(ARCHIVE)/$(SAMBA_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGPREFIX)/etc/init.d
	install -d $(PKGS_DIR)
	$(REMOVE)/samba-$(SAMBA_VER)
	$(UNTAR)/$(SAMBA_SOURCE)
	$(CHDIR)/samba-$(SAMBA_VER); \
		$(call apply_patches, $(SAMBA_PATCH)); \
		cd source3; \
		./autogen.sh; \
		$(BUILDENV) \
		ac_cv_lib_attr_getxattr=no \
		ac_cv_search_getxattr=no \
		ac_cv_file__proc_sys_kernel_core_pattern=yes \
		libreplace_cv_HAVE_C99_VSNPRINTF=yes \
		libreplace_cv_HAVE_GETADDRINFO=yes \
		libreplace_cv_HAVE_IFACE_IFCONF=yes \
		LINUX_LFS_SUPPORT=no \
		samba_cv_CC_NEGATIVE_ENUM_VALUES=yes \
		samba_cv_HAVE_GETTIMEOFDAY_TZ=yes \
		samba_cv_HAVE_IFACE_IFCONF=yes \
		samba_cv_HAVE_KERNEL_OPLOCKS_LINUX=yes \
		samba_cv_HAVE_SECURE_MKSTEMP=yes \
		samba_cv_HAVE_WRFILE_KEYTAB=no \
		samba_cv_USE_SETREUID=yes \
		samba_cv_USE_SETRESUID=yes \
		samba_cv_have_setreuid=yes \
		samba_cv_have_setresuid=yes \
		ac_cv_header_zlib_h=no \
		samba_cv_zlib_1_2_3=no \
		ac_cv_path_PYTHON="" \
		ac_cv_path_PYTHON_CONFIG="" \
		libreplace_cv_HAVE_GETADDRINFO=no \
		libreplace_cv_READDIR_NEEDED=no \
		./configure $(SILENT_OPT) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix= \
			--includedir=/usr/include \
			--exec-prefix=/usr \
			--disable-pie \
			--disable-avahi \
			--disable-cups \
			--disable-relro \
			--disable-swat \
			--disable-shared-libs \
			--disable-socket-wrapper \
			--disable-nss-wrapper \
			--disable-smbtorture4 \
			--disable-fam \
			--disable-iprint \
			--disable-dnssd \
			--disable-pthreadpool \
			--disable-dmalloc \
			--with-included-iniparser \
			--with-included-popt \
			--with-sendfile-support \
			--without-aio-support \
			--without-cluster-support \
			--without-ads \
			--without-krb5 \
			--without-dnsupdate \
			--without-automount \
			--without-ldap \
			--without-pam \
			--without-pam_smbpass \
			--without-winbind \
			--without-wbclient \
			--without-syslog \
			--without-nisplus-home \
			--without-quotas \
			--without-sys-quotas \
			--without-utmp \
			--without-acl-support \
			--with-configdir=/etc/samba \
			--with-privatedir=/etc/samba \
			--with-mandir=no \
			--with-piddir=/var/run \
			--with-logfilebase=/var/log \
			--with-lockdir=/var/lock \
			--with-swatdir=/usr/share/swat \
			--disable-cups \
			--without-winbind \
			--without-libtdb \
			--without-libtalloc \
			--without-libnetapi \
			--without-libsmbclient \
			--without-libsmbsharemodes \
			--without-libtevent \
			--without-libaddns \
		; \
		$(MAKE) $(MAKE_OPTS); \
		$(MAKE) $(MAKE_OPTS) installservers installbin installscripts installdat installmodules \
			SBIN_PROGS="bin/samba_multicall" DESTDIR=$(PKGPREFIX) prefix=./. ; \
			ln -s samba_multicall $(PKGPREFIX)/usr/sbin/nmbd
			ln -s samba_multicall $(PKGPREFIX)/usr/sbin/smbd
			ln -s samba_multicall $(PKGPREFIX)/usr/sbin/smbpasswd
	install -m 755 $(SKEL_ROOT)/etc/init.d/samba $(PKGPREFIX)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/samba/smb.conf $(PKGPREFIX)/etc/samba/
	$(REMOVE)/samba-$(SAMBA_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/samba && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/samba_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# ofgwrite-ipk
#
ofgwrite-ipk: $(D)/bootstrap $(ARCHIVE)/$(OFGWRITE_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGPREFIX)/usr/bin
	install -d $(PKGS_DIR)
	$(REMOVE)/ofgwrite-ddt
	set -e; if [ -d $(ARCHIVE)/ofgwrite-ddt.git ]; \
		then cd $(ARCHIVE)/ofgwrite-ddt.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/Duckbox-Developers/ofgwrite-ddt.git ofgwrite-ddt.git; \
		fi
	cp -ra $(ARCHIVE)/ofgwrite-ddt.git $(BUILD_TMP)/ofgwrite-ddt
	$(CHDIR)/ofgwrite-ddt; \
		$(call apply_patches,$(OFGWRITE_PATCH)); \
		$(BUILDENV) \
		$(MAKE); \
	install -m 755 $(BUILD_TMP)/ofgwrite-ddt/ofgwrite_bin $(PKGPREFIX)/usr/bin
	install -m 755 $(BUILD_TMP)/ofgwrite-ddt/ofgwrite_caller $(PKGPREFIX)/usr/bin
	install -m 755 $(BUILD_TMP)/ofgwrite-ddt/ofgwrite $(PKGPREFIX)/usr/bin
	$(REMOVE)/ofgwrite-ddt
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/ofgwrite && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/ofgwrite_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# xupnpd-ipk
#	
xupnpd-ipk: $(D)/bootstrap $(D)/openssl
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGPREFIX)/etc/init.d
	install -d $(PKGS_DIR)
	$(REMOVE)/xupnpd
	set -e; if [ -d $(ARCHIVE)/xupnpd.git ]; \
		then cd $(ARCHIVE)/xupnpd.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/clark15b/xupnpd.git xupnpd.git; \
		fi
	cp -ra $(ARCHIVE)/xupnpd.git $(BUILD_TMP)/xupnpd
	($(CHDIR)/xupnpd; git checkout -q $(XUPNPD_BRANCH);)
	$(CHDIR)/xupnpd; \
		$(call apply_patches, $(XUPNPD_PATCH))
	$(CHDIR)/xupnpd/src; \
		$(BUILDENV) \
		$(MAKE) embedded TARGET=$(TARGET) PKG_CONFIG=$(PKG_CONFIG) LUAFLAGS="$(TARGET_LDFLAGS) -I$(TARGET_INCLUDE_DIR)"; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	install -m 755 $(SKEL_ROOT)/etc/init.d/xupnpd $(PKGPREFIX)/etc/init.d/
	mkdir -p $(PKGPREFIX)/usr/share/xupnpd/config
	$(REMOVE)/xupnpd
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/xupnpd && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/xupnpd_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# graphlcd-ipk
#
graphlcd-ipk: $(D)/bootstrap $(D)/freetype $(D)/libusb $(ARCHIVE)/$(GRAPHLCD_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGPREFIX)/etc
	install -d $(PKGS_DIR)
	$(REMOVE)/graphlcd-git-$(GRAPHLCD_VER)
	$(UNTAR)/$(GRAPHLCD_SOURCE)
	$(CHDIR)/graphlcd-git-$(GRAPHLCD_VER); \
		$(call apply_patches, $(GRAPHLCD_PATCH)); \
		$(MAKE) -C glcdgraphics all TARGET=$(TARGET)- DESTDIR=$(PKGPREFIX); \
		$(MAKE) -C glcddrivers all TARGET=$(TARGET)- DESTDIR=$(PKGPREFIX); \
		$(MAKE) -C glcdgraphics install DESTDIR=$(PKGPREFIX); \
		$(MAKE) -C glcddrivers install DESTDIR=$(PKGPREFIX); \
		cp -a graphlcd.conf $(PKGPREFIX)/etc
		rm -r $(PKGPREFIX)/usr/include
	$(REMOVE)/graphlcd-git-$(GRAPHLCD_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/graphlcd && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/graphlcd_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# lcd4linux-ipk
#
lcd4linux-ipk: $(D)/bootstrap $(D)/libusb_compat $(D)/gd $(D)/libusb $(D)/libdpf $(ARCHIVE)/$(LCD4LINUX_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGPREFIX)/etc/init.d
	install -d $(PKGS_DIR)
	$(REMOVE)/lcd4linux-git-$(LCD4LINUX_VER)
	$(UNTAR)/$(LCD4LINUX_SOURCE)
	$(CHDIR)/lcd4linux-git-$(LCD4LINUX_VER); \
		$(call apply_patches, $(LCD4LINUX_PATCH)); \
		$(BUILDENV) ./bootstrap $(SILENT_OPT); \
		$(BUILDENV) ./configure $(CONFIGURE_OPTS) $(SILENT_OPT) \
			--prefix=/usr \
			--with-drivers='DPF,SamsungSPF$(LCD4LINUX_DRV),PNG' \
			--with-plugins='all,!apm,!asterisk,!dbus,!dvb,!gps,!hddtemp,!huawei,!imon,!isdn,!kvv,!mpd,!mpris_dbus,!mysql,!pop3,!ppp,!python,!qnaplog,!raspi,!sample,!seti,!w1retap,!wireless,!xmms' \
			--without-ncurses \
		; \
		$(MAKE) vcs_version all; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	install -m 755 $(SKEL_ROOT)/etc/init.d/lcd4linux $(PKGPREFIX)/etc/init.d/
	install -D -m 0600 $(SKEL_ROOT)/etc/lcd4linux.conf $(PKGPREFIX)/etc/lcd4linux.conf
	$(REMOVE)/lcd4linux-git-$(LCD4LINUX_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/lcd4linux && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/lcd4linux_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# gstreamer-ipk
#
gstreamer-ipk: $(D)/bootstrap $(D)/libglib2 $(D)/libxml2 $(D)/glib_networking $(ARCHIVE)/$(GSTREAMER_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/gstreamer-$(GSTREAMER_VER)
	$(UNTAR)/$(GSTREAMER_SOURCE)
	$(CHDIR)/gstreamer-$(GSTREAMER_VER); \
		$(call apply_patches, $(GSTREAMER_PATCH)); \
		./autogen.sh --noconfigure $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
			--libexecdir=/usr/lib \
			--datarootdir=/.remove \
			--enable-silent-rules \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-tests \
			--disable-valgrind \
			--disable-gst-tracer-hooks \
			--disable-dependency-tracking \
			--disable-examples \
			--disable-check \
			$(GST_MAIN_CONFIG_DEBUG) \
			--disable-benchmarks \
			--disable-gtk-doc-html \
			ac_cv_header_valgrind_valgrind_h=no \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/gstreamer-$(GSTREAMER_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/gstreamer && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/gstreamer_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# gst_plugins_base-ipk
#
gst_plugins_base-ipk: $(D)/bootstrap $(D)/zlib $(D)/libglib2 $(D)/orc $(D)/gstreamer $(D)/alsa_lib $(D)/libogg $(D)/libvorbis $(ARCHIVE)/$(GST_PLUGINS_BASE_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/gst-plugins-base-$(GST_PLUGINS_BASE_VER)
	$(UNTAR)/$(GST_PLUGINS_BASE_SOURCE)
	$(CHDIR)/gst-plugins-base-$(GST_PLUGINS_BASE_VER); \
		$(call apply_patches, $(GST_PLUGINS_BASE_PATCH)); \
		./autogen.sh --noconfigure $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
			--datarootdir=/.remove \
			--enable-silent-rules \
			--disable-valgrind \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-examples \
			--disable-gtk-doc-html \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/gst-plugins-base-$(GST_PLUGINS_BASE_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/gst-plugins-base && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/gst-plugins-base_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# gst_plugins_good-ipk
#
gst_plugins_good-ipk: $(D)/bootstrap $(D)/libpng $(D)/libjpeg $(D)/gstreamer $(D)/gst_plugins_base $(D)/libsoup $(D)/flac $(ARCHIVE)/$(GST_PLUGINS_GOOD_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/gst-plugins-good-$(GST_PLUGINS_GOOD_VER)
	$(UNTAR)/$(GST_PLUGINS_GOOD_SOURCE)
	$(CHDIR)/gst-plugins-good-$(GST_PLUGINS_GOOD_VER); \
		$(call apply_patches, $(GST_PLUGINS_GOOD_PATCH)); \
		./autogen.sh --noconfigure $(SILENT_OPT); \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--datarootdir=/.remove \
			--enable-silent-rules \
			--disable-valgrind \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-examples \
			--disable-gtk-doc-html \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	$(REMOVE)/gst-plugins-good-$(GST_PLUGINS_GOOD_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/gst-plugins-good && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/gst-plugins-good_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# gst_plugins_bad-ipk
#
gst_plugins_bad-ipk: $(D)/bootstrap $(D)/libass $(D)/libcurl $(D)/libxml2 $(D)/openssl $(D)/librtmp $(D)/gstreamer $(D)/gst_plugins_base $(ARCHIVE)/$(GST_PLUGINS_BAD_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/gst-plugins-bad-$(GST_PLUGINS_BAD_VER)
	$(UNTAR)/$(GST_PLUGINS_BAD_SOURCE)
	$(CHDIR)/gst-plugins-bad-$(GST_PLUGINS_BAD_VER); \
		$(call apply_patches, $(GST_PLUGINS_BAD_PATCH)); \
		./autogen.sh --noconfigure $(SILENT_OPT); \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--datarootdir=/.remove \
			--enable-silent-rules \
			--disable-valgrind \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-examples \
			--disable-gtk-doc-html \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/gst-plugins-bad-$(GST_PLUGINS_BAD_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/gst-plugins-bad && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/gst-plugins-bad_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# gst_plugins_ugly-ipk
#
gst_plugins_ugly-ipk: $(D)/bootstrap $(D)/gstreamer $(D)/gst_plugins_base $(ARCHIVE)/$(GST_PLUGINS_UGLY_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/gst-plugins-ugly-$(GST_PLUGINS_UGLY_VER)
	$(UNTAR)/$(GST_PLUGINS_UGLY_SOURCE)
	$(CHDIR)/gst-plugins-ugly-$(GST_PLUGINS_UGLY_VER); \
		./autogen.sh --noconfigure $(SILENT_OPT); \
		$(CONFIGURE) \
			--prefix=/usr \
			--datarootdir=/.remove \
			--enable-silent-rules \
			--disable-valgrind \
			$(GST_PLUGIN_CONFIG_DEBUG) \
			--disable-examples \
			--disable-gtk-doc-html \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	$(REMOVE)/gst-plugins-ugly-$(GST_PLUGINS_UGLY_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/gst-plugins-ugly && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/gst-plugins-ugly_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# gst_plugins_subsink-ipk
#
gst_plugins_subsink-ipk: $(D)/bootstrap $(D)/gstreamer $(D)/gst_plugins_base $(D)/gst_plugins_good $(D)/gst_plugins_bad $(D)/gst_plugins_ugly
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/gstreamer-$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink
	set -e; if [ -d $(ARCHIVE)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink.git ]; \
		then cd $(ARCHIVE)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink.git; git pull; \
		else cd $(ARCHIVE); git clone https://github.com/christophecvr/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink.git gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink.git; \
		fi
	cp -ra $(ARCHIVE)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink.git $(BUILD_TMP)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink
	$(CHDIR)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink; \
		aclocal --force -I m4; \
		libtoolize --copy --ltdl --force; \
		autoconf --force; \
		autoheader --force; \
		automake --add-missing --copy --force-missing --foreign; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-silent-rules \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	$(REMOVE)/gstreamer$(GST_PLUGINS_SUBSINK_VER)-plugin-subsink
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/gst-plugins-subsink && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/gst-plugins-subsink_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# gst_plugins_dvbmediasink-ipk
#
gst_plugins_dvbmediasink-ipk: $(D)/bootstrap $(D)/gstreamer $(D)/gst_plugins_base $(D)/gst_plugins_good $(D)/gst_plugins_bad $(D)/gst_plugins_ugly $(D)/gst_plugin_subsink $(D)/libdca
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink
	set -e; if [ -d $(ARCHIVE)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink.git ]; \
		then cd $(ARCHIVE)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink.git; git pull; \
		else cd $(ARCHIVE); git clone -b gst-1.0 https://github.com/OpenPLi/gst-plugin-dvbmediasink.git gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink.git; \
		fi
	cp -ra $(ARCHIVE)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink.git $(BUILD_TMP)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink
	$(CHDIR)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink; \
		aclocal --force -I m4; \
		libtoolize --copy --ltdl --force; \
		autoconf --force; \
		autoheader --force; \
		automake --add-missing --copy --force-missing --foreign; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-silent-rules \
			--with-wma \
			--with-wmv \
			--with-pcm \
			--with-dts \
			--with-eac3 \
			--with-h265 \
			--with-vb6 \
			--with-vb8 \
			--with-vb9 \
			--with-spark \
			--with-gstversion=1.0 \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	$(REMOVE)/gstreamer$(GST_PLUGINS_DVBMEDIASINK_VER)-plugin-dvbmediasink
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/gst-plugins-dvbmediasink && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/gst-plugins-dvbmediasink_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# ffmpeg
#
ffmpeg-ipk: $(D)/bootstrap $(D)/openssl $(D)/bzip2 $(D)/freetype $(D)/libass $(D)/libxml2 $(D)/libroxml $(D)/librtmp $(ARCHIVE)/$(FFMPEG_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/ffmpeg-$(FFMPEG_VER)
	$(UNTAR)/$(FFMPEG_SOURCE)
	$(CHDIR)/ffmpeg-$(FFMPEG_VER); \
		$(call apply_patches, $(FFMPEG_PATCH)); \
		./configure $(SILENT_OPT) \
			--disable-ffplay \
			--disable-ffprobe \
			\
			--disable-doc \
			--disable-htmlpages \
			--disable-manpages \
			--disable-podpages \
			--disable-txtpages \
			\
			--disable-altivec \
			--disable-amd3dnow \
			--disable-amd3dnowext \
			--disable-mmx \
			--disable-mmxext \
			--disable-sse \
			--disable-sse2 \
			--disable-sse3 \
			--disable-ssse3 \
			--disable-sse4 \
			--disable-sse42 \
			--disable-avx \
			--disable-xop \
			--disable-fma3 \
			--disable-fma4 \
			--disable-avx2 \
			--disable-armv5te \
			--disable-armv6 \
			--disable-armv6t2 \
			--disable-vfp \
			--disable-inline-asm \
			--disable-mips32r2 \
			--disable-mipsdsp \
			--disable-mipsdspr2 \
			--disable-fast-unaligned \
			\
			--disable-dxva2 \
			--disable-vaapi \
			--disable-vdpau \
			\
			--disable-muxers \
			--enable-muxer=apng \
			--enable-muxer=flac \
			--enable-muxer=mp3 \
			--enable-muxer=h261 \
			--enable-muxer=h263 \
			--enable-muxer=h264 \
			--enable-muxer=hevc \
			--enable-muxer=image2 \
			--enable-muxer=image2pipe \
			--enable-muxer=m4v \
			--enable-muxer=matroska \
			--enable-muxer=mjpeg \
			--enable-muxer=mp4 \
			--enable-muxer=mpeg1video \
			--enable-muxer=mpeg2video \
			--enable-muxer=mpegts \
			--enable-muxer=ogg \
			\
			--disable-parsers \
			--enable-parser=aac \
			--enable-parser=aac_latm \
			--enable-parser=ac3 \
			--enable-parser=dca \
			--enable-parser=dvbsub \
			--enable-parser=dvd_nav \
			--enable-parser=dvdsub \
			--enable-parser=flac \
			--enable-parser=h264 \
			--enable-parser=hevc \
			--enable-parser=mjpeg \
			--enable-parser=mpeg4video \
			--enable-parser=mpegvideo \
			--enable-parser=mpegaudio \
			--enable-parser=png \
			--enable-parser=vc1 \
			--enable-parser=vorbis \
			--enable-parser=vp8 \
			--enable-parser=vp9 \
			\
			--disable-encoders \
			--enable-encoder=aac \
			--enable-encoder=h261 \
			--enable-encoder=h263 \
			--enable-encoder=h263p \
			--enable-encoder=jpeg2000 \
			--enable-encoder=jpegls \
			--enable-encoder=ljpeg \
			--enable-encoder=mjpeg \
			--enable-encoder=mpeg1video \
			--enable-encoder=mpeg2video \
			--enable-encoder=mpeg4 \
			--enable-encoder=png \
			--enable-encoder=rawvideo \
			\
			--disable-decoders \
			--enable-decoder=aac \
			--enable-decoder=aac_latm \
			--enable-decoder=adpcm_ct \
			--enable-decoder=adpcm_g722 \
			--enable-decoder=adpcm_g726 \
			--enable-decoder=adpcm_g726le \
			--enable-decoder=adpcm_ima_amv \
			--enable-decoder=adpcm_ima_oki \
			--enable-decoder=adpcm_ima_qt \
			--enable-decoder=adpcm_ima_rad \
			--enable-decoder=adpcm_ima_wav \
			--enable-decoder=adpcm_ms \
			--enable-decoder=adpcm_sbpro_2 \
			--enable-decoder=adpcm_sbpro_3 \
			--enable-decoder=adpcm_sbpro_4 \
			--enable-decoder=adpcm_swf \
			--enable-decoder=adpcm_yamaha \
			--enable-decoder=alac \
			--enable-decoder=ape \
			--enable-decoder=atrac1 \
			--enable-decoder=atrac3 \
			--enable-decoder=atrac3p \
			--enable-decoder=ass \
			--enable-decoder=cook \
			--enable-decoder=dca \
			--enable-decoder=dsd_lsbf \
			--enable-decoder=dsd_lsbf_planar \
			--enable-decoder=dsd_msbf \
			--enable-decoder=dsd_msbf_planar \
			--enable-decoder=dvbsub \
			--enable-decoder=dvdsub \
			--enable-decoder=eac3 \
			--enable-decoder=evrc \
			--enable-decoder=flac \
			--enable-decoder=g723_1 \
			--enable-decoder=g729 \
			--enable-decoder=h261 \
			--enable-decoder=h263 \
			--enable-decoder=h263i \
			--enable-decoder=h264 \
			--enable-decoder=hevc \
			--enable-decoder=iac \
			--enable-decoder=imc \
			--enable-decoder=jpeg2000 \
			--enable-decoder=jpegls \
			--enable-decoder=mace3 \
			--enable-decoder=mace6 \
			--enable-decoder=metasound \
			--enable-decoder=mjpeg \
			--enable-decoder=mlp \
			--enable-decoder=movtext \
			--enable-decoder=mp1 \
			--enable-decoder=mp2 \
			--enable-decoder=mp3 \
			--enable-decoder=mp3adu \
			--enable-decoder=mp3on4 \
			--enable-decoder=mpeg1video \
			--enable-decoder=mpeg2video \
			--enable-decoder=mpeg4 \
			--enable-decoder=nellymoser \
			--enable-decoder=opus \
			--enable-decoder=pcm_alaw \
			--enable-decoder=pcm_bluray \
			--enable-decoder=pcm_dvd \
			--enable-decoder=pcm_f32be \
			--enable-decoder=pcm_f32le \
			--enable-decoder=pcm_f64be \
			--enable-decoder=pcm_f64le \
			--enable-decoder=pcm_lxf \
			--enable-decoder=pcm_mulaw \
			--enable-decoder=pcm_s16be \
			--enable-decoder=pcm_s16be_planar \
			--enable-decoder=pcm_s16le \
			--enable-decoder=pcm_s16le_planar \
			--enable-decoder=pcm_s24be \
			--enable-decoder=pcm_s24daud \
			--enable-decoder=pcm_s24le \
			--enable-decoder=pcm_s24le_planar \
			--enable-decoder=pcm_s32be \
			--enable-decoder=pcm_s32le \
			--enable-decoder=pcm_s32le_planar \
			--enable-decoder=pcm_s8 \
			--enable-decoder=pcm_s8_planar \
			--enable-decoder=pcm_u16be \
			--enable-decoder=pcm_u16le \
			--enable-decoder=pcm_u24be \
			--enable-decoder=pcm_u24le \
			--enable-decoder=pcm_u32be \
			--enable-decoder=pcm_u32le \
			--enable-decoder=pcm_u8 \
			--enable-decoder=pgssub \
			--enable-decoder=png \
			--enable-decoder=qcelp \
			--enable-decoder=qdm2 \
			--enable-decoder=ra_144 \
			--enable-decoder=ra_288 \
			--enable-decoder=ralf \
			--enable-decoder=s302m \
			--enable-decoder=sipr \
			--enable-decoder=shorten \
			--enable-decoder=sonic \
			--enable-decoder=srt \
			--enable-decoder=ssa \
			--enable-decoder=subrip \
			--enable-decoder=subviewer \
			--enable-decoder=subviewer1 \
			--enable-decoder=tak \
			--enable-decoder=text \
			--enable-decoder=truehd \
			--enable-decoder=truespeech \
			--enable-decoder=tta \
			--enable-decoder=vorbis \
			--enable-decoder=wmalossless \
			--enable-decoder=wmapro \
			--enable-decoder=wmav1 \
			--enable-decoder=wmav2 \
			--enable-decoder=wmavoice \
			--enable-decoder=wavpack \
			--enable-decoder=xsub \
			\
			--disable-demuxers \
			--enable-demuxer=aac \
			--enable-demuxer=ac3 \
			--enable-demuxer=apng \
			--enable-demuxer=ass \
			--enable-demuxer=avi \
			--enable-demuxer=dts \
			--enable-demuxer=dash \
			--enable-demuxer=ffmetadata \
			--enable-demuxer=flac \
			--enable-demuxer=flv \
			--enable-demuxer=h264 \
			--enable-demuxer=hls \
			--enable-demuxer=image2 \
			--enable-demuxer=image2pipe \
			--enable-demuxer=image_bmp_pipe \
			--enable-demuxer=image_jpeg_pipe \
			--enable-demuxer=image_jpegls_pipe \
			--enable-demuxer=image_png_pipe \
			--enable-demuxer=m4v \
			--enable-demuxer=matroska \
			--enable-demuxer=mjpeg \
			--enable-demuxer=mov \
			--enable-demuxer=mp3 \
			--enable-demuxer=mpegts \
			--enable-demuxer=mpegtsraw \
			--enable-demuxer=mpegps \
			--enable-demuxer=mpegvideo \
			--enable-demuxer=mpjpeg \
			--enable-demuxer=ogg \
			--enable-demuxer=pcm_s16be \
			--enable-demuxer=pcm_s16le \
			--enable-demuxer=realtext \
			--enable-demuxer=rawvideo \
			--enable-demuxer=rm \
			--enable-demuxer=rtp \
			--enable-demuxer=rtsp \
			--enable-demuxer=srt \
			--enable-demuxer=vc1 \
			--enable-demuxer=wav \
			--enable-demuxer=webm_dash_manifest \
			\
			--disable-filters \
			--enable-filter=scale \
			--enable-filter=drawtext \
			\
			--enable-zlib \
			--enable-bzlib \
			--enable-openssl \
			--enable-libass \
			--enable-bsfs \
			--disable-xlib \
			--disable-libxcb \
			--disable-libxcb-shm \
			--disable-libxcb-xfixes \
			--disable-libxcb-shape \
			\
			$(FFMPEG_CONF_OPTS) \
			\
			--enable-shared \
			--enable-network \
			--enable-nonfree \
			--disable-static \
			--disable-debug \
			--disable-runtime-cpudetect \
			--enable-pic \
			--enable-pthreads \
			--enable-hardcoded-tables \
			--disable-optimizations \
			\
			--pkg-config=pkg-config \
			--enable-cross-compile \
			--cross-prefix=$(TARGET)- \
			--extra-cflags="$(TARGET_CFLAGS) $(FFMPRG_EXTRA_CFLAGS)" \
			--extra-ldflags="$(TARGET_LDFLAGS) -lrt" \
			--arch=$(BOXARCH) \
			--target-os=linux \
			--prefix=/usr \
			--bindir=/sbin \
			--mandir=/.remove \
			--datadir=/.remove \
			--docdir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/ffmpeg-$(FFMPEG_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/ffmpeg && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/ffmpeg_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# lua
#
lua-ipk: $(D)/bootstrap $(D)/ncurses $(ARCHIVE)/$(LUAPOSIX_SOURCE) $(ARCHIVE)/$(LUA_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/lua-$(LUA_VER)
	mkdir -p $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(UNTAR)/$(LUA_SOURCE)
	$(CHDIR)/lua-$(LUA_VER); \
		$(call apply_patches, $(LUAPOSIX_PATCH)); \
		tar xf $(ARCHIVE)/$(LUAPOSIX_SOURCE); \
		cd luaposix-git-$(LUAPOSIX_VER)/ext; cp posix/posix.c include/lua52compat.h ../../src/; cd ../..; \
		cd luaposix-git-$(LUAPOSIX_VER)/lib; cp *.lua $(TARGET_DIR)/usr/share/lua/$(LUA_VER_SHORT); cd ../..; \
		sed -i 's/<config.h>/"config.h"/' src/posix.c; \
		sed -i '/^#define/d' src/lua52compat.h; \
		sed -i 's|man/man1|/.remove|' Makefile; \
		$(MAKE) linux CC=$(TARGET)-gcc CPPFLAGS="$(TARGET_CPPFLAGS) -fPIC" LDFLAGS="-L$(TARGET_DIR)/usr/lib" BUILDMODE=dynamic PKG_VERSION=$(LUA_VER); \
		$(MAKE) install INSTALL_TOP=$(PKGPREFIX)/usr INSTALL_MAN=$(PKGPREFIX)/.remove
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/bin/luac
	$(REMOVE)/lua-$(LUA_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/lua && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/lua_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# luacurl-ipk
#
luacurl-ipk: $(D)/bootstrap $(D)/libcurl $(D)/lua $(ARCHIVE)/$(LUACURL_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/luacurl-git-$(LUACURL_VER)
	$(UNTAR)/$(LUACURL_SOURCE)
	$(CHDIR)/luacurl-git-$(LUACURL_VER); \
		$(MAKE) CC=$(TARGET)-gcc LDFLAGS="-L$(TARGET_DIR)/usr/lib" \
			LIBDIR=$(TARGET_DIR)/usr/lib \
			LUA_INC=$(TARGET_DIR)/usr/include; \
		$(MAKE) install DESTDIR=$(PKGPREFIX) LUA_CMOD=/usr/lib/lua/$(LUA_VER_SHORT) LUA_LMOD=/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luacurl-git-$(LUACURL_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/luacurl && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/luacurl_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# luaexpat-ipk
#
luaexpat-ipk: $(D)/bootstrap $(D)/lua $(D)/expat $(ARCHIVE)/$(LUAEXPAT_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/luaexpat-$(LUAEXPAT_VER)
	$(UNTAR)/$(LUAEXPAT_SOURCE)
	$(CHDIR)/luaexpat-$(LUAEXPAT_VER); \
		$(call apply_patches, $(LUAEXPAT_PATCH)); \
		$(MAKE) CC=$(TARGET)-gcc LDFLAGS="-L$(TARGET_DIR)/usr/lib" PREFIX=$(TARGET_DIR)/usr; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)/usr
	$(REMOVE)/luaexpat-$(LUAEXPAT_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/luaexpat && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/luaexpat_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# luasocket-ipk
#	
luasocket-ipk: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUASOCKET_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/luasocket-git-$(LUASOCKET_VER)
	$(UNTAR)/$(LUASOCKET_SOURCE)
	$(CHDIR)/luasocket-git-$(LUASOCKET_VER); \
		sed -i -e "s@LD_linux=gcc@LD_LINUX=$(TARGET)-gcc@" -e "s@CC_linux=gcc@CC_LINUX=$(TARGET)-gcc -L$(TARGET_DIR)/usr/lib@" -e "s@DESTDIR?=@DESTDIR?=$(PKGPREFIX)/usr@" src/makefile; \
		$(MAKE) CC=$(TARGET)-gcc LD=$(TARGET)-gcc LUAV=$(LUA_VER_SHORT) PLAT=linux COMPAT=COMPAT LUAINC_linux=$(TARGET_DIR)/usr/include LUAPREFIX_linux=; \
		$(MAKE) install LUAPREFIX_linux= LUAV=$(LUA_VER_SHORT)
	$(REMOVE)/luasocket-git-$(LUASOCKET_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/luasocket && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/luasocket_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# luafeedparser-ipk
#
luafeedparser-ipk: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUAFEEDPARSER_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luafeedparser-git-$(LUAFEEDPARSER_VER)
	$(UNTAR)/$(LUAFEEDPARSER_SOURCE)
	$(CHDIR)/luafeedparser-git-$(LUAFEEDPARSER_VER); \
		sed -i -e "s/^PREFIX.*//" -e "s/^LUA_DIR.*//" Makefile ; \
		$(BUILDENV) $(MAKE) install  LUA_DIR=$(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luafeedparser-git-$(LUAFEEDPARSER_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/luafeedparser && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/luafeedparser_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# luasoap-ipk
#
luasoap-ipk: $(D)/bootstrap $(D)/lua $(ARCHIVE)/$(LUASOAP_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luasoap-$(LUASOAP_VER)
	$(UNTAR)/$(LUASOAP_SOURCE)
	$(CHDIR)/luasoap-$(LUASOAP_VER); \
		$(call apply_patches, $(LUASOAP_PATCH)); \
		$(MAKE) install LUA_DIR=$(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	$(REMOVE)/luasoap-$(LUASOAP_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/luasoap && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/luasoap_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# luajson-ipk
#
luajson-ipk: $(D)/bootstrap $(D)/lua $(ARCHIVE)/json.lua
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	install -d $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)
	cp $(ARCHIVE)/json.lua $(PKGPREFIX)/usr/share/lua/$(LUA_VER_SHORT)/json.lua
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/luajson && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/luajson_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# python
#
python-ipk: $(D)/bootstrap $(D)/host_python $(D)/ncurses $(D)/zlib $(D)/openssl $(D)/libffi $(D)/bzip2 $(D)/readline $(D)/sqlite $(ARCHIVE)/$(PYTHON_SOURCE)
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(REMOVE)/Python-$(PYTHON_VER)
	$(UNTAR)/$(PYTHON_SOURCE)
	$(CHDIR)/Python-$(PYTHON_VER); \
		$(call apply_patches, $(PYTHON_PATCH)); \
		CONFIG_SITE= \
		$(BUILDENV) \
		autoreconf -fiv Modules/_ctypes/libffi; \
		autoconf $(SILENT_OPT); \
		./configure $(SILENT_OPT) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc \
			--enable-shared \
			--with-lto \
			--enable-ipv6 \
			--with-threads \
			--with-pymalloc \
			--with-signal-module \
			--with-wctype-functions \
			ac_sys_system=Linux \
			ac_sys_release=2 \
			ac_cv_file__dev_ptmx=no \
			ac_cv_file__dev_ptc=no \
			ac_cv_have_long_long_format=yes \
			ac_cv_no_strict_aliasing_ok=yes \
			ac_cv_pthread=yes \
			ac_cv_cxx_thread=yes \
			ac_cv_sizeof_off_t=8 \
			ac_cv_have_chflags=no \
			ac_cv_have_lchflags=no \
			ac_cv_py_format_size_t=yes \
			ac_cv_broken_sem_getvalue=no \
			HOSTPYTHON=$(HOST_DIR)/bin/python$(PYTHON_VER_MAJOR) \
		; \
		$(MAKE) $(MAKE_OPTS) \
			PYTHON_MODULES_INCLUDE="$(PKGPREFIX)/usr/include" \
			PYTHON_MODULES_LIB="$(PKGPREFIX)/usr/lib" \
			PYTHON_XCOMPILE_DEPENDENCIES_PREFIX="$(PKGPREFIX)" \
			CROSS_COMPILE_TARGET=yes \
			CROSS_COMPILE=$(TARGET) \
			MACHDEP=linux2 \
			HOSTARCH=$(TARGET) \
			CFLAGS="$(TARGET_CFLAGS)" \
			LDFLAGS="$(TARGET_LDFLAGS)" \
			LD="$(TARGET)-gcc" \
			HOSTPYTHON=$(HOST_DIR)/bin/python$(PYTHON_VER_MAJOR) \
			HOSTPGEN=$(HOST_DIR)/bin/pgen \
			all DESTDIR=$(PKGPREFIX) \
		; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	ln -sf ../../libpython$(PYTHON_VER_MAJOR).so.1.0 $(PKGPREFIX)/$(PYTHON_DIR)/config/libpython$(PYTHON_VER_MAJOR).so; \
	ln -sf $(PKGPREFIX)/$(PYTHON_INCLUDE_DIR) $(TARGET_DIR)/usr/include/python
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
	$(REMOVE)/Python-$(PYTHON_VER)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/python && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/python_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# aio-grab-ipk
#
aio-grab-ipk: $(D)/bootstrap $(D)/libpng $(D)/libjpeg
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	set -e; cd $(APPS_DIR)/tools/aio-grab-$(BOXARCH); \
		$(CONFIGURE_TOOLS) CPPFLAGS="$(CPPFLAGS) -I$(DRIVER_DIR)/bpamem" \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/aio-grab && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/aio-grab_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# exteplayer3-ipk
#
exteplayer3-ipk: $(D)/bootstrap $(D)/ffmpeg $(D)/libass
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	set -e; cd $(APPS_DIR)/tools/$(TOOLS_EXTEPLAYER3); \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/exteplayer3 && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/exteplayer3_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# showiframe-ipk
#
showiframe-ipk: $(D)/bootstrap
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	set -e; cd $(APPS_DIR)/tools/showiframe-$(BOXARCH); \
		$(CONFIGURE_TOOLS) \
			--prefix= \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/showiframe && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/showiframe_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# neutrino-ipk
#
$(PKGPREFIX)/.version:
	echo "distro=$(MAINTAINER)" > $@
	echo "imagename=`sed -n 's/\#define PACKAGE_NAME "//p' $(N_OBJDIR)/config.h | sed 's/"//'`" >> $@
	echo "imageversion=`sed -n 's/\#define PACKAGE_VERSION "//p' $(N_OBJDIR)/config.h | sed 's/"//'`" >> $@
	echo "homepage=https://github.com/Duckbox-Developers" >> $@
	echo "creator=$(MAINTAINER)" >> $@
	echo "docs=https://github.com/Duckbox-Developers" >> $@
	echo "forum=https://github.com/Duckbox-Developers/neutrino-ddt" >> $@
	echo "version=0200`date +%Y%m%d%H%M`" >> $@
	echo "git=`git log | grep "^commit" | wc -l`" >> $@
	
$(D)/neutrino-ipk: $(D)/neutrino.do_prepare $(D)/neutrino.do_compile
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(PKGPREFIX); \
	rm -f $(PKGPREFIX)/.version
	make $(PKGPREFIX)/.version
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/neutrino && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/neutrino_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)

#
# titan
#
titan-ipk: $(D)/titan.do_compile
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(MAKE) -C $(SOURCE_DIR)/titan install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/titan && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/titan_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# enigma2-ipk
#
enigma2-ipk: $(D)/enigma2.do_compile
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(MAKE) -C $(SOURCE_DIR)/enigma2 install DESTDIR=$(PKGPREFIX)
	rm -r $(PKGPREFIX)/usr/include $(PKGPREFIX)/usr/lib/pkgconfig
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/enigma2 && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/enigma2_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# neutrino2
#
neutrino2-ipk: $(D)/neutrino2.do_compile
	$(START_BUILD)
	rm -rf $(PKGPREFIX)
	install -d $(PKGPREFIX)
	install -d $(PKGS_DIR)
	$(MAKE) -C $(SOURCE_DIR)/neutrino2/neutrino2 install DESTDIR=$(PKGPREFIX)
ifneq ($(OPTIMIZATIONS), $(filter $(OPTIMIZATIONS), kerneldebug debug normal))
	find $(PKGPREFIX)/ -name '*' -exec $(TARGET)-strip --strip-unneeded {} &>/dev/null \;
endif
	cd $(PKGPREFIX) && tar -cvzf $(PKGS_DIR)/data.tar.gz *
	cd $(PACKAGES)/neutrino2 && tar -cvzf $(PKGS_DIR)/control.tar.gz *
	cd $(PKGS_DIR) && echo 2.0 > debian-binary && tar -cvzf $(PKGS_DIR)/neutrino2_$(BOXARCH).tar.gz data.tar.gz control.tar.gz debian-binary && rm -rf data.tar.gz control.tar.gz debian-binary
	rm -rf $(PKGPREFIX)
	$(END_BUILD)
	
#
# pkg-clean
#
ipk-clean:
	cd $(PKGS_DIR) && rm -rf *
		

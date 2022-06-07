#!/bin/bash
if [ `id -u` != 0 ]; then
	echo "You are not running this script as root. Try it again as root or with \"sudo ./tf7700.sh\"."
	echo "Bye Bye..."
	exit
fi

CURDIR=`pwd`
BASEDIR=$CURDIR/../..

TUFSBOXDIR=$BASEDIR/tufsbox/tf7700
TMPDIR=$CURDIR/tmp
TMPROOTDIR=$TMPDIR/ROOT
OUTDIR=$TUFSBOXDIR/image
RELEASEDIR=$TUFSBOXDIR/release

if [ -e $TMPDIR ]; then
	rm -rf $TMPDIR/*
fi

mkdir -p $TMPDIR
mkdir -p $TMPROOTDIR

echo ""
echo "-----------------------------------------------------------------------"
echo "Creating image..."

cp -a $RELEASEDIR/* $TMPROOTDIR
cp $RELEASEDIR/.version $TMPROOTDIR

if [ ! -e $TMPROOTDIR/dev/mtd0 ]; then
	cd $TMPROOTDIR/dev/
	if [ -e $TMPROOTDIR/var/etc/init.d/makedev ]; then
		$TMPROOTDIR/var/etc/init.d/makedev start
	else
		$TMPROOTDIR/etc/init.d/makedev start
	fi
	#correct some devices
	rm -f vfd
	rm -f rc
	rm -f fpc
	mknod -m 0666 fpc     c 62 0 2>/dev/null
	mknod -m 0666 vfd     c 62 0 2>/dev/null
	mknod -m 0666 rc      c 62 1 2>/dev/null
	mknod -m 0666 fplarge c 62 2 2>/dev/null
	mknod -m 0666 fpsmall c 62 3 2>/dev/null
	cd -
fi

if [ -f $TMPROOTDIR/etc/hostname ]; then
	BOXTYPE=`cat $TMPROOTDIR/etc/hostname`
elif [ -f $TMPROOTDIR/var/etc/hostname ]; then
	BOXTYPE=`cat $TMPROOTDIR/var/etc/hostname`
fi

. $CURDIR/../common/gitversion.sh $CURDIR $BOXTYPE

OUTFILE=$OUTDIR/$BOXTYPE$gitversion

TFINSTALLERDIR=$BASEDIR/hostapps/tfinstaller

rm -rf $OUTDIR
mkdir -p $OUTDIR

cp $TFINSTALLERDIR/Enigma_Installer.ini $OUTDIR/
cp $TFINSTALLERDIR/Enigma_Installer.tfd $OUTDIR/
cp $TFINSTALLERDIR/uImage $CURDIR/out/

UIMAGESIZE=`stat -c %s $TFINSTALLERDIR/uImage`
if [ "$UIMAGESIZE" == "0" -o "$UIMAGESIZE" == "" ]; then
	echo -e "\033[01;31m"
	echo "!!! WARNING: UIMAGE SIZE IS ZERO OR MISSING !!!"
	echo "RUN MAKE tfinstaller FIRST !!!"
	echo  "-----------------------------------------------------------------------"
	echo -e "\033[00m"
fi

echo "-----------------------------------------------------------------------"

cd $TMPROOTDIR/
tar -cvzf $CURDIR/out/rootfs.tar.gz *
cd -

zip -j $OUTFILE.zip $OUTDIR/Enigma_Installer.ini $OUTDIR/Enigma_Installer.tfd $OUTDIR/uImage $OUTDIR/rootfs.tar.gz

echo "-----------------------------------------------------------------------"

AUDIOELFSIZE=`stat -c %s $TMPROOTDIR/lib/firmware/audio.elf`
if [ "$AUDIOELFSIZE" == "0" -o "$AUDIOELFSIZE" == "" ]; then
	echo -e "\033[01;31m"
	echo "!!! WARNING: AUDIOELF SIZE IS ZERO OR MISSING !!!"
	echo "IF YOUR ARE CREATING THE FW PART MAKE SURE THAT YOU USE CORRECT ELFS"
	echo -e "\033[00m"
fi

VIDEOELFSIZE=`stat -c %s $TMPROOTDIR/lib/firmware/audio.elf`
if [ "$VIDEOELFSIZE" == "0" -o "$VIDEOELFSIZE" == "" ]; then
	echo -e "\033[01;31m"
	echo "!!! WARNING: VIDEOELF SIZE IS ZERO OR MISSING !!!"
	echo "IF YOUR ARE CREATING THE FW PART MAKE SURE THAT YOU USE CORRECT ELFS"
	echo -e "\033[00m"
fi

if [ ! -e $TMPROOTDIR/dev/mtd0 ]; then
	echo -e "\033[01;31m"
	echo "!!! WARNING: DEVS ARE MISSING !!!"
	echo "IF YOUR ARE CREATING THE ROOT PART MAKE SURE THAT YOU USE A CORRECT DEV.TAR"
	echo -e "\033[00m"
fi

rm -f $OUTDIR/Enigma_Installer.ini
rm -f $OUTDIR/Enigma_Installer.tfd
rm -f $OUTDIR/uImage
rm -f $OUTDIR/rootfs.tar.gz
rm -rf $TMPDIR

[ "$1" != "" ] && chown -R $1:users $OUTDIR/

echo "Flashimage created:"
echo ""

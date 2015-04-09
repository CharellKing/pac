#!/bin/bash

if [ $(whoami) != "root" ]
then
	echo "*******************************"
	echo "You moust run $0 as user 'root'"
	echo "*******************************"
	exit 1;
fi

cd /opt/david/pac
rm -rf pac/
cp pac.list pacmanager-code/pac.list
cp -r pacmanager-code/ pac/
find /opt/david/pac/pac -name "*.svn" | xargs rm -rf

# Get version from PACUtils.pm module
V=$(grep "our \$APPVERSION" pac/lib/PACUtils.pm | awk -F"'" '{print $2;}')

echo "**********************************"
echo "**********************************"
echo "Creating packages for PAC ${V}..."
echo "**********************************"
echo "**********************************"
echo ""

rm -rf meta
rm -f dist/*

# First of all, change %version in pac.list
echo "----------------------------------------------"
echo " - Changing version in 'pac.list' to ${V}..."
echo "----------------------------------------------"
echo ""
sed "s/%version .*/%version $V/g" pac.list > pac.list.new
if [ $? -ne 0 ];
then
	echo " *********** ERROR ************"
	exit $?
fi
mv pac.list.new pac.list
cp pac.list make.sh pac/
chown -R david:david pac/

# .tar.gz
echo "----------------------------------------------"
echo " - Creating '.tar.gz' package for PAC ${V}..."
echo "----------------------------------------------"
echo ""
tar -czf pac-${V}-all.tar.gz pac
chown david:david pac-${V}-all.tar.gz
mv pac-${V}-all.tar.gz dist/

# DEB
echo "----------------------------------------------"
echo " - Creating '.deb' package for PAC ${V}..."
echo "----------------------------------------------"
echo ""
epm -v --keep-files -f deb pac -m meta
if [ $? -ne 0 ]; then
	echo " *********** ERROR ************"
	exit $?
fi

sed 's/Architecture:.*/Architecture: all/g' meta/pac-${V}-meta/DEBIAN/control > meta/pac-${V}-meta/DEBIAN/control.new
mv meta/pac-${V}-meta/DEBIAN/control.new meta/pac-${V}-meta/DEBIAN/control
echo "Recommends: xtightvncviewer, rdesktop, libgtk2-appindicator-perl, libgtk2-sourceview2-perl, autossh, remote-tty, cu, c3270, mosh" >> meta/pac-${V}-meta/DEBIAN/control
echo "Section: networking" >> meta/pac-${V}-meta/DEBIAN/control
echo "Installed-Size: 4300" >> meta/pac-${V}-meta/DEBIAN/control
echo "Homepage: http://sourceforge.net/projects/pacmanager/" >> meta/pac-${V}-meta/DEBIAN/control
echo "Provides: pac-manager" >> meta/pac-${V}-meta/DEBIAN/control
echo "Priority: optional" >> meta/pac-${V}-meta/DEBIAN/control

dpkg -D1 -b meta/pac-${V}-meta pac-${V}-all.deb
chown david:david pac-${V}-all.deb
mv pac-${V}-all.deb dist/

# RPM
if [ 1 -eq 1 ]; then
	echo "----------------------------------------------"
	echo " - Creating 32/64 bit '.rpm' package for PAC ${V}..."
	echo "----------------------------------------------"
	echo ""
	alien -g -r --scripts dist/pac-${V}-all.deb
	if [ $? -ne 0 ]; then
		echo " *********** ERROR ************"
		exit $?
	fi
	sed "s/^Group:.*/Group: Converted\/networking\nRequires: perl vte ftp telnet perl-Gtk2-Unique perl-IO-Stty perl-Crypt-Blowfish perl-Crypt-Rijndael/g" pac-${V}/pac-${V}-2.spec > pac-${V}/pac-${V}-2.spec.new
	sed 's/^%dir "\/"//g' pac-${V}/pac-${V}-2.spec.new > pac-${V}/pac-${V}-2.spec.new.2
	sed 's/^%dir "\/usr\/bin\/"//g' pac-${V}/pac-${V}-2.spec.new.2 > pac-${V}/pac-${V}-2.spec.new.3
	mv pac-${V}/pac-${V}-2.spec.new.3 pac-${V}/pac-${V}-2.spec
	rm pac-${V}/pac-${V}-2.spec.new.2 pac-${V}/pac-${V}-2.spec.new
	cp -r pac-${V} pac-${V}.64
	echo ""
	echo " ------ Creating 32 bit '.rpm' package for PAC ${V}..."
	rpmbuild --quiet -bb --buildroot $(pwd)/pac-${V} --target i386 pac-${V}/pac-${V}-2.spec
	mv pac-${V}.64 pac-${V}
	echo " ------ Creating 64 bit '.rpm' package for PAC ${V}..."
	rpmbuild --quiet -bb --clean --buildroot $(pwd)/pac-${V} --target x86_64 pac-${V}/pac-${V}-2.spec

	mv ../pac-${V}-2.*.rpm dist/
fi

echo ""
echo "--------------------------"
echo "- List of generated files:"
echo "--------------------------"
ls -lF dist/

# Empty temp dir
rm -rf meta
rm -rf /home/david/rpmbuild
rm -rf /opt/david/pac/pac

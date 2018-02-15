#!/bin/bash
set -e

scriptdir=$(dirname $0)

# add ppas
apt-get -qq update
apt-get -qq install software-properties-common
add-apt-repository -y ppa:beineri/opt-qt594-xenial
add-apt-repository -y ppa:skycoder42/qt-modules-opt
add-apt-repository -y ppa:ubuntu-toolchain-r/test

# install build deps
apt-get -qq update
apt-get -qq install --no-install-recommends libgl1-mesa-dev libglib2.0-0 libpulse-dev make g++ git ca-certificates curl xauth libx11-xcb1 libfontconfig1 libdbus-1-3 python3 doxygen qpmx-opt gcc-6 g++-6 $EXTRA_PKG

# install qpm
curl -Lo /tmp/qpm https://www.qpm.io/download/v0.10.0/linux_386/qpm
install -m 755 /tmp/qpm /usr/local/bin/

# create installer script
qtvid=$(echo $QT_VER | sed -e "s/\\.//g")
echo "qtVersion = \"$qtvid\";" > $scriptdir/qt-installer-script.qs
if [[ "$PLATFORM" == "static" ]]; then
	echo "platform = \"src\";" >> $scriptdir/qt-installer-script.qs
else
	echo "platform = \"$PLATFORM\";" >> $scriptdir/qt-installer-script.qs
fi
echo "extraMods = [];" >> $scriptdir/qt-installer-script.qs
for mod in $EXTRA_MODULES; do
	echo "extraMods.push(\"$mod\");" >> $scriptdir/qt-installer-script.qs
done
cat $scriptdir/qt-installer-script-base.qs >> $scriptdir/qt-installer-script.qs

# install Qt
curl -Lo /tmp/installer.run https://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run
chmod +x /tmp/installer.run
if ! QT_QPA_PLATFORM=minimal /tmp/installer.run --script $scriptdir/qt-installer-script.qs --addTempRepository https://install.skycoder42.de/qtmodules/linux_x64 --verbose > /tmp/installer.log; then
	cat /tmp/installer.log
	exit 1
fi

# update gcc for linux
if [[ "$PLATFORM" == "static" ]]; then
	TPLATFORM="Src/qtbase"
else
	TPLATFORM=$PLATFORM
fi

echo "QMAKE_CXX=g++-6" >> /opt/qt/$QT_VER/$TPLATFORM/mkspecs/linux-g++/qmake.conf
echo "QMAKE_CC=gcc-6" >> /opt/qt/$QT_VER/$TPLATFORM/mkspecs/linux-g++/qmake.conf
echo "QMAKE_CXX=g++-6" >> /opt/qt/$QT_VER/$TPLATFORM/mkspecs/linux-g++-32/qmake.conf
echo "QMAKE_CC=gcc-6" >> /opt/qt/$QT_VER/$TPLATFORM/mkspecs/linux-g++-32/qmake.conf
echo "QMAKE_CXX=g++-6" >> /opt/qt/$QT_VER/$TPLATFORM/mkspecs/linux-g++-64/qmake.conf
echo "QMAKE_CC=gcc-6" >> /opt/qt/$QT_VER/$TPLATFORM/mkspecs/linux-g++-64/qmake.conf

rm -rf /opt/qt/Examples
rm -rf /opt/qt/Docs
rm -rf /opt/qt/Tools/QtCreator

#!/bin/bash
set -ex

distro="{}"
pkgname="{}"
mode="{}"
debpkgs="{}"
optver="{}"
noupload="{}"

cd /debbuild

# install ppa
apt-get -qq update
apt-get -qq install software-properties-common apt-utils
apt-get -qq upgrade
if [ "$mode" == "opt" ]; then
	add-apt-repository -y ppa:beineri/opt-qt${{optver}}-xenial
	add-apt-repository -y ppa:skycoder42/qt-modules-opt
else
	add-apt-repository -y ppa:skycoder42/qt-modules
fi

# install deps
apt-get -qq update
apt-get -qq install --no-install-recommends gnupg pbuilder ubuntu-dev-tools dh-make build-essential fakeroot dput
apt-get -qq install $debpkgs

# prepare pubkeys and ppas
echo "!/bin/bash" > .exec.sh
echo "apt-get -qq install gnupg dirmngr" >> .exec.sh
mirrors=""
if [ "$mode" == "opt" ]; then
	echo "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6CD53B7A813BE3CA4F3BD3DB782DBCC6429E7D0B" >> .exec.sh
	echo "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C65D51784EDC19A871DBDBB710C56D0DE9977759" >> .exec.sh
	mirrors="deb http://ppa.launchpad.net/beineri/opt-qt${{optver}}-xenial/ubuntu $distro main | deb http://ppa.launchpad.net/skycoder42/qt-modules-opt/ubuntu $distro main"
else
	echo "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6CD53B7A813BE3CA4F3BD3DB782DBCC6429E7D0B" >> .exec.sh
	mirrors="deb http://ppa.launchpad.net/skycoder42/qt-modules/ubuntu $distro main"
fi

# create pbuilder images
if ! pbuilder-dist $distro update --override-config --othermirror "$mirrors"; then
	pbuilder-dist $distro create
	chmod +x .exec.sh
	pbuilder-dist $distro execute --save-after-exec .exec.sh
	pbuilder-dist $distro update --override-config --othermirror "$mirrors"
	# import gpg key
	gpg --import launchpad.asc
fi

# build via pbuilder
pushd build
pushd $pkgname
debuild -S
popd
pbuilder-dist $distro build *.dsc

# publish to lp
if [ "$noupload" != "y" ]; then
	ppa="qt-modules"
	if [[ "$mode" == "opt" ]]; then
		ppa="$ppa-opt"
	fi
	dput "ppa:skycoder42/$ppa" *.changes
fi

popd
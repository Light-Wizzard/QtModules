#!/bin/bash
set -e

scriptdir=$(dirname $0)

export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"

# ios: no tests
if [[ $PLATFORM == "ios" ]]; then
	export NO_TESTS=true
fi

# static flag
if [[ "$PLATFORM" == "static" ]]; then
	export NO_TESTS=true
	echo "CONFIG += static_host_build" >> .qmake.conf
fi

# build
rootdir=$(pwd)
mkdir build-$PLATFORM
pushd build-$PLATFORM

/opt/qt/$QT_VER/$PLATFORM/bin/qmake $QMAKE_FLAGS ../
make qmake_all
make
make INSTALL_ROOT="$rootdir/install" install

# build and run tests
if [[ -z "$NO_TESTS" ]]; then
	make all

	export LD_LIBRARY_PATH="$(pwd)/lib:/opt/qt/$QT_VER/$PLATFORM/lib:$LD_LIBRARY_PATH"

	if [[ -z "$TEST_DIR" ]]; then
		export TEST_DIR=./tests/auto
	fi
	pushd "$TEST_DIR"
	for test in $(find . -type f -perm +0111 -name "tst_*"); do
		#QT_QPA_PLATFORM=minimal
		$test
	done
	popd
fi

# build examples
if [[ -n "$BUILD_EXAMPLES" ]]; then
	make all

	pushd examples
	make INSTALL_ROOT="$rootdir/install" install
	popd
fi

popd

# build documentation
if [[ -n "$BUILD_DOC" ]]; then
	mkdir build-doc
	pushd build-doc

	/opt/qt/$QT_VER/$PLATFORM/bin/qmake "CONFIG+=debug" $QMAKE_FLAGS ../
	make qmake_all

	pushd doc
	make doxygen
	make INSTALL_ROOT="$rootdir/install" install
	popd

	popd
fi

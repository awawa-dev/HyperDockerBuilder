#!/bin/bash

############################################
#                BUILD QT                  #
############################################

qt_version="6.8.4"

git clone --depth 1 --branch v${qt_version}-lts-lgpl https://code.qt.io/qt/qtbase.git qt_lts
mkdir qt_build
cd qt_build

configure_args=(
    -prefix /usr
    -bindir /usr/qt_${qt_version}_bin
    -headerdir /usr/qt_${qt_version}_include
    -hostdatadir /usr/qt_${qt_version}_host
    -archdatadir /usr/qt_${qt_version}
    -datadir /usr/qt_${qt_version}

    # Existing
    -no-dbus
    -no-gui
    -no-widgets
    -no-icu
    -no-feature-sql
    -no-feature-xml

    # QtNetwork
    -no-feature-brotli
    -no-feature-networkdiskcache
    -no-feature-gssapi
    -no-feature-ocsp
    -no-feature-networkproxy
    -no-feature-topleveldomain

    # QtCore
    -no-feature-animation
    -no-feature-easingcurve
    -no-feature-jalalicalendar
    -no-feature-hijricalendar
    -no-feature-timezone_locale
    -no-feature-mimetype
    -no-feature-testlib
    -no-feature-concurrent
    -no-feature-future
    -no-feature-itemmodel
    -no-feature-filesystemwatcher

    -nomake tests
    -nomake examples
)

../qt_lts/configure "${configure_args[@]}"

echo "===== Qt feature configuration ====="
grep '^QT_FEATURE_' CMakeCache.txt | sort
echo "===================================="

if [ "$?" -ne "0" ]; then
  echo "Qt configuration failed"
  exit 1
fi
cmake --build . --parallel

echo "===== Qt module sizes (build) ====="
find . -type f \( -name 'libQt6Core.so*' -o -name 'libQt6Network.so*' \) \
    -printf '%s %p\n' |
    sort -n |
    numfmt --field=1 --to=iec
echo "==================================="

if [ "$?" -ne "0" ]; then
  echo "Qt build failed"
  exit 1
fi
cmake --install .
if [ "$?" -ne "0" ]; then
  echo "Qt install failed"
  exit 1
fi

rm -rf * .[!.]* && ls -la
git clone --depth 1 --branch v${qt_version}-lts-lgpl https://code.qt.io/qt/qtserialport.git qtserialport
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ${build_option_qt_serial} ./qtserialport
if [ "$?" -ne "0" ]; then
  echo "Qt serial configuration failed"
  exit 1
fi
cmake --build . --parallel
if [ "$?" -ne "0" ]; then
  echo "Qt serialport build failed"
  exit 1
fi
cmake --install .
if [ "$?" -ne "0" ]; then
  echo "Qt serialport install failed"
  exit 1
fi

cd ..
rm -r qt_lts
if [ "$?" -ne "0" ]; then
  echo "Qt clean failed (1)"
  exit 1
fi
rm -r qt_build
if [ "$?" -ne "0" ]; then
  echo "Qt clean failed (2)"
  exit 1
fi

############################################
#              BUILD CCACHE                #
############################################

ccache_version="4.14"

mkdir ccache
cd ccache

wget "https://github.com/ccache/ccache/releases/download/v${ccache_version}/ccache-${ccache_version}.tar.gz"
if [ "$?" -ne "0" ]; then
  echo "Could not download ccache sources"
  exit 1
fi

tar -zxvf "ccache-${ccache_version}.tar.gz"
if [ "$?" -ne "0" ]; then
  echo "Extracting of ccache failed"
  exit 1
fi

cd "ccache-${ccache_version}"
if [ "$?" -ne "0" ]; then
  echo "Missing ccache folder"
  exit 1
fi

mkdir build
cd build
cmake -DHIREDIS_FROM_INTERNET=ON -DCMAKE_BUILD_TYPE=Release ..
if [ "$?" -ne "0" ]; then
  echo "CMake config failed"
  exit 1
fi
make -j $(nproc)
if [ "$?" -ne "0" ]; then
  echo "Make failed"
  exit 1
fi
make install
if [ "$?" -ne "0" ]; then
  echo "Make install failed"
  exit 1
fi
cd ../../..
rm -r ccache
if [ "$?" -ne "0" ]; then
  echo "Clean up failed"
  exit 1
fi


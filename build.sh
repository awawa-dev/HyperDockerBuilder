#!/bin/bash

############################################
#                BUILD QT                  #
############################################

qt_version="6.8.3"
git clone --branch v${qt_version} https://github.com/qt/qtbase.git qt_lts
mkdir qt_build
cd qt_build
../qt_lts/configure -prefix /usr -bindir /usr/qt_${qt_version}_bin -headerdir /usr/qt_${qt_version}_include -hostdatadir /usr/qt_${qt_version}_host -archdatadir /usr/qt_${qt_version} -datadir /usr/qt_${qt_version} -submodules qtbase,qtnetwork -no-sbom -no-dbus -no-gui -no-widgets -no-sql-sqlite -no-icu -skip qtsql -skip qtxml -nomake tests -nomake examples
if [ "$?" -ne "0" ]; then
  echo "Qt configuration failed"
  exit 1
fi
cmake --build . --parallel
if [ "$?" -ne "0" ]; then
  echo "Qt build failed"
  exit 1
fi
cmake --install .
if [ "$?" -ne "0" ]; then
  echo "Qt install failed"
  exit 1
fi

required_version="3.27.7"
current_version=$(cmake --version | head -n1 | awk '{print $3}' | sed 's/[^0-9.].*$//')
if [ "$(printf '%s\n' "$current_version" "$required_version" | sort -V | head -n1)" != "$required_version" ]; then
  echo "CMake version $current_version is older than $required_version" >&2
  build_option="-DQT_GENERATE_SBOM=OFF"
fi

rm -r * .*
git clone --branch v${qt_version} https://github.com/qt/qtserialport.git qtserialport
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ${build_option} ./qtserialport
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

ccache_version="4.11.3"

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


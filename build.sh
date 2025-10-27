#!/bin/bash

############################################
#              BUILD CCACHE                #
############################################

mkdir ccache
cd ccache

wget "https://github.com/neuschaefer/ccache/archive/refs/heads/cmake-fix.zip"
if [ "$?" -ne "0" ]; then
  echo "Could not download ccache sources"
  exit 1
fi

unzip ./cmake-fix.zip
if [ "$?" -ne "0" ]; then
  echo "Extracting of ccache failed"
  exit 1
fi

cd "ccache-cmake-fix"
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


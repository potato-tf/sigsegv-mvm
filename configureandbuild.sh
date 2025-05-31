#!/bin/bash

echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
if [[ $EUID -ne 0 ]]
then
    echo "Not running as root!"
    exit
fi

_INSTALL_DIR="/root"

function build()
{
    cd $_INSTALL_DIR/sigsegv-mvm
    ./autoconfig.sh

    cd build/x86
    ambuild

    cd ../../build/x64
    ambuild

    cp -rf $_INSTALL_DIR/sigsegv-mvm/build/x86/package/addons/sourcemod/* /var/tf2server/tf/addons/sourcemod
    cp -rf $_INSTALL_DIR/sigsegv-mvm/build/x64/package/addons/sourcemod/* /var/tf2server/tf/addons/sourcemod
}
function build_release()
{
    cd $_INSTALL_DIR/sigsegv-mvm
    ./autoconfig.sh

    cd build/release
    ambuild

    cp -rf $_INSTALL_DIR/sigsegv-mvm/build/release/package/addons/sourcemod/* /var/tf2server/tf/addons/sourcemod
    cp -rf $_INSTALL_DIR/sigsegv-mvm/build/release/package/addons/sourcemod/* /var/tf2server/tf/addons/sourcemod
}

if [[ $# -gt 0 ]]; then
    build_release
    exit
fi

dpkg --add-architecture i386
apt update

apt install -y autoconf automake libtool pip python3-venv nasm libiberty-dev libiberty-dev:i386 libelf-dev:i386 libboost-dev:i386 libbsd-dev:i386 libunwind-dev:i386 lib32z1-dev libc6-dev-i386 linux-libc-dev:i386 g++-multilib

read -p "Full clone and (re)build? (y/n): " full_rebuild
# full_rebuild="n"
if [ "$full_rebuild" = "y" ]; then
    rm -rf $_INSTALL_DIR/sigsegv-mvm
    rm -rf $_INSTALL_DIR/alliedmodders
fi

mkdir -p $_INSTALL_DIR/sigsegv-mvm

# clone sigsegv-mvm
git clone --recursive --branch minmaxfix "https://github.com/Brain-dawg/sigsegv-mvm.git"

chmod -R 755 $_INSTALL_DIR/sigsegv-mvm

# Clone SM/AMBuild repositories
mkdir -p $_INSTALL_DIR/alliedmodders
cd $_INSTALL_DIR/alliedmodders

git clone https://github.com/alliedmodders/ambuild.git --depth 1
git clone https://github.com/alliedmodders/hl2sdk.git --depth 1 -b sdk2013 hl2sdk-sdk2013
git clone https://github.com/alliedmodders/hl2sdk --depth 1 -b tf2 hl2sdk-tf2
git clone https://github.com/alliedmodders/hl2sdk.git --depth 1 -b css hl2sdk-css
git clone https://github.com/alliedmodders/metamod-source.git --depth 1 -b 1.11-dev
git clone --recursive https://github.com/alliedmodders/sourcemod.git --depth 1 -b 1.11-dev

chmod -R 755 $_INSTALL_DIR/alliedmodders

# export LD_LIBRARY_PATH="${_INSTALL_DIR}/alliedmodders/hl2sdk-sdk2013/lib/public/linux64:${_INSTALL_DIR}/alliedmodders/hl2sdk-sdk2013/lib/public/linux"

# echo $LD_LIBRARY_PATH
# read -p "Press any key to continue..."

# create python venv
# mkdir -p .venvs
# python3 -m venv ./bin/python
# python3 -m venv .venvs/ambuild
# chmod -R 755 $_INSTALL_DIR/.venvs

# .venvs/ambuild/bin/pip install alliedmodders/ambuild
pip install ./ambuild --break-system-packages
#replace configure.py shebang line to use python3
sed -i '1s|^.*|#!/usr/bin/python3|' $_INSTALL_DIR/sigsegv-mvm/configure.py
cd ..

# add ambuild to PATH
pathfile=$_INSTALL_DIR/.bashrc
# pathvar='export PATH='$_INSTALL_DIR'/.venvs/ambuild/bin/:$PATH'
pathvar='export PATH='$_INSTALL_DIR'/bin/:$PATH'

touch $pathfile
if ! grep -q -F -x "$pathvar" "$pathfile"; then
    echo "$pathvar" >> $pathfile
fi
source $_INSTALL_DIR/.bashrc

cd $_INSTALL_DIR/sigsegv-mvm
git submodule init
git submodule update --depth 1

chmod -R 755 $_INSTALL_DIR/sigsegv-mvm

# build submodules
if [ "$full_rebuild" = "y" ]; then
    cd libs/udis86
    # $_INSTALL_DIR/.venvs/ambuild/bin/python $_INSTALL_DIR/sigsegv-mvm/libs/udis86/scripts/ud_itab.py $_INSTALL_DIR/sigsegv-mvm/libs/udis86/docs/x86/optable.xml $_INSTALL_DIR/sigsegv-mvm/libs/udis86/libudis86
    /usr/bin/python3 $_INSTALL_DIR/sigsegv-mvm/libs/udis86/scripts/ud_itab.py $_INSTALL_DIR/sigsegv-mvm/libs/udis86/docs/x86/optable.xml $_INSTALL_DIR/sigsegv-mvm/libs/udis86/libudis86
    ./autogen.sh
    ./configure --enable-static=yes --with-python=/usr/bin/python3
    make clean
    make CFLAGS="-m32" LDFLAGS="-m32"
    mv libudis86/.libs/libudis86.a ../libudis86.a
    make clean
    make CFLAGS="-fPIC"
    mv libudis86/.libs/libudis86.a ../libudis86x64.a
    cd ../..

    chmod -R 755 $_INSTALL_DIR/sigsegv-mvm/libs/udis86
fi

# build lua
if [ "$full_rebuild" = "y" ]; then
    cd $_INSTALL_DIR/sigsegv-mvm/libs
    wget https://www.lua.org/ftp/lua-5.4.4.tar.gz

    chmod -R 755 $_INSTALL_DIR/sigsegv-mvm/libs

    tar -xf lua-*.tar.gz
    rm lua-*.tar.gz
    mv lua-* lua
    cd lua
    make CC=g++ MYCFLAGS='-m32' MYLDFLAGS='-m32'
    mv src/liblua.a ../liblua.a
    make clean
    make CC=g++ MYCFLAGS="-fPIC"
    mv src/liblua.a ../libluax64.a
    cd ../..

    chmod -R 755 $_INSTALL_DIR/sigsegv-mvm
fi

build_release
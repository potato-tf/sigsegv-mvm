#!/bin/bash

export CC=gcc-15
export CXX=g++-15

if grep -qi microsoft /proc/version; then
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
fi

if [[ $EUID -ne 0 ]]
then
    echo "Not running as root!"
    exit
fi

full_rebuild=$( [ -d $SIGMOD_BUILD_DIR/sigsegv-mvm/.git ] && "y" || "n" )

# pass additional args to only build
if [ "$#" -gt 0 ]; then

    if [ "$1" = "release" ]; then
        build_release
        exit

    elif [ "$1" = "full_rebuild" ]; then
        full_rebuild="y"
    fi
fi

SIGMOD_BUILD_DIR="$(pwd)"
GAMESERVER_DIR=${2:-"/var/tf2server/tf"}
export MAX_AMBUILD_JOBS=${3:-$(( $(nproc) / 2 ))}
AMBUILDPY="$SIGMOD_BUILD_DIR/.venvs/ambuild/bin/python3"

function use_ambuild_venv()
{
    export PATH="$SIGMOD_BUILD_DIR/.venvs/ambuild/bin:$PATH"
    export AMBUILDPY
}

function build()
{
    use_ambuild_venv
    cd $SIGMOD_BUILD_DIR/sigsegv-mvm
    ./autoconfig.sh

    cd build/x86
    nice -n 19 ionice -c 3 $SIGMOD_BUILD_DIR/.venvs/ambuild/bin/ambuild -j$MAX_AMBUILD_JOBS

    cd ../../build/x64
    nice -n 19 ionice -c 3 $SIGMOD_BUILD_DIR/.venvs/ambuild/bin/ambuild -j$MAX_AMBUILD_JOBS

    cp -rf $SIGMOD_BUILD_DIR/sigsegv-mvm/build/x86/package/addons/sourcemod/* $GAMESERVER_DIR/addons/sourcemod
    cp -rf $SIGMOD_BUILD_DIR/sigsegv-mvm/build/x64/package/addons/sourcemod/* $GAMESERVER_DIR/addons/sourcemod
}
function build_release()
{
    use_ambuild_venv
    cd $SIGMOD_BUILD_DIR/sigsegv-mvm
    ./autoconfig.sh
    ./multibuild.sh


    if [ -d $GAMESERVER_DIR/addons/sourcemod ]; then
        cp -rf $SIGMOD_BUILD_DIR/sigsegv-mvm/build/release/package/addons/sourcemod/* $GAMESERVER_DIR/addons/sourcemod
        cp -rf $SIGMOD_BUILD_DIR/sigsegv-mvm/build/release/package/addons/sourcemod/* $GAMESERVER_DIR/addons/sourcemod
    fi
}

function ensure_gcc15()
{
    command -v gcc-15 >/dev/null 2>&1 && return 0

    apt install -y gnupg ca-certificates curl
    if [ ! -f /usr/share/keyrings/ubuntu-toolchain-r-test.gpg ]; then
        curl -fsSL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x60C317108A870663' \
            | gpg --dearmor -o /usr/share/keyrings/ubuntu-toolchain-r-test.gpg
    fi
    if [ ! -f /etc/apt/sources.list.d/ubuntu-toolchain-r-test.list ]; then
        SUITE="$(. /etc/os-release && echo "$VERSION_CODENAME")"
        echo "deb [signed-by=/usr/share/keyrings/ubuntu-toolchain-r-test.gpg] https://ppa.launchpadcontent.net/ubuntu-toolchain-r/test/ubuntu ${SUITE} main" \
            > /etc/apt/sources.list.d/ubuntu-toolchain-r-test.list
    fi
}

dpkg --add-architecture i386
apt update
ensure_gcc15
apt update

apt install -y git autoconf automake libtool pip python3-venv nasm libiberty-dev libiberty-dev:i386 libelf-dev:i386 libboost-dev:i386 libbsd-dev:i386 libunwind-dev:i386 lib32z1-dev libc6-dev-i386 linux-libc-dev:i386 gcc-15-multilib g++-15-multilib

# read -p "Full clone and (re)build? (y/n): " full_rebuild

# if [ "$full_rebuild" = "y" ]; then
#     rm -rf $SIGMOD_BUILD_DIR/sigsegv-mvm
#     rm -rf $SIGMOD_BUILD_DIR/alliedmodders
# fi

mkdir -p $SIGMOD_BUILD_DIR/sigsegv-mvm

# clone sigsegv-mvm
if [ ! -d "$SIGMOD_BUILD_DIR/sigsegv-mvm/.git" ]; then
    git clone --recursive --branch buildscript "https://github.com/Brain-dawg/sigsegv-mvm.git" "$SIGMOD_BUILD_DIR/sigsegv-mvm"
else
    git pull
fi

chmod -R 755 $SIGMOD_BUILD_DIR/sigsegv-mvm

# Clone SM/AMBuild repositories
mkdir -p $SIGMOD_BUILD_DIR/alliedmodders
cd $SIGMOD_BUILD_DIR/alliedmodders

[ ! -d ambuild/.git ] && git clone https://github.com/alliedmodders/ambuild.git --depth 1
[ ! -d hl2sdk-sdk2013/.git ] && git clone https://github.com/alliedmodders/hl2sdk.git --depth 1 -b sdk2013 hl2sdk-sdk2013
[ ! -d hl2sdk-tf2/.git ] && git clone https://github.com/alliedmodders/hl2sdk --depth 1 -b tf2 hl2sdk-tf2
[ ! -d hl2sdk-css/.git ] && git clone https://github.com/alliedmodders/hl2sdk.git --depth 1 -b css hl2sdk-css
[ ! -d metamod-source/.git ] && git clone https://github.com/alliedmodders/metamod-source.git --depth 1 -b 1.11-dev
[ ! -d sourcemod/.git ] && git clone --recursive https://github.com/alliedmodders/sourcemod.git --depth 1 -b 1.11-dev

chmod -R 755 $SIGMOD_BUILD_DIR/alliedmodders

# export LD_LIBRARY_PATH="${SIGMOD_BUILD_DIR}/alliedmodders/hl2sdk-sdk2013/lib/public/linux64:${SIGMOD_BUILD_DIR}/alliedmodders/hl2sdk-sdk2013/lib/public/linux"

# echo $LD_LIBRARY_PATH
# read -p "Press any key to continue..."

# create python venv (AMBuild lives here)
if [ ! -x "$SIGMOD_BUILD_DIR/.venvs/ambuild/bin/pip" ]; then
    mkdir -p "$SIGMOD_BUILD_DIR/.venvs"
    python3 -m venv "$SIGMOD_BUILD_DIR/.venvs/ambuild"
    chmod -R 755 "$SIGMOD_BUILD_DIR/.venvs"
fi

"$SIGMOD_BUILD_DIR/.venvs/ambuild/bin/pip" install "$SIGMOD_BUILD_DIR/alliedmodders/ambuild"
sed -i "1s|^.*|#!$SIGMOD_BUILD_DIR/.venvs/ambuild/bin/python3|" "$SIGMOD_BUILD_DIR/sigsegv-mvm/configure.py"
use_ambuild_venv
cd "$SIGMOD_BUILD_DIR"

# add ambuild to PATH
pathfile=$SIGMOD_BUILD_DIR/.bashrc
pathvar="export PATH=\"$SIGMOD_BUILD_DIR/.venvs/ambuild/bin:$PATH\""
# pathvar='export PATH='$SIGMOD_BUILD_DIR'/bin:$PATH'

touch $pathfile
if ! grep -q -F -x "$pathvar" "$pathfile"; then
    echo "$pathvar" >> $pathfile
fi
source $SIGMOD_BUILD_DIR/.bashrc

cd $SIGMOD_BUILD_DIR/sigsegv-mvm
git submodule init
git submodule update --depth 1

chmod -R 755 $SIGMOD_BUILD_DIR/sigsegv-mvm

# build submodules
if [ "$full_rebuild" = "y" ]; then
    cd libs/udis86
    $SIGMOD_BUILD_DIR/.venvs/ambuild/bin/python $SIGMOD_BUILD_DIR/sigsegv-mvm/libs/udis86/scripts/ud_itab.py $SIGMOD_BUILD_DIR/sigsegv-mvm/libs/udis86/docs/x86/optable.xml $SIGMOD_BUILD_DIR/sigsegv-mvm/libs/udis86/libudis86
    # /usr/bin/python3 $SIGMOD_BUILD_DIR/sigsegv-mvm/libs/udis86/scripts/ud_itab.py $SIGMOD_BUILD_DIR/sigsegv-mvm/libs/udis86/docs/x86/optable.xml $SIGMOD_BUILD_DIR/sigsegv-mvm/libs/udis86/libudis86
    ./autogen.sh
    ./configure --enable-static=yes --with-python=$SIGMOD_BUILD_DIR/.venvs/ambuild/bin/python3
    make clean
    make CC=gcc-15 CFLAGS="-m32" LDFLAGS="-m32"
    mv libudis86/.libs/libudis86.a ../libudis86.a
    make clean
    make CC=gcc-15 CFLAGS="-fPIC"
    mv libudis86/.libs/libudis86.a ../libudis86x64.a
    cd ../..

    chmod -R 755 $SIGMOD_BUILD_DIR/sigsegv-mvm/libs/udis86
fi

# build lua
if [ "$full_rebuild" = "y" ]; then
    cd $SIGMOD_BUILD_DIR/sigsegv-mvm/libs
    wget https://www.lua.org/ftp/lua-5.4.4.tar.gz

    chmod -R 755 $SIGMOD_BUILD_DIR/sigsegv-mvm/libs

    tar -xf lua-*.tar.gz
    rm lua-*.tar.gz
    mv lua-* lua
    cd lua
    make CC=g++-15 MYCFLAGS='-m32' MYLDFLAGS='-m32'
    mv src/liblua.a ../liblua.a
    make clean
    make CC=g++-15 MYCFLAGS="-fPIC"
    mv src/liblua.a ../libluax64.a
    cd ../..

    chmod -R 755 $SIGMOD_BUILD_DIR/sigsegv-mvm
fi

build_release
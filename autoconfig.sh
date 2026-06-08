#!/bin/bash

PROJECT_DIR=$(dirname "$(realpath "$0")")
CONFIGURE="$PROJECT_DIR/configure.py"
echo "$PROJECT_DIR"
PATHS="--hl2sdk-root=$PROJECT_DIR/../alliedmodders --mms-path=$PROJECT_DIR/../alliedmodders/metamod-source --sm-path=$PROJECT_DIR/../alliedmodders/sourcemod"

export CC=${CC:=gcc}
export CXX=${CXX:=g++}

if [ -z "${AMBUILDPY:-}" ]; then
    if [ -x "$PROJECT_DIR/../.venvs/ambuild/bin/python3" ]; then
        AMBUILDPY="$PROJECT_DIR/../.venvs/ambuild/bin/python3"
    else
        AMBUILDPY="$(command -v python3)"
    fi
fi
export AMBUILDPY

mkdir -p build
cd build
    "$AMBUILDPY" "$CONFIGURE" $PATHS --sdks=tf2 --enable-debug --exclude-mods-debug --enable-optimize --exclude-mods-visualize --exclude-vgui
cd ..

mkdir -p build/release
pushd build/release
    "$AMBUILDPY" "$CONFIGURE" $PATHS --targets=x86_64,x86 --sdks=tf2,css,sdk2013 --build-all --enable-optimize --exclude-mods-debug --exclude-mods-visualize --exclude-vgui
popd

mkdir -p build/x86
pushd build/x86
    "$AMBUILDPY" "$CONFIGURE" $PATHS --targets=x86 --sdks=tf2 --enable-optimize --exclude-mods-debug --exclude-mods-visualize --exclude-vgui
popd

mkdir -p build/x64
pushd build/x64
    "$AMBUILDPY" "$CONFIGURE" $PATHS --targets=x86_64 --sdks=tf2 --enable-optimize --exclude-mods-debug --exclude-mods-visualize --exclude-vgui
popd
# mkdir -p build/release/optimize-only
# pushd build/release/optimize-only
# 	CC=gcc CXX=g++ $CONFIGURE $PATHS --enable-optimize --exclude-mods-debug --exclude-mods-visualize --exclude-vgui --optimize-mods-only
# popd

# mkdir -p build/release/no-mvm
# pushd build/release/no-mvm
# 	CC=gcc CXX=g++ $CONFIGURE $PATHS --sdks=tf2 --enable-optimize --exclude-mods-debug --exclude-mods-visualize --exclude-vgui --exclude-mods-mvm
# popd

# mkdir -p build/clang
# pushd build/clang
# 	CC=clang CXX=clang++ $CONFIGURE $PATHS --sdks=tf2 --enable-debug
# popd

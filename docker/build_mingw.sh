#/bin/bash
LIBIIO_BRANCH=master
LIBAD9361_BRANCH=master
LIBAD9166_BRANCH=master

export WORKDIR=/home/$USER/

init_env() {

export ARCH=x86_64
export MINGW_VERSION=mingw32
export CC=/${MINGW_VERSION}/bin/${ARCH}-w64-mingw32-gcc.exe
export CXX=/${MINGW_VERSION}/bin/${ARCH}-w64-mingw32-g++.exe

export JOBS=-j9
export CMAKE_GENERATOR="Unix Makefiles"
export STAGING_DIR="/$MINGW_VERSION"
export MAKE_BIN="/bin/make"
export MAKE="$MAKE_BIN $JOBS"
export CMAKE_OPTS="-DCMAKE_C_COMPILER:FILEPATH=${CC}\
-DCMAKE_CXX_COMPILER:FILEPATH=${CXX}\
-DCMAKE_MAKE_PROGRAM:FILEPATH=${MAKE_BIN}\
-DPKG_CONFIG_EXECUTABLE=/$MINGW_VERSION/bin/pkg-config.exe\
-DCMAKE_MODULE_PATH=$STAGING_DIR\
-DCMAKE_PREFIX_PATH=$STAGING_DIR/lib/cmake\
-DCMAKE_BUILD_TYPE=RelWithDebInfo\
-DCMAKE_STAGING_PREFIX=$STAGING_DIR\
-DCMAKE_INSTALL_PREFIX=$STAGING_DIR"

export CMAKE="/$MINGW_VERSION/bin/cmake"
export HOST=${MINGW_VERSION}-w64-mingw32
export AUTOCONF_OPTS="--prefix=/mingw64 \
        --host=${ARCH}-w64-mingw32 \
        --enable-shared \
        --disable-static"
}

install_pacman_deps() {
WINDEPS="\
msys2-devel \
mingw-w64-i686-toolchain \
mingw-w64-i686-cmake \
mingw-w64-i686-ninja \
mingw-w64-i686-qt5-winextras \
mingw-w64-i686-qt5 \
mingw-w64-i686-qt5-3d \
mingw-w64-i686-gdb \
mingw-w64-i686-mesa \
mingw-w64-i686-qt-creator \
mingw-w64-i686-nsis"
pacman -S --noconfirm --needed $WINDEPS
}


clone() {
    cd /c/
    git clone https://github.com/analogdevicesinc/adi-kuiper-imager --branch $BRANCH
}

create_deploy() {
mkdir -p /c/adi-kuiper-imager/build/deploy
cp /c/msys64/mingw32/bin/{libbrotlicommon.dll,libbrotlidec.dll,libbrotlienc.dll,libdouble-conversion.dll,libfreetype-6.dll,libglib-2.0-0.dll,libgraphite2.dll,libharfbuzz-0.dll,libicudt*.dll,libicuin*.dll,libicuuc*.dll,libintl-8.dll,liblzma-5.dll,libmd4c.dll,libpcre-2*.dll,libpng16-16.dll,zlib1.dll,libbz2-1.dll,libiconv-2.dll,liblz4.dll,libxml2-2.dll,libzstd.dll,libgcc_s_dw2-1.dll,libstdc++-6.dll,libwinpthread-1.dll libssl*.dll libcrypto*.dll} /c/adi-kuiper-imager/build/deploy
#cp /c/OpenSSL-Win32/libeay32.dll /c/adi-kuiper-imager/build/deploy
}

build() {
export PATH=/c/msys64/mingw32/bin:/c/msys64/usr/bin:$PATH &&
cmake -B /c/adi-kuiper-imager/build -S /c/adi-kuiper-imager -GNinja -DCMAKE_BUILD_TYPE:STRING=Release -DQT_QMAKE_EXECUTABLE:STRING="/c/msys64/mingw32/bin/qmake.exe" -DCMAKE_PREFIX_PATH:STRING="/c/msys64/mingw32/bin" -DCMAKE_C_COMPILER:STRING="/c/msys64/mingw32/bin/gcc.exe" -DCMAKE_CXX_COMPILER:STRING="/c/msys64/mingw32/bin/g++.exe" -DCMAKE_MAKE_PROGRAM:FILEPATH="/c/msys64/mingw32/bin/ninja.exe" /c/adi-kuiper-imager &&
cmake --build /c/adi-kuiper-imager/build --target all
}

create_installer() {
makensis.exe /c/adi-kuiper-imager/build/kuiper-imager.nsi
}

build_imager() {
    clone
    build
    create_deploy
    create_installer
}

init_env
$@
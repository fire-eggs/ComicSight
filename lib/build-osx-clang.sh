#!/bin/sh

# you may want temporarily rename /opt/local here
# not to depend on libraries stored there (like MacPorts)
#
# sudo mv /opt/local /opt/local.bak
#

# build result directory structure
mkdir build
cd build
mkdir osx
cd osx
mkdir bin
mkdir include
mkdir lib-shared
mkdir lib-static
mkdir lib-static-shared-fltk
cd ../../

export CFLAGS=-flto
export CPPFLAGS=-flto

export DYLD_FALLBACK_LIBRARY_PATH=$DYLD_FALLBACK_LIBRARY_PATH:$PWD/build/osx/lib-shared

# build libpng (shared lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake \
-DPNG_SHARED=ON -DPNG_STATIC=OFF \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INCLUDE_PATH=../../build/osx/include \
-DCMAKE_LIBRARY_PATH=../../build/osx/lib-shared \
-G"Unix Makefiles" \
../src/libpng-1.6.7
make
mv libpng16.16.7.0.dylib ../build/osx/lib-shared/libpng16.16.7.0.dylib
mv libpng16.16.dylib ../build/osx/lib-shared/libpng16.16.dylib
mv libpng16.dylib ../build/osx/lib-shared/libpng16.dylib
mv libpng.dylib ../build/osx/lib-shared/libpng.dylib
cd ../

rm -rf build-desktop

# build libpng (static lib with static dependencies)
mkdir build-desktop
cd build-desktop
cmake \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INCLUDE_PATH=../../build/osx/include \
-DCMAKE_LIBRARY_PATH=../../build/osx/lib-static \
-G"Unix Makefiles" \
../src/libpng-1.6.7
make
mv pngtest ../build/osx/bin/pngtest
mv pngvalid ../build/osx/bin/pngvalid
mv pnglibconf.h ../build/osx/include/pnglibconf.h
mv libpng16.a ../build/osx/lib-static/libpng16.a
mv libpng.a ../build/osx/lib-static/libpng.a
cd ../
cp src/libpng-1.6.7/png.h build/osx/include/png.h
cp src/libpng-1.6.7/pngconf.h build/osx/include/pngconf.h

rm -rf build-desktop

# build libjpeg
# libjpeg-turbo needs NASM
#   (use MacPorts and "sudo port install nasm" under OS X)
mkdir build-desktop
#   if you have renamed /opt/local to /opt/local.bak, you need to use
#   /opt/local.bak/bin/nasm instead of /opt/local/bin/nasm
cd build-desktop
../src/libjpeg-turbo-1.3.0/configure --host x86_64-apple-darwin NASM=/opt/local/bin/nasm
make
mv cjpeg ../build/osx/bin/cjpeg
mv djpeg ../build/osx/bin/djpeg
mv jpegtran ../build/osx/bin/jpegtran
mv rdjpgcom ../build/osx/bin/rdjpgcom
mv tjbench ../build/osx/bin/tjbench
mv tjunittest ../build/osx/bin/tjunittest
mv wrjpgcom ../build/osx/bin/wrjpgcom
mv jconfig.h ../build/osx/include/jconfig.h
mv .libs/libjpeg.a ../build/osx/lib-static/libjpeg.a
mv .libs/libturbojpeg.a  ../build/osx/lib-static/libturbojpeg.a
mv .libs/libjpeg.62.1.0.dylib ../build/osx/lib-shared/libjpeg.62.1.0.dylib
mv .libs/libjpeg.62.dylib ../build/osx/lib-shared/libjpeg.62.dylib
mv .libs/libjpeg.dylib ../build/osx/lib-shared/libjpeg.dylib
mv .libs/libturbojpeg.dylib ../build/osx/lib-shared/libturbojpeg.dylib
cd ../
cp src/libjpeg-turbo-1.3.0/jpeglib.h build/osx/include/jpeglib.h
cp src/libjpeg-turbo-1.3.0/jmorecfg.h build/osx/include/jmorecfg.h
cp src/libjpeg-turbo-1.3.0/jpegint.h build/osx/include/jpegint.h
cp src/libjpeg-turbo-1.3.0/jerror.h build/osx/include/jerror.h

rm -rf build-desktop

# build fltk (shared lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake \
-DOPTION_BUILD_SHARED_LIBS=ON \
-DOPTION_BUILD_EXAMPLES=OFF \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INCLUDE_PATH=../../build/osx/include \
-DCMAKE_LIBRARY_PATH=../../build/osx/lib-shared \
-G"Unix Makefiles" \
../src/fltk-1.3.2
make
mv lib/libfltk.dylib ../build/osx/lib-shared/libfltk.dylib
mv lib/libfltk_forms.dylib ../build/osx/lib-shared/libfltk_forms.dylib
mv lib/libfltk_gl.dylib ../build/osx/lib-shared/libfltk_gl.dylib
mv lib/libfltk_images.dylib ../build/osx/lib-shared/libfltk_images.dylib
cd ../

rm -rf build-desktop

# build fltk (static lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake \
-DOPTION_BUILD_EXAMPLES=OFF \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INCLUDE_PATH=../../build/osx/include \
-DCMAKE_LIBRARY_PATH=../../build/osx/lib-shared \
-G"Unix Makefiles" \
../src/fltk-1.3.2
make
mv lib/libfltk.a ../build/osx/lib-static-shared-fltk/libfltk.a
mv lib/libfltk_forms.a ../build/osx/lib-static-shared-fltk/libfltk_forms.a
mv lib/libfltk_gl.a ../build/osx/lib-static-shared-fltk/libfltk_gl.a
mv lib/libfltk_images.a ../build/osx/lib-static-shared-fltk/libfltk_images.a
cd ../

rm -rf build-desktop

# build fltk (static lib with static dependencies)
mkdir build-desktop
cd build-desktop
cmake \
-DOPTION_BUILD_EXAMPLES=OFF \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INCLUDE_PATH=../../build/osx/include \
-DCMAKE_LIBRARY_PATH=../../build/osx/lib-static \
-G"Unix Makefiles" \
../src/fltk-1.3.2
make
mv bin/fluid ../build/osx/bin/fluid
mv lib/libfltk.a ../build/osx/lib-static/libfltk.a
mv lib/libfltk_forms.a ../build/osx/lib-static/libfltk_forms.a
mv lib/libfltk_gl.a ../build/osx/lib-static/libfltk_gl.a
mv lib/libfltk_images.a ../build/osx/lib-static/libfltk_images.a
cd ../
mkdir build/osx/include/FL
cp src/fltk-1.3.2/FL/*.h build/osx/include/FL
cp src/fltk-1.3.2/FL/*.H build/osx/include/FL

rm -rf build-desktop

# liblzma
mkdir build-desktop
cd build-desktop
cmake \
-DCMAKE_BUILD_TYPE=Release \
-G"Unix Makefiles" \
../src/xz-5.0.5
make
mv lzmadec ../build/osx/bin/lzmadec
mv lzmainfo ../build/osx/bin/lzmainfo
mv xz ../build/osx/bin/xz
mv xzdec ../build/osx/bin/xzdec
mv liblzma.dylib ../build/osx/lib-shared/liblzma.dylib
mv liblzmastatic.a ../build/osx/lib-static/liblzma.a
cd ../
mkdir build/osx/include/lzma
cp src/xz-5.0.5/src/liblzma/api/*.h build/osx/include
cp src/xz-5.0.5/src/liblzma/api/lzma/*.h build/osx/include/lzma

rm -rf build-desktop

# build libarchive (shared lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake \
-DENABLE_TEST=OFF \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INCLUDE_PATH=../../build/osx/include \
-DCMAKE_LIBRARY_PATH=../../build/osx/lib-shared \
-G"Unix Makefiles" \
../src/libarchive-3.1.2
make
mv libarchive/libarchive.dylib ../build/osx/lib-shared/libarchive.dylib
mv libarchive/libarchive.14.dylib ../build/osx/lib-shared/libarchive.14.dylib
cd ../

rm -rf build-desktop

# build libarchive (static lib with static dependencies)
mkdir build-desktop
cd build-desktop
cmake \
-DENABLE_TEST=OFF \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INCLUDE_PATH=../../build/osx/include \
-DCMAKE_LIBRARY_PATH=../../build/osx/lib-static \
-G"Unix Makefiles" \
../src/libarchive-3.1.2
make
mv bin/bsdcpio ../build/osx/bin/bsdcpio
mv bin/bsdtar ../build/osx/bin/bsdtar
mv libarchive/libarchive.a ../build/osx/lib-static/libarchive.a
cd ../
cp src/libarchive-3.1.2/libarchive/archive.h build/osx/include/archive.h
cp src/libarchive-3.1.2/libarchive/archive_entry.h build/osx/include/archive_entry.h

rm -rf build-desktop

# if you have renamed /opt/local to /opt/local.bak, you should undo it now
#
# sudo mv /opt/local.bak /opt/local
#

# default libs
mkdir build/osx/lib
cp build/osx/lib-static/* build/osx/lib

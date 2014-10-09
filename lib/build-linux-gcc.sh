#!/bin/sh

# build result directory structure
mkdir build
cd build
mkdir linux
cd linux
mkdir bin
mkdir include
mkdir lib
cd ../../

export CFLAGS='-flto -fno-use-linker-plugin'
export CPPFLAGS='-flto -fno-use-linker-plugin'

# build fltk (static lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake \
  -DOPTION_BUILD_EXAMPLES=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=../../build/linux \
  -G"Unix Makefiles" \
  ../src/fltk-1.3.2
make
mv fltk-config ../build/linux/bin/fltk-config
mv bin/fluid ../build/linux/bin/fluid
mv lib/libfltk.a ../build/linux/lib/libfltk.a
mv lib/libfltk_forms.a ../build/linux/lib/libfltk_forms.a
mv lib/libfltk_gl.a ../build/linux/lib/libfltk_gl.a
mv lib/libfltk_images.a ../build/linux/lib/libfltk_images.a
cd ../
mkdir build/linux/include/FL
cp src/fltk-1.3.2/FL/*.h build/linux/include/FL
cp src/fltk-1.3.2/FL/*.H build/linux/include/FL

rm -rf build-desktop

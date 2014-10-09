REM build result directory structure
mkdir build
cd build
mkdir win-mingw
cd win-mingw
mkdir bin
mkdir include
mkdir lib-shared
mkdir lib-static
mkdir lib-static-shared-fltk
cd ..\..

set PATH=%PATH%;%CD%\build\win-mingw\lib-shared

set CFLAGS=-flto
set CPPFLAGS=-flto

REM build zlib
mkdir build-desktop
cd build-desktop
cmake ^
  -DCMAKE_BUILD_TYPE=Release ^
  -G"MinGW Makefiles" ^
  ..\src\zlib-1.2.8
make
move /Y example.exe ..\build\win-mingw\bin\example-zlib.exe
move /Y example64.exe ..\build\win-mingw\bin\example64-zlib.exe
move /Y minigzip.exe ..\build\win-mingw\bin\minigzip.exe
move /Y minigzip64.exe ..\build\win-mingw\bin\minigzip64.exe
move /Y zconf.h ..\build\win-mingw\include\zconf.h
move /Y libzlib.dll ..\build\win-mingw\lib-shared\libzlib.dll
move /Y libzlib.dll.a ..\build\win-mingw\lib-shared\libzlib.dll.a
move /Y libzlibstatic.a ..\build\win-mingw\lib-static\libzlib.a
cd ..
copy /Y src\zlib-1.2.8\zlib.h build\win-mingw\include\zlib.h

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build libpng (shared lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DPNG_SHARED=ON -DPNG_STATIC=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-mingw\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-mingw\lib-shared ^
  -G"MinGW Makefiles" ^
  ..\src\libpng-1.6.7
make
move /Y libpng16.dll ..\build\win-mingw\lib-shared\libpng16.dll
move /Y libpng16.dll.a ..\build\win-mingw\lib-shared\libpng.dll.a
cd ..

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build libpng (static lib with static dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-mingw\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-mingw\lib-static ^
  -G"MinGW Makefiles" ^
  ..\src\libpng-1.6.7
make
move /Y pngtest.exe ..\build\win-mingw\bin\pngtest.exe
move /Y pngvalid.exe ..\build\win-mingw\bin\pngvalid.exe
move /Y pnglibconf.h ..\build\win-mingw\include\pnglibconf.h
move /Y libpng16.a ..\build\win-mingw\lib-static\libpng.a
cd ..
copy /Y src\libpng-1.6.7\png.h build\win-mingw\include\png.h
copy /Y src\libpng-1.6.7\pngconf.h build\win-mingw\include\pngconf.h

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build libjpeg
REM libjpeg-turbo needs NASM
mkdir build-desktop
cd build-desktop
cmake ^
  -DCMAKE_BUILD_TYPE=Release ^
  -G"MinGW Makefiles" ^
  ..\src\libjpeg-turbo-1.3.0
make
move /Y cjpeg-static.exe ..\build\win-mingw\bin\cjpeg-static.exe
move /Y djpeg-static.exe ..\build\win-mingw\bin\djpeg-static.exe
move /Y jpegtran-static.exe ..\build\win-mingw\bin\jpegtran-static.exe
move /Y rdjpgcom.exe ..\build\win-mingw\bin\rdjpgcom.exe
move /Y tjbench.exe ..\build\win-mingw\bin\tjbench.exe
move /Y tjbench-static.exe ..\build\win-mingw\bin\tjbench-static.exe
move /Y tjunittest.exe ..\build\win-mingw\bin\tjunittest.exe
move /Y tjunittest-static.exe ..\build\win-mingw\bin\tjunittest-static.exe
move /Y wrjpgcom.exe ..\build\win-mingw\bin\wrjpgcom.exe
move /Y sharedlib\cjpeg.exe ..\build\win-mingw\bin\cjpeg.exe
move /Y sharedlib\djpeg.exe ..\build\win-mingw\bin\djpeg.exe
move /Y sharedlib\jcstest.exe ..\build\win-mingw\bin\jcstest.exe
move /Y sharedlib\jpegtran.exe ..\build\win-mingw\bin\jpegtran.exe
move /Y libturbojpeg.dll ..\build\win-mingw\bin\libturbojpeg.dll
move /Y jconfig.h ..\build\win-mingw\include\jconfig.h
move /Y libturbojpeg.a ..\build\win-mingw\lib-static\libjpeg.a
move /Y sharedlib\libjpeg-62.dll ..\build\win-mingw\lib-shared\libjpeg-62.dll
move /Y sharedlib\libjpeg.dll.a ..\build\win-mingw\lib-shared\libjpeg.dll.a
cd ..
copy /Y src\libjpeg-turbo-1.3.0\jpeglib.h build\win-mingw\include\jpeglib.h
copy /Y src\libjpeg-turbo-1.3.0\jmorecfg.h build\win-mingw\include\jmorecfg.h
copy /Y src\libjpeg-turbo-1.3.0\jpegint.h build\win-mingw\include\jpegint.h
copy /Y src\libjpeg-turbo-1.3.0\jerror.h build\win-mingw\include\jerror.h

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build fltk (shared lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DOPTION_BUILD_SHARED_LIBS=ON ^
  -DOPTION_BUILD_EXAMPLES=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-mingw\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-mingw\lib-shared ^
  -G"MinGW Makefiles" ^
  ..\src\fltk-1.3.2
make
move /Y lib\libfltk.dll ..\build\win-mingw\lib-shared\libfltk.dll
move /Y lib\libfltk.dll.a ..\build\win-mingw\lib-shared\libfltk.dll.a
move /Y lib\libfltk_forms.dll ..\build\win-mingw\lib-shared\libfltk_forms.dll
move /Y lib\libfltk_forms.dll.a ..\build\win-mingw\lib-shared\libfltk_forms.dll.a
move /Y lib\libfltk_gl.dll ..\build\win-mingw\lib-shared\libfltk_gl.dll
move /Y lib\libfltk_gl.dll.a ..\build\win-mingw\lib-shared\libfltk_gl.dll.a
move /Y lib\libfltk_images.dll ..\build\win-mingw\lib-shared\libfltk_images.dll
move /Y lib\libfltk_images.dll.a ..\build\win-mingw\lib-shared\libfltk_images.dll.a
cd ..

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build fltk (static lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DOPTION_BUILD_EXAMPLES=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-mingw\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-mingw\lib-shared ^
  -G"MinGW Makefiles" ^
  ..\src\fltk-1.3.2
make
move /Y lib\libfltk.a ..\build\win-mingw\lib-static-shared-fltk\libfltk.a
move /Y lib\libfltk_forms.a ..\build\win-mingw\lib-static-shared-fltk\libfltk_forms.a
move /Y lib\libfltk_gl.a ..\build\win-mingw\lib-static-shared-fltk\libfltk_gl.a
move /Y lib\libfltk_images.a ..\build\win-mingw\lib-static-shared-fltk\libfltk_images.a
cd ..

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build fltk (static lib with static dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DOPTION_BUILD_EXAMPLES=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-mingw\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-mingw\lib-static ^
  -G"MinGW Makefiles" ^
  ..\src\fltk-1.3.2
make
move /Y bin\fluid.exe ..\build\win-mingw\bin\fluid.exe
move /Y lib\libfltk.a ..\build\win-mingw\lib-static\libfltk.a
move /Y lib\libfltk_forms.a ..\build\win-mingw\lib-static\libfltk_forms.a
move /Y lib\libfltk_gl.a ..\build\win-mingw\lib-static\libfltk_gl.a
move /Y lib\libfltk_images.a ..\build\win-mingw\lib-static\libfltk_images.a
cd ..
mkdir build\win-mingw\include\FL
copy /Y src\fltk-1.3.2\FL\*.h build\win-mingw\include\FL
copy /Y src\fltk-1.3.2\FL\*.H build\win-mingw\include\FL

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM liblzma
REM (CMake based on https://projects.kde.org/projects/kdesupport/emerge/repository/revisions/master/show/portage/win32libs/liblzma)
mkdir build-desktop
cd build-desktop
cmake ^
  -DCMAKE_BUILD_TYPE=Release ^
  -G"MinGW Makefiles" ^
  ..\src\xz-5.0.5
make
move /Y lzmadec.exe ..\build\win-mingw\bin\lzmadec.exe
move /Y lzmainfo.exe ..\build\win-mingw\bin\lzmainfo.exe
move /Y xz.exe ..\build\win-mingw\bin\xz.exe
move /Y xzdec.exe ..\build\win-mingw\bin\xzdec.exe
move /Y liblzma.dll ..\build\win-mingw\lib-shared\liblzma.dll
move /Y liblzma.dll.a ..\build\win-mingw\lib-shared\liblzma.dll.a
move /Y liblzmastatic.a ..\build\win-mingw\lib-static\liblzma.a
cd ..
mkdir build\win-mingw\include\lzma
copy /Y src\xz-5.0.5\src\liblzma\api\*.h build\win-mingw\include
copy /Y src\xz-5.0.5\src\liblzma\api\lzma\*.h build\win-mingw\include\lzma

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build libarchive (shared lib with shared dependencies)
REM tests do not work with MinGW due to http://code.google.com/p/libarchive/issues/detail?id=319
mkdir build-desktop
cd build-desktop
cmake ^
  -DENABLE_TEST=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-mingw\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-mingw\lib-shared ^
  -G"MinGW Makefiles" ^
  ..\src\libarchive-3.1.2
make
move /Y bin\libarchive.dll ..\build\win-mingw\lib-shared\libarchive.dll
move /Y libarchive\libarchive.dll.a ..\build\win-mingw\lib-shared\libarchive.dll.a
cd ..

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build libarchive (static lib with static dependencies)
REM tests do not work with MinGW due to http://code.google.com/p/libarchive/issues/detail?id=319
mkdir build-desktop
cd build-desktop
cmake ^
  -DENABLE_TEST=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-mingw\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-mingw\lib-static ^
  -G"MinGW Makefiles" ^
  ..\src\libarchive-3.1.2
make
move /Y bin\bsdcpio.exe ..\build\win-mingw\bin\bsdcpio.exe
move /Y bin\bsdtar.exe ..\build\win-mingw\bin\bsdtar.exe
move /Y libarchive\libarchive_static.a ..\build\win-mingw\lib-static\libarchive.a
cd ..
copy /Y src\libarchive-3.1.2\libarchive\archive.h build\win-mingw\include\archive.h
copy /Y src\libarchive-3.1.2\libarchive\archive_entry.h build\win-mingw\include\archive_entry.h

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing


REM default libs
mkdir build\win-mingw\lib
copy /Y build\win-mingw\lib-static\*.* build\win-mingw\lib

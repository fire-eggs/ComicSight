REM build result directory structure
mkdir build
cd build
mkdir win-msvc
cd win-msvc
mkdir bin
mkdir include
mkdir lib-shared
mkdir lib-static
mkdir lib-static-shared-fltk
cd ..\..

set PATH=%PATH%;%CD%\build\win-msvc\lib-shared

set CFLAGS=/GL
set CPPFLAGS=/GL

REM build zlib
mkdir build-desktop
cd build-desktop
cmake ^
  -DCMAKE_BUILD_TYPE=Release ^
  -G"NMake Makefiles" ^
  ..\src\zlib-1.2.8
nmake
move /Y example.exe ..\build\win-msvc\bin\example-zlib.exe
move /Y minigzip.exe ..\build\win-msvc\bin\minigzip.exe
move /Y zconf.h ..\build\win-msvc\include\zconf.h
move /Y zlib.dll ..\build\win-msvc\lib-shared\zlib.dll
move /Y zlib.lib ..\build\win-msvc\lib-shared\zlib.lib
move /Y zlibstatic.lib ..\build\win-msvc\lib-static\zlib.lib
cd ..
copy /Y src\zlib-1.2.8\zlib.h build\win-msvc\include\zlib.h

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build libpng (shared lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DPNG_SHARED=ON -DPNG_STATIC=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-msvc\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-msvc\lib-shared ^
  -G"NMake Makefiles" ^
  ..\src\libpng-1.6.7
nmake
move /Y libpng16.dll ..\build\win-msvc\lib-shared\libpng16.dll
move /Y libpng16.lib ..\build\win-msvc\lib-shared\libpng.lib
cd ..

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build libpng (static lib with static dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-msvc\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-msvc\lib-static ^
  -G"NMake Makefiles" ^
  ..\src\libpng-1.6.7
nmake
move /Y pngtest.exe ..\build\win-msvc\bin\pngtest.exe
move /Y pngvalid.exe ..\build\win-msvc\bin\pngvalid.exe
move /Y pnglibconf.h ..\build\win-msvc\include\pnglibconf.h
move /Y libpng16_static.lib ..\build\win-msvc\lib-static\libpng.lib
cd ..
copy /Y src\libpng-1.6.7\png.h build\win-msvc\include\png.h
copy /Y src\libpng-1.6.7\pngconf.h build\win-msvc\include\pngconf.h

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build libjpeg
mkdir build-desktop
cd build-desktop
cmake ^
  -DCMAKE_BUILD_TYPE=Release ^
  -G"NMake Makefiles" ^
  ..\src\libjpeg-turbo-1.3.0
nmake
move /Y cjpeg-static.exe ..\build\win-msvc\bin\cjpeg-static.exe
move /Y djpeg-static.exe ..\build\win-msvc\bin\djpeg-static.exe
move /Y jpegtran-static.exe ..\build\win-msvc\bin\jpegtran-static.exe
move /Y rdjpgcom.exe ..\build\win-msvc\bin\rdjpgcom.exe
move /Y tjbench.exe ..\build\win-msvc\bin\tjbench.exe
move /Y tjbench-static.exe ..\build\win-msvc\bin\tjbench-static.exe
move /Y tjunittest.exe ..\build\win-msvc\bin\tjunittest.exe
move /Y tjunittest-static.exe ..\build\win-msvc\bin\tjunittest-static.exe
move /Y wrjpgcom.exe ..\build\win-msvc\bin\wrjpgcom.exe
move /Y sharedlib\cjpeg.exe ..\build\win-msvc\bin\cjpeg.exe
move /Y sharedlib\djpeg.exe ..\build\win-msvc\bin\djpeg.exe
move /Y sharedlib\jcstest.exe ..\build\win-msvc\bin\jcstest.exe
move /Y sharedlib\jpegtran.exe ..\build\win-msvc\bin\jpegtran.exe
move /Y turbojpeg.dll ..\build\win-msvc\bin\turbojpeg.dll
move /Y jconfig.h ..\build\win-msvc\include\jconfig.h
move /Y turbojpeg-static.lib ..\build\win-msvc\lib-static\jpeg.lib
move /Y sharedlib\jpeg62.dll ..\build\win-msvc\lib-shared\jpeg62.dll
move /Y sharedlib\jpeg.lib ..\build\win-msvc\lib-shared\jpeg.lib
cd ..
copy /Y src\libjpeg-turbo-1.3.0\jpeglib.h build\win-msvc\include\jpeglib.h
copy /Y src\libjpeg-turbo-1.3.0\jmorecfg.h build\win-msvc\include\jmorecfg.h
copy /Y src\libjpeg-turbo-1.3.0\jpegint.h build\win-msvc\include\jpegint.h
copy /Y src\libjpeg-turbo-1.3.0\jerror.h build\win-msvc\include\jerror.h

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build fltk (shared lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DOPTION_BUILD_SHARED_LIBS=ON ^
  -DOPTION_BUILD_EXAMPLES=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-msvc\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-msvc\lib-shared ^
  -G"NMake Makefiles" ^
  ..\src\fltk-1.3.2
nmake
move /Y lib\fltkdll.lib ..\build\win-msvc\lib-shared\fltk.lib
move /Y lib\fltkdll.dll ..\build\win-msvc\lib-shared\fltk.dll
move /Y lib\fltkformsdll.lib ..\build\win-msvc\lib-shared\fltkforms.lib
move /Y lib\fltkformsdll.dll ..\build\win-msvc\lib-shared\fltkforms.dll
move /Y lib\fltkgldll.lib ..\build\win-msvc\lib-shared\fltkgl.lib
move /Y lib\fltkgldll.dll ..\build\win-msvc\lib-shared\fltkgl.dll
move /Y lib\fltkimagesdll.lib ..\build\win-msvc\lib-shared\fltkimages.lib
move /Y lib\fltkimagesdll.dll ..\build\win-msvc\lib-shared\fltkimages.dll
cd ..

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build fltk (static lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DOPTION_BUILD_EXAMPLES=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-msvc\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-msvc\lib-shared ^
  -G"NMake Makefiles" ^
  ..\src\fltk-1.3.2
nmake
move /Y lib\fltk.lib ..\build\win-msvc\lib-static-shared-fltk\fltk.lib
move /Y lib\fltkforms.lib ..\build\win-msvc\lib-static-shared-fltk\fltkforms.lib
move /Y lib\fltkgl.lib ..\build\win-msvc\lib-static-shared-fltk\fltkgl.lib
move /Y lib\fltkimages.lib ..\build\win-msvc\lib-static-shared-fltk\fltkimages.lib
cd ..

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build fltk (static lib with static dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DOPTION_BUILD_EXAMPLES=OFF ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-msvc\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-msvc\lib-static ^
  -G"NMake Makefiles" ^
  ..\src\fltk-1.3.2
nmake
move /Y bin\fluid.exe ..\build\win-msvc\bin\fluid.exe
move /Y lib\fltk.lib ..\build\win-msvc\lib-static\fltk.lib
move /Y lib\fltkforms.lib ..\build\win-msvc\lib-static\fltkforms.lib
move /Y lib\fltkgl.lib ..\build\win-msvc\lib-static\fltkgl.lib
move /Y lib\fltkimages.lib ..\build\win-msvc\lib-static\fltkimages.lib
cd ..
mkdir build\win-msvc\include\FL
copy /Y src\fltk-1.3.2\FL\*.h build\win-msvc\include\FL
copy /Y src\fltk-1.3.2\FL\*.H build\win-msvc\include\FL

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM liblzma
REM (CMake based on https://projects.kde.org/projects/kdesupport/emerge/repository/revisions/master/show/portage/win32libs/liblzma)
REM this has to be build with MinGW (since MSVC is not supported) and the library has to be renamed
if not [%CFLAGS%] == [%^CFLAGS%] set CFLAGS_BACKUP=%CFLAGS%
if not [%CPPFLAGS%] == [%^CPPFLAGS%] set CPPFLAGS_BACKUP=%CPPFLAGS%
set CFLAGS=
set CPPFLAGS=

mkdir build-desktop
cd build-desktop
cmake ^
  -DCMAKE_BUILD_TYPE=Release ^
  -G"MinGW Makefiles" ^
  ..\src\xz-5.0.5
make
move /Y lzmadec.exe ..\build\win-msvc\bin\lzmadec.exe
move /Y lzmainfo.exe ..\build\win-msvc\bin\lzmainfo.exe
move /Y xz.exe ..\build\win-msvc\bin\xz.exe
move /Y xzdec.exe ..\build\win-msvc\bin\xzdec.exe
move /Y liblzma.dll ..\build\win-msvc\lib-shared\liblzma.dll
move /Y liblzma.dll.a ..\build\win-msvc\lib-shared\liblzma.lib
move /Y liblzmastatic.a ..\build\win-msvc\lib-static\liblzma.lib
cd ..
mkdir build\win-msvc\include\lzma
copy /Y src\xz-5.0.5\src\liblzma\api\*.h build\win-msvc\include
copy /Y src\xz-5.0.5\src\liblzma\api\lzma\*.h build\win-msvc\include\lzma

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

if not [%CFLAGS_BACKUP%] == [%^CFLAGS_BACKUP%] set CFLAGS=%CFLAGS_BACKUP%
if not [%CPPFLAGS_BACKUP%] == [%^CPPFLAGS_BACKUP%] set CPPFLAGS=%CPPFLAGS_BACKUP%

REM build libarchive (shared lib with shared dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-msvc\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-msvc\lib-shared ^
  -G"NMake Makefiles" ^
  ..\src\libarchive-3.1.2
nmake
move /Y bin\archive.dll ..\build\win-msvc\lib-shared\archive.dll
move /Y libarchive\archive.lib ..\build\win-msvc\lib-shared\archive.lib
cd ..

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing

REM build libarchive (static lib with static dependencies)
mkdir build-desktop
cd build-desktop
cmake ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INCLUDE_PATH=..\..\build\win-msvc\include ^
  -DCMAKE_LIBRARY_PATH=..\..\build\win-msvc\lib-static ^
  -G"NMake Makefiles" ^
  ..\src\libarchive-3.1.2
nmake
move /Y bin\bsdcpio.exe ..\build\win-msvc\bin\bsdcpio.exe
move /Y bin\bsdtar.exe ..\build\win-msvc\bin\bsdtar.exe
move /Y libarchive\archive_static.lib ..\build\win-msvc\lib-static\archive.lib
cd ..
copy /Y src\libarchive-3.1.2\libarchive\archive.h build\win-msvc\include\archive.h
copy /Y src\libarchive-3.1.2\libarchive\archive_entry.h build\win-msvc\include\archive_entry.h

move build-desktop build-desktop-removing
rmdir /S /Q build-desktop-removing


REM default libs
mkdir build\win-msvc\lib
copy /Y build\win-msvc\lib-static\*.* build\win-msvc\lib

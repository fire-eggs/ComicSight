ComicSight: Building
====================

Build system
------------

To build the application (and its prerequisite libraries), the
[CMake](http://cmake.org/) build system is used.


Prerequisite Libraries
----------------------

In order to compile the program, you need the development files for the
following libraries:

* [FLTK](http://fltk.org/)
  is required since the user interface is based on it

  You are advised to compile FLTK with the supplied patches applied as described
  in the next subsection

The following libraries are highly recommended to generate a useful build:

* [libarchive](http://libarchive.org/)
  is used to access compressed comic book archives

* [libjpeg](http://ijg.org/) or
  [libjpeg-turbo](http://libjpeg-turbo.virtualgl.org/)
  is used to read JPEG image files

* [libpng](http://libpng.org/pub/png/libpng.html)
  is used to read PNG image files

If you are not using pre-compiled development builds for the libraries above,
but you are going to build them yourself, the following libraries also are
of interest:

* [zlib](http://zlib.net/)
  is required for libpng and recommended for libarchive

* [liblzma](http://tukaani.org/xz/)
  is used by libarchive to read LZMA-compressed files


Compiling the Prerequisite Libraries
------------------------------------

For details on how to compile the prerequisite libraries, please refer to the
respective documentation. How to build those is out of scope of this document
except for the supplied patch to the FLTK library. Still some other patches to
the CMake build files for the used libraries are provided in the `lib/src`
directory for information purposes. If you are having trouble building one of
those libraries, you may look into those patches as well.

For the FLTK library, there is also an `important.patch` file that changes some
of the library's code. You are recommended to apply this patch and build a
patched FLTK version to link against. FLTK is linked statically, so those
patches will apply even if using otherwise dynamically linked libraries provided
by the system. The patches are also submitted to the
[FLTK bug tracker](http://fltk.org/str.php) as #2978, #2980, #2981 and #2998.

Further help on how to build the libraries is given in form of some shell and
batch scripts in the `lib` directory. Those are provided for information
purposes. They assume the source code for each library to be placed in its own
directory under `lib/src` and will produce `bin`, `include` and `lib`
directories under `lib/build/[system]`.

Additionally to the standard library search paths, the ComicSight build system
will also automatically search for libraries in `lib/[system]` and
`lib/build/[system]`, where `[system]` is a string including the operating
system name, the compiler name, and/or the system architecture.


Prerequisite Tools
------------------

The build system will produce raster graphics (such as PNG files) from the
source vector graphics (SVG files). To accomplish this, the following
applications must be available to the build system:

* [ImageMagick](http://imagemagick.org/) is needed to convert between image
  formats

The following applications are highly recommended:

* [Inkscape](http://inkscape.org/) is the preferred application to rasterize
  SVG images; although the build system can fall back to ImageMagick for this
  purpose, the conversion result may not yield the same quality as compared to
  using Inkscape; there may even be problems of inaccurate color conversion with
  ImageMagick builds for some architectures

* [pngquant](http://pngquant.org/) (at least version 2 required) is used to
  quantize images resulting in smaller file size

* [PNGOUT](http://advsys.net/ken/utils.htm) or
  [OptiPNG](http://optipng.sourceforge.net/) is used to optimize compressed PNG
  images, PNGOUT is preferred over OptiPNG because it yields better compression
  ratios and is even faster

Additionally, during packaging and runtime, the application can make use of the
proprietary [unRAR](http://rarlab.com/rar_add.htm) utility to read certain RAR
files that libarchive is not capable of handling. On Microsoft Windows, the
unRAR DLL can be included in the created package. You can put the library
`unrar.dll` for the respective architecture into `lib/win-amd64/lib` or
`lib/win-x86/lib`. On Mac OS X, the unRAR executable can be included in the
created package. You can put the (universal) binary `unrar` into `lib/osx/bin`.
The unRAR binaries are distributed under a license that allows the utility to be
used in other software.


Compiling the ComicSight application
------------------------------------

Once all prerequisites are available, you can invoke the build system using the
following command on the command line:

    cmake

You can use several arguments for the `cmake` invocation

* `-G"Unix Makefiles"` to create Unix makefiles for the use with GCC or Clang
* `-G"MinGW Makefiles"` to create makefiles for the use with MinGW
* `-G"NMake Makefiles"` to create makefiles for the use with MSVC
* `-DCMAKE_BUILD_TYPE=Release` to configure a release build
* `-DCMAKE_BUILD_TYPE=Debug` to configure a debug build

CMake is also capable of creating project files for certain IDEs. Please refer to
the CMake documentation for further information on the command line arguments.

Additionally, for the ComicSight build system the following arguments can be
used:

* `-DSTATIC_BUILD=ON` or `-DSTATIC_BUILD=OFF` switches static linking against
  the C and C++ runtime libraries on or off; this defaults to `ON` for MinGW
  builds and to `OFF` for others
* `-DOPTIMIZATION_FLAGS=OFF` turns off automatic appending of certain additional
  compiler optimization flags for the release build
* `-DVERSION=[version string]` forces the given version string to be used,
  otherwise the build system tries to infer sensible version information from
  Git tags, the changelog file, the directory name or the current date

If CMake has successfully generated the makefiles, you can just build the
application using

    make

or, when using MSVC,

    nmake


ComicSight: Packaging
=====================

The build system also provides means to create deployable packages of the
application using the CPack packaging system that is integrated with CMake.
Depending on the current platform, you can use one of the following commands to
create a package:

* `cpack -G ZIP` or `cpack -G TZ` or `cpack -G TGZ` or `cpack -G TBZ2` to create
  a simple compressed archive in the format zip, tar.Z, tar.gz or tar.bz2
* `cpack -G DEB` to create a Linux DEB package
* `cpack -G RPM` to create a Linux RPM package
* `cpack -G DragNDrop` or `cpack -G Bundle` to create a OS X DMG drag-and-drop
  installer
* `cpack -G NSIS` to create a Windows EXE installer;
  [NSIS](http://nsis.sourceforge.net/) must be available to build the installer

Please refer to the CPack documentation for further information on the command
line arguments.

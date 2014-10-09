ComicSight: Changelog
=====================

## v0.1
* initial working version
* support for CBZ, CBR, CBT, and CB7 archive file type through libarchive.
  For certain RAR subfiles that libarchive does handle (bug #262 and #338),
  the applications relies on the unrar utility
* support for JPEG and PNG images
* support for the GNOME Virtual File System (GVFS) using gvfs-fuse
* uses nearest-neighbor resampling for fast image resizing
* uses Lanczos resampling for high-quality image resizing
* depending on the configuration, uses the libraries FLTK, libarchive,
  libjpeg resp. libjpeg-turbo and libpng
* build supported at least on Linux (GCC >= 4.7), Mac OS X (Clang >= 3.4) and
  Microsoft Windows (MinGW using GCC >= 4.7 posix threads version for
  std::thread support or MSVC >= 11.0)

ComicSight
==========

A simple fast viewer for comic book archives

ComicSight is a lightweight graphical viewer application for the sole purpose
of displaying comic book archives. It supports the common comic book archive
file types like CBZ, CBR, CBT and CB7 and uncompressed comic book folders.

The program runs on Linux (or other Unix-like operating systems that run the
X Window System), as well as on Mac OS X and on Microsoft Windows.

The following command line arguments are supported:

* --fullscreen

  Starts the application in fullscreen mode
  giving the user no possibility to return to windowed mode

* --version

  Prints version information to the console and terminates,
  does not start the graphical user interface

ComicSight makes use of the following libraries:

* [FLTK](http://www.fltk.org/)
* [libarchive](http://www.libarchive.org/)
* [libjpeg](http://ijg.org/) or
  [libjpeg-turbo](http://libjpeg-turbo.virtualgl.org/)
* [libpng](http://www.libpng.org/pub/png/libpng.html)

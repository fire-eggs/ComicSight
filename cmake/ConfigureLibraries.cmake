include_directories(${PROJECT_SOURCE_DIR}/src)

# use dl library on Unix to dynamically load shared objects
if(UNIX)
    find_package(DL)
    if(DL_FOUND)
        include_directories(${DL_INCLUDE_DIR})
    endif(DL_FOUND)
endif(UNIX)

# use FLTK (this is a required dependency)
set(FLTK_SKIP_FLUID TRUE)
set(FLTK_SKIP_OPENGL TRUE)
set(FLTK_SKIP_FORMS TRUE)
find_package(FLTK REQUIRED)
include(AddLibrariesForFLTK)
include_directories(${FLTK_INCLUDE_DIR})

# use libjpeg, if available
find_package(JPEG)
if(JPEG_FOUND)
    include_directories(${JPEG_INCLUDE_DIR})
    add_definitions(-DHAVE_LIBJPEG)
else(JPEG_FOUND)
    message(WARNING "Warning: no JPEG support")
endif(JPEG_FOUND)

# use libpng, if available
find_package(PNG)
if(PNG_FOUND)
    include_directories(${PNG_INCLUDE_DIRS})
    add_definitions(-DHAVE_LIBPNG)
else(PNG_FOUND)
    message(WARNING "Warning: no PNG support")
endif(PNG_FOUND)

# use libarchive, if available
find_package(LibArchive)
if(LibArchive_FOUND)
    include(AddLibrariesForLibArchive)
    include_directories(${LibArchive_INCLUDE_DIRS})
    add_definitions(-DHAVE_LIBARCHIVE)
else(LibArchive_FOUND)
    message(WARNING "Warning: no archive file support")
endif(LibArchive_FOUND)

# use X11 XPM image support, if available
if(UNIX AND NOT APPLE)
    find_package(X11)
    if(X11_FOUND)
        add_definitions(-DHAVE_X11)
        if(X11_Xpm_FOUND)
            include_directories(${X11_Xpm_INCLUDE_PATH})
            add_definitions(-DHAVE_X11XPM)
        else(X11_Xpm_FOUND)
            message(STATUS "Warning: no X11 pixmap window icon support")
        endif(X11_Xpm_FOUND)
    else(X11_Xpm_FOUND)
        message(STATUS "Warning: no X11 support")
    endif(X11_FOUND)
else(UNIX AND NOT APPLE)
    # make sure we do not link against X11 libraries on OS X
    # which might have been found by the FLTK package
    set(X11_Xpm_LIB "")
endif(UNIX AND NOT APPLE)

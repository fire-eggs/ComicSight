if(CMAKE_CROSSCOMPILING)
    # import embedres from a file when cross-compiling
    if(NOT DEFINED NATIVE_BUILD_BINARY_DIR)
        set(NATIVE_BUILD_BINARY_DIR "${PROJECT_BINARY_DIR}")
    endif(NOT DEFINED NATIVE_BUILD_BINARY_DIR)
    set(IMPORT_EXECUTABLES "${NATIVE_BUILD_BINARY_DIR}/embedres.cmake"
        CACHE FILEPATH "embedres native executable")
    include(${IMPORT_EXECUTABLES})
else(CMAKE_CROSSCOMPILING)
    # only build embedres when not cross-compiling
    add_executable(embedres res/src/embedres.c)
    export(TARGETS embedres FILE "${PROJECT_BINARY_DIR}/embedres.cmake")
endif(CMAKE_CROSSCOMPILING)


# embed resources
include_directories("${PROJECT_BINARY_DIR}")
add_custom_command(
    OUTPUT comicsight.res.c
    COMMAND embedres comicsight "${PROJECT_BINARY_DIR}/comicsight96.png"
    DEPENDS embedres "${PROJECT_BINARY_DIR}/comicsight96.png"
    VERBATIM)
add_custom_command(
    OUTPUT eyes.res.c
    COMMAND embedres eyes "${PROJECT_BINARY_DIR}/eyes.png"
    DEPENDS embedres "${PROJECT_BINARY_DIR}/eyes.png"
    VERBATIM)
add_custom_command(
    OUTPUT eyes_background.res.c
    COMMAND embedres eyes_background "${PROJECT_BINARY_DIR}/eyes-background.png"
    DEPENDS embedres "${PROJECT_BINARY_DIR}/eyes-background.png"
    VERBATIM)
add_custom_command(
    OUTPUT eyes_foreground.res.c
    COMMAND embedres eyes_foreground "${PROJECT_BINARY_DIR}/eyes-foreground.png"
    DEPENDS embedres "${PROJECT_BINARY_DIR}/eyes-foreground.png"
    VERBATIM)


# main executable
add_executable(comicsight WIN32
    version.c
    comicsight.res.c
    eyes.res.c
    eyes_background.res.c
    eyes_foreground.res.c
    comicsight.rc
    src/comicsight.cpp
    src/controller.cpp
    src/util/backgroundworker.cpp
    src/util/vfsresolver.cpp
    src/util/concurrent.h
    src/gui/fltkex.cpp
    src/gui/mixin.h
    src/gui/osx.mm
    src/gui/win32.cpp
    src/gui/window.cpp
    src/gui/windowmanager.cpp
    src/gui/x11.cpp
    src/comic/comic.cpp
    src/comic/contentprovider.h
    src/comic/directorycontentprovider.cpp
    src/comic/archivecontentprovider.cpp
    src/image/image.cpp
    src/image/colortype.cpp
    src/image/resample.cpp)

if(NOT APPLE)
    if(MSVC)
        set_source_files_properties(src/gui/osx.mm PROPERTIES COMPILE_FLAGS "/TP")
    else(MSVC)
        set_source_files_properties(src/gui/osx.mm PROPERTIES COMPILE_FLAGS "-x c++")
    endif(MSVC)
endif(NOT APPLE)

add_dependencies(comicsight version images)

target_link_libraries(comicsight ${DL_LIBRARIES})
target_link_libraries(comicsight ${FLTK_LIBRARIES})
target_link_libraries(comicsight ${JPEG_LIBRARIES})
target_link_libraries(comicsight ${PNG_LIBRARIES})
target_link_libraries(comicsight ${LibArchive_LIBRARIES})
target_link_libraries(comicsight ${X11_Xpm_LIB})

if(APPLE)
    # build OSX bundle
    if(iconutil_FOUND)
        add_custom_command(
            OUTPUT
              "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/MacOS/comicsight"
              "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Info.plist"
              "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Resources/comicsight.icns"
            COMMAND mkdir -p "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/MacOS"
            COMMAND mkdir -p "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Resources"
            COMMAND cp
              "${PROJECT_BINARY_DIR}/comicsight"
              "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/MacOS/comicsight"
            COMMAND cp
              "${PROJECT_BINARY_DIR}/Info.plist"
              "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Info.plist"
            COMMAND cp
              "${PROJECT_BINARY_DIR}/comicsight.icns"
              "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Resources/comicsight.icns"
            DEPENDS
              "${PROJECT_BINARY_DIR}/comicsight"
              "${PROJECT_BINARY_DIR}/Info.plist"
              "${PROJECT_BINARY_DIR}/comicsight.icns"
            VERBATIM)

        add_custom_target(comicsightbundle ALL SOURCES
            "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/MacOS/comicsight"
            "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Info.plist"
            "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Resources/comicsight.icns")
    else(iconutil_FOUND)
        add_custom_command(
            OUTPUT
              "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/MacOS/comicsight"
              "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Info.plist"
            COMMAND mkdir -p "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/MacOS"
            COMMAND mkdir -p "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Resources"
            COMMAND cp
              "${PROJECT_BINARY_DIR}/comicsight"
              "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/MacOS/comicsight"
            COMMAND cp
              "${PROJECT_BINARY_DIR}/Info.plist"
              "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Info.plist"
            DEPENDS
              "${PROJECT_BINARY_DIR}/comicsight"
              "${PROJECT_BINARY_DIR}/Info.plist"
            VERBATIM)

        add_custom_target(comicsightbundle ALL SOURCES
            "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/MacOS/comicsight"
            "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Info.plist")
    endif(iconutil_FOUND)
endif(APPLE)

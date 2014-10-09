# VERSION can be set before including this script to use a fixed version value

get_filename_component(_CONFIGURE_VERSION_CMAKE_FILE ${CMAKE_CURRENT_LIST_FILE} ABSOLUTE)

include(VersionInference)

if(VERSION)
    message(STATUS "Forced version string ${VERSION}")
else(VERSION)
    if(NOT EXISTS "${PROJECT_SOURCE_DIR}/.git")
        message(STATUS "Not building from a Git checkout")
    endif(NOT EXISTS "${PROJECT_SOURCE_DIR}/.git")

    version_from_git(VERSION)
    if(NOT VERSION)
        version_from_changelog(VERSION "${PROJECT_SOURCE_DIR}/CHANGES.md")
    endif(NOT VERSION)
    if(NOT VERSION)
        version_from_directory(VERSION "${PROJECT_SOURCE_DIR}")
    endif(NOT VERSION)
    if(NOT VERSION)
        version_from_date(VERSION)
    endif(NOT VERSION)
    message(STATUS "Inferred version string ${VERSION}")

    set(_CONFIGURE_VERSION_ADD_CUSTOM_TARGET ON)
endif(VERSION)

# extract version numbers and format them as four comma-separated numbers
# for the Windows resource file
string(REGEX MATCH "[0-9]+(\\.[0-9]+)*" WIN32_FILEVERSION "${VERSION}")
string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+" WIN32_FILEVERSION "${WIN32_FILEVERSION}.0.0.0.0")
string(REPLACE "." "," WIN32_FILEVERSION "${WIN32_FILEVERSION}")
set(WIN32_PRODUCTVERSION "${WIN32_FILEVERSION}")

# set full version information for the Windows resource file
set(WIN32_FILEVERSION_STR "${VERSION}")
set(WIN32_PRODUCTVERSION_STR "${VERSION}")

# set debug and pre-release flags for the Windows resource file
set(WIN32_FILEFLAGS "0")
if(CMAKE_BUILD_TYPE MATCHES "^[Dd][Ee][Bb][Uu][Gg]$")
    set(WIN32_FILEFLAGS "${WIN32_FILEFLAGS} | VS_FF_DEBUG")
endif(CMAKE_BUILD_TYPE MATCHES "^[Dd][Ee][Bb][Uu][Gg]$")
if(VERSION MATCHES "untagged|modified|git")
    set(WIN32_FILEFLAGS "${WIN32_FILEFLAGS} | VS_FF_PRERELEASE")
endif(VERSION MATCHES "untagged|modified|git")

# extract version numbers and format them as three dot-separated numbers
# for the OS X bundle information file
string(REGEX MATCH "[0-9]+(\\.[0-9]+)*" OSX_VERSION "${VERSION}")
string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" OSX_VERSION "${OSX_VERSION}.0.0.0")

# set full version information for the OS X bundle information file
set(OSX_VERSION_STR "${VERSION}")

# configure Windows resource file, the OS X bundle information file and the version source code file
configure_file("${PROJECT_SOURCE_DIR}/res/win/comicsight.rc" "${PROJECT_BINARY_DIR}/comicsight.rc")
configure_file("${PROJECT_SOURCE_DIR}/res/osx/Info.plist" "${PROJECT_BINARY_DIR}/Info.plist")
configure_file("${PROJECT_SOURCE_DIR}/src/version.c" "${PROJECT_BINARY_DIR}/version.c")

# create a target that will run this script file for every build
if(NOT _CONFIGURE_VERSION_CALLED_AS_CMAKE_SCRIPT)
    set_source_files_properties("${PROJECT_BINARY_DIR}/comicsight.rc" PROPERTIES GENERATED TRUE)
    set_source_files_properties("${PROJECT_BINARY_DIR}/Info.plist" PROPERTIES GENERATED TRUE)
    set_source_files_properties("${PROJECT_BINARY_DIR}/version.c" PROPERTIES GENERATED TRUE)

    if(_CONFIGURE_VERSION_ADD_CUSTOM_TARGET)
        add_custom_target(version ALL
                          COMMAND "${CMAKE_COMMAND}"
                            "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}"
                            "-DPROJECT_SOURCE_DIR=${PROJECT_SOURCE_DIR}"
                            "-DPROJECT_BINARY_DIR=${PROJECT_BINARY_DIR}"
                            "-D_CONFIGURE_VERSION_CALLED_AS_CMAKE_SCRIPT=ON"
                            -P "${_CONFIGURE_VERSION_CMAKE_FILE}"
                          COMMENT "Checking application version"
                          VERBATIM
                          SOURCES
                            "${PROJECT_BINARY_DIR}/comicsight.rc"
                            "${PROJECT_BINARY_DIR}/Info.plist"
                            "${PROJECT_BINARY_DIR}/version.c")
    endif(_CONFIGURE_VERSION_ADD_CUSTOM_TARGET)
endif(NOT _CONFIGURE_VERSION_CALLED_AS_CMAKE_SCRIPT)

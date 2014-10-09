set(PACKAGING_TARGET_FILES)

# build prerequisites for OSX DMG drag-and-drop installer
if(APPLE)
    set(OSX_INSTALLER_DMG_VOLUME_NAME "ComicSight")
    set(OSX_INSTALLER_DMG_BACKGROUND_IMAGE "${PROJECT_BINARY_DIR}/osxinstaller.png")
    set(OSX_INSTALLER_DMG_DS_STORE "${PROJECT_BINARY_DIR}/DS_Store")

    add_custom_command(
        OUTPUT "${OSX_INSTALLER_DMG_DS_STORE}"
        COMMAND sh
          "${PROJECT_SOURCE_DIR}/res/osx/create-dmg-ds-store.sh"
          "${OSX_INSTALLER_DMG_VOLUME_NAME}"
          "${OSX_INSTALLER_DMG_BACKGROUND_IMAGE}"
        COMMAND "${CMAKE_COMMAND}" -E copy
          "${PROJECT_BINARY_DIR}/osx/DS_Store"
          "${OSX_INSTALLER_DMG_DS_STORE}"
        WORKING_DIRECTORY
          "${PROJECT_BINARY_DIR}/osx"
        DEPENDS
          "${PROJECT_SOURCE_DIR}/res/osx/create-dmg-ds-store.sh"
          "${OSX_INSTALLER_DMG_BACKGROUND_IMAGE}"
        VERBATIM)

    list(APPEND PACKAGING_TARGET_FILES "${OSX_INSTALLER_DMG_DS_STORE}")
endif(APPLE)

# find and include unrar binary file
if(WIN32)
    find_file(UNRAR_BINARY NAMES unrar.dll PATH_SUFFIXES lib ONLY_CMAKE_FIND_ROOT_PATH)
else(WIN32)
    find_program(UNRAR_BINARY NAMES unrar ONLY_CMAKE_FIND_ROOT_PATH)
endif(WIN32)

if(UNRAR_BINARY)
    get_filename_component(UNRAR_BINARY_NAME "${UNRAR_BINARY}" NAME)

    if(UNIX)
        add_custom_command(
            OUTPUT "${PROJECT_BINARY_DIR}/${UNRAR_BINARY_NAME}"
            COMMAND cp "${UNRAR_BINARY}" "${PROJECT_BINARY_DIR}"
            COMMAND chmod 0775 "${PROJECT_BINARY_DIR}/${UNRAR_BINARY_NAME}"
            DEPENDS "${UNRAR_BINARY}"
            VERBATIM)
    else(UNIX)
        add_custom_command(
            OUTPUT "${PROJECT_BINARY_DIR}/${UNRAR_BINARY_NAME}"
            COMMAND "${CMAKE_COMMAND}" -E copy "${UNRAR_BINARY}" "${PROJECT_BINARY_DIR}"
            DEPENDS "${UNRAR_BINARY}"
            VERBATIM)
    endif(UNIX)

    set(UNRAR_BINARY "${PROJECT_BINARY_DIR}/${UNRAR_BINARY_NAME}")
    list(APPEND PACKAGING_TARGET_FILES "${UNRAR_BINARY}")

    if(NOT WIN32 AND NOT APPLE)
        message(STATUS "RAR supported for all RAR subtypes "
                       "through the external unRAR utility. "
                       "DEB packages built by this build system "
                       "will contain the unRAR external dependency as suggestion. "
                       "RPM packages built by this build system "
                       "will not contain the unRAR external dependency.")
    endif(NOT WIN32 AND NOT APPLE)
else(UNRAR_BINARY)
    if(WIN32 OR APPLE)
        message(WARNING "Warning: no RAR support for all RAR subtypes")
    else(WIN32 OR APPLE)
        message(WARNING "Warning: no RAR support for all RAR subtypes. "
                        "DEB packages built by this build system "
                        "will contain the unRAR external dependency as suggestion. "
                        "RPM packages built by this build system "
                        "will not contain the unRAR external dependency.")
    endif(WIN32 OR APPLE)
endif(UNRAR_BINARY)

mark_as_advanced(UNRAR_BINARY)

# add package target
add_custom_target(packaging ALL SOURCES ${PACKAGING_TARGET_FILES})
add_dependencies(packaging version images)

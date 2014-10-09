# SYSTEM_ARCHITECTURE and SYSTEM_ENDIAN should be set before including this script


set(CPACK_PROJECT_CONFIG_FILE "${PROJECT_SOURCE_DIR}/cmake/CPackOptions.cmake")


set(CPACK_INSTALL_CMAKE_PROJECTS "${PROJECT_BINARY_DIR};${PROJECT_NAME};main;/")
set(CPACK_COMPONENTS_ALL_IN_ONE_PACKAGE 1)
set(CPACK_STRIP_FILES TRUE)


string(TOLOWER "${CMAKE_SYSTEM_NAME}-${SYSTEM_ARCHITECTURE}-${SYSTEM_ENDIAN}" CPACK_SYSTEM_NAME)
string(REPLACE "/" "" CPACK_SYSTEM_NAME "${CPACK_SYSTEM_NAME}")
string(REPLACE ";" "+" CPACK_SYSTEM_NAME "${CPACK_SYSTEM_NAME}")
if(WIN32)
    if(SYSTEM_ARCHITECTURE MATCHES "i.86")
        set(CPACK_SYSTEM_NAME "win32")
        set(CPACK_NSIS_DEFINES)
    endif(SYSTEM_ARCHITECTURE MATCHES "i.86")
    if(SYSTEM_ARCHITECTURE MATCHES "x86_64")
        set(CPACK_SYSTEM_NAME "win64")
        set(CPACK_NSIS_DEFINES "!define INSTALL64")
    endif(SYSTEM_ARCHITECTURE MATCHES "x86_64")
endif(WIN32)


set(CPACK_PACKAGE_NAME "${CMAKE_PROJECT_NAME}")
set(CPACK_PACKAGE_VENDOR "Pascal Weisenburger")
set(CPACK_PACKAGE_CONTACT "Pascal Weisenburger <pascal.weisenburger@web.de>")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${PROJECT_SOURCE_DIR}/README.md")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "A viewer for comic book archives")

set(CPACK_PACKAGE_EXECUTABLES "comicsight;ComicSight")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "ComicSight")

set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/LICENSE.md")
set(CPACK_RESOURCE_FILE_README "${PROJECT_SOURCE_DIR}/README.md")


# DEB
set(CPACK_DEBIAN_PACKAGE_SECTION "Graphics")
set(CPACK_DEBIAN_PACKAGE_SUGGESTS "gvfs-fuse, unrar")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${PROJECT_SOURCE_DIR}/res/deb/postinst"
                                       "${PROJECT_SOURCE_DIR}/res/deb/postrm")


# RPM
set(CPACK_RPM_PACKAGE_LICENSE "ISC")
set(CPACK_RPM_PACKAGE_GROUP "Amusements/Graphics")
set(CPACK_RPM_CHANGELOG_FILE "${PROJECT_SOURCE_DIR}/res/rpm/changelog")
set(CPACK_RPM_POST_INSTALL_SCRIPT_FILE "${PROJECT_SOURCE_DIR}/res/rpm/post")
set(CPACK_RPM_POST_UNINSTALL_SCRIPT_FILE "${PROJECT_SOURCE_DIR}/res/rpm/postun")
set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST "*")
set(CPACK_RPM_PACKAGE_SUGGESTS "gvfs-fuse, unrar")  # this will have no effect since
                                                    # most RPM version do not support suggestions
                                                    # (see http://public.kitware.com/Bug/view.php?id=13423)
                                                    # but these should not be required via
                                                    # CPACK_RPM_PACKAGE_REQUIRES


# NSIS
# there is a bug that causes NSIS not to handle full unix paths properly
# you have to make sure that there is at least one backslash
set(CPACK_NSIS_DEFINES "${CPACK_NSIS_DEFINES}
                        !ifdef INSTALL64
                          !include \\\"${PROJECT_SOURCE_DIR}/res/win\\\\StrReplace.nsh\\\"
                        !endif
                        !include \\\"${PROJECT_SOURCE_DIR}/res/win\\\\FileAssoc.nsh\\\"
                        !include \\\"${PROJECT_SOURCE_DIR}/res/win\\\\InstallationSize.nsh\\\"
                        !define MUI_WELCOMEFINISHPAGE_BITMAP \\\"${PROJECT_BINARY_DIR}\\\\wininstaller.bmp\\\"
                        !define MUI_HEADERIMAGE
                        !define MUI_HEADERIMAGE_BITMAP \\\"${PROJECT_BINARY_DIR}\\\\wininstallerheader.bmp\\\"")
if(UNRAR_BINARY)
    set(CPACK_NSIS_DEFINES "${CPACK_NSIS_DEFINES}\n!define INCLUDE_UNRAR")
endif(UNRAR_BINARY)
set(CPACK_NSIS_COMPRESSOR "/SOLID lzma")
set(CPACK_NSIS_INSTALLED_ICON_NAME "comicsight.exe")
set(CPACK_NSIS_CONTACT "Pascal Weisenburger <pascal.weisenburger@web.de>")


# DMG
set(CPACK_DMG_VOLUME_NAME "${OSX_INSTALLER_DMG_VOLUME_NAME}")
set(CPACK_DMG_BACKGROUND_IMAGE "${OSX_INSTALLER_DMG_BACKGROUND_IMAGE}")
set(CPACK_DMG_DS_STORE "${OSX_INSTALLER_DMG_DS_STORE}")
set(CPACK_BUNDLE_NAME "ComicSight")
set(CPACK_BUNDLE_PLIST "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Info.plist")
set(CPACK_BUNDLE_ICON "${PROJECT_BINARY_DIR}/ComicSight.app/Contents/Resources/comicsight.icns")


include(CPack)

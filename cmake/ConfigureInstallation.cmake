if(WIN32)
    install(TARGETS comicsight DESTINATION . COMPONENT main)
else(WIN32)
    install(TARGETS comicsight DESTINATION bin COMPONENT main)
endif(WIN32)

install(FILES "${PROJECT_SOURCE_DIR}/res/x11/comicsight.desktop"
        DESTINATION share/applications COMPONENT x11)
install(FILES "${PROJECT_BINARY_DIR}/comicsight16.png"
        DESTINATION share/icons/hicolor/16x16/apps RENAME comicsight.png COMPONENT x11)
install(FILES "${PROJECT_BINARY_DIR}/comicsight22.png"
        DESTINATION share/icons/hicolor/22x22/apps RENAME comicsight.png COMPONENT x11)
install(FILES "${PROJECT_BINARY_DIR}/comicsight24.png"
        DESTINATION share/icons/hicolor/24x24/apps RENAME comicsight.png COMPONENT x11)
install(FILES "${PROJECT_BINARY_DIR}/comicsight32.png"
        DESTINATION share/icons/hicolor/32x32/apps RENAME comicsight.png COMPONENT x11)
install(FILES "${PROJECT_BINARY_DIR}/comicsight48.png"
        DESTINATION share/icons/hicolor/48x48/apps RENAME comicsight.png COMPONENT x11)
install(FILES "${PROJECT_BINARY_DIR}/comicsight64.png"
        DESTINATION share/icons/hicolor/64x64/apps RENAME comicsight.png COMPONENT x11)
install(FILES "${PROJECT_BINARY_DIR}/comicsight96.png"
        DESTINATION share/icons/hicolor/96x96/apps RENAME comicsight.png COMPONENT x11)
install(FILES "${PROJECT_BINARY_DIR}/comicsight.svg"
        DESTINATION share/icons/hicolor/scalable/apps COMPONENT x11)

install(FILES "${PROJECT_SOURCE_DIR}/res/deb/comicsight"
        DESTINATION share/menu COMPONENT deb)

if(UNRAR_BINARY)
    if(WIN32)
        install(PROGRAMS "${UNRAR_BINARY}" DESTINATION . COMPONENT unrar)
    else(WIN32)
        install(PROGRAMS "${UNRAR_BINARY}" DESTINATION bin COMPONENT unrar)
    endif(WIN32)
endif(UNRAR_BINARY)

if(APPLE)
    install(CODE "
        include(BundleUtilities)
        get_dotapp_dir(\"\${CMAKE_INSTALL_PREFIX}\" INST_DIR)
        string(REGEX REPLACE \"/[^/]+\\\\.app$\" \"\" INST_DIR \"\${INST_DIR}\")

        file(COPY \"${PROJECT_BINARY_DIR}/ComicSight.app\"
             DESTINATION \"\${INST_DIR}\")
    " COMPONENT osxinstaller)

    if(UNRAR_BINARY)
        install(CODE "
            include(BundleUtilities)
            get_dotapp_dir(\"\${CMAKE_INSTALL_PREFIX}\" INST_DIR)
            string(REGEX REPLACE \"/[^/]+\\\\.app$\" \"\" INST_DIR \"\${INST_DIR}\")

            file(COPY \"${UNRAR_BINARY}\"
                 DESTINATION \"\${INST_DIR}/ComicSight.app/Contents/MacOS\")
        " COMPONENT osxinstaller)
    endif(UNRAR_BINARY)
endif(APPLE)

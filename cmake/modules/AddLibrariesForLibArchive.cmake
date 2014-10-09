#
# link against additional libraries that are needed for statically
# linking libarchive
#

if(LibArchive_FOUND)
    # check if lib is linked statically
    foreach(LIB ${LibArchive_LIBRARIES})
        string(REGEX REPLACE "\\.([aA]|[lL][iI][bB])" ".dll" LIBDLL "${LIB}")
        if(LIB MATCHES "\\.([aA]|[lL][iI][bB])" AND NOT EXISTS "${LIBDLL}")

            add_definitions(-DLIBARCHIVE_STATIC)

            find_package(ZLIB)
            if(ZLIB_FOUND)
                list(APPEND LibArchive_LIBRARIES "${ZLIB_LIBRARIES}")
            endif(ZLIB_FOUND)

            find_package(BZip2)
            if(BZIP2_FOUND)
                list(APPEND LibArchive_LIBRARIES "${BZIP2_LIBRARIES}")
            endif(BZIP2_FOUND)

            find_package(LZMA)
            if(LZMA_FOUND)
                list(APPEND LibArchive_LIBRARIES "${LZMA_LIBRARIES}")
            endif(LZMA_FOUND)
            if(LZMADEC_FOUND)
                list(APPEND LibArchive_LIBRARIES "${LZMADEC_LIBRARIES}")
            endif(LZMADEC_FOUND)

            if(LZO2_INCLUDE_DIR)
                set(LZO2_FIND_QUIETLY TRUE)
            endif(LZO2_INCLUDE_DIR)
            find_path(LZO2_INCLUDE_DIR lzo/lzoconf.h)
            find_library(LZO2_LIBRARY NAMES lzo2 liblzo2)
            include(FindPackageHandleStandardArgs)
            find_package_handle_standard_args(LZO2 DEFAULT_MSG
                                              LZO2_LIBRARY LZO2_INCLUDE_DIR)
            if(LZO2_FOUND)
                list(APPEND LibArchive_LIBRARIES "${LZO2_LIBRARY}")
            endif(LZO2_FOUND)
            mark_as_advanced(CLEAR LZO2_INCLUDE_DIR)
            mark_as_advanced(CLEAR LZO2_LIBRARY)

            find_package(LibXml2)
            if(LIBXML2_FOUND)
                list(APPEND LibArchive_LIBRARIES "${LIBXML2_LIBRARIES}")
            else(LIBXML2_FOUND)
                find_package(EXPAT)
                if(EXPAT_FOUND)
                    list(APPEND LibArchive_LIBRARIES "${EXPAT_LIBRARIES}")
                endif(EXPAT_FOUND)
            endif(LIBXML2_FOUND)
            
            find_path(ICONV_INCLUDE_DIR NAMES iconv.h)
            mark_as_advanced(ICONV_INCLUDE_DIR)
            find_library(ICONV_LIBRARY NAMES iconv)
            mark_as_advanced(ICONV_LIBRARY)
            if(ICONV_INCLUDE_DIR AND ICONV_LIBRARY)
                list(APPEND LibArchive_LIBRARIES "${ICONV_LIBRARY}")
            endif(ICONV_INCLUDE_DIR AND ICONV_LIBRARY)

            break(LIB)
        endif(LIB MATCHES "\\.([aA]|[lL][iI][bB])" AND NOT EXISTS "${LIBDLL}")
    endforeach(LIB)
endif(LibArchive_FOUND)

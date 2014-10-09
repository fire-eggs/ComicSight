#
# link against additional libraries that may not be set correctly when
# finding the FLTK package
#

if(FLTK_FOUND AND UNIX AND FLTK_CONFIG_SCRIPT)
    # check if lib is linked statically
    foreach(LIB ${FLTK_LIBRARIES})
        if(LIB MATCHES "\\.[aA]")

            exec_program(sh ARGS ${FLTK_CONFIG_SCRIPT} --ldflags
                         OUTPUT_VARIABLE FLTK_LDFLAGS)
            if(FLTK_LDFLAGS MATCHES "-lfltk (.*)")
                string(REGEX REPLACE "-lfltk (.*)" "\\1" FLTK_LIBS "${FLTK_LDFLAGS}")
                string(REGEX REPLACE " +" ";" FLTK_LIBS "${FLTK_LIBS}")
                set(FLTK_LIBRARIES "${FLTK_LIBRARIES};${FLTK_LIBS}")
            endif(FLTK_LDFLAGS MATCHES "-lfltk (.*)")

            break(LIB)
        endif(LIB MATCHES "\\.[aA]")
    endforeach(LIB ${FLTK_LIBRARIES})
endif(FLTK_FOUND AND UNIX AND FLTK_CONFIG_SCRIPT)

if(FLTK_FOUND AND WIN32)
    # check if lib is linked dynamically
    foreach(LIB ${FLTK_LIBRARIES})
        if(LIB MATCHES "\\.([dD][lL][lL])")

            add_definitions(-DFL_DLL)

            break(LIB)
        endif(LIB MATCHES "\\.([dD][lL][lL])")
    endforeach(LIB)
endif(FLTK_FOUND AND WIN32)

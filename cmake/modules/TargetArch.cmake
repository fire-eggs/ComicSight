# Based on TargetArch.cmake by Petroules Corporation, which is released under
# the terms of the BSD license
# https://github.com/petroules/solar-cmake/blob/master/TargetArch.cmake
#
# Based on the Qt 5 processor detection code, so it should be very accurate
# https://qt.gitorious.org/qt/qtbase/blobs/stable/src/corelib/global/qprocessordetection.h
#
# Currently handles arm, avr32, x86, x86_64, ia64, mips, ppc, ppc64, s390, sh
# and sparc as well as endianess and arm hard float
#
# Regarding POWER/PowerPC, just as it is noted in the Qt source,
# "There are many more known variants/revisions that we do not handle/detect."

if(TARGET_ARCH_MODULE_INCLUDED)
    return()
endif(TARGET_ARCH_MODULE_INCLUDED)
set(TARGET_ARCH_MODULE_INCLUDED YES)

set(archdetect_c_code "
#if defined(__arm__) || defined(__TARGET_ARCH_ARM)
#  if defined(__ARM_ARCH_7__) \\
      || defined(__ARM_ARCH_7A__) \\
      || defined(__ARM_ARCH_7R__) \\
      || defined(__ARM_ARCH_7M__) \\
      || defined(__ARM_ARCH_7S__) \\
      || (defined(__TARGET_ARCH_ARM) && __TARGET_ARCH_ARM-0 >= 7) \\
      || (defined(_M_ARM) && _M_ARM-0 >= 7)
#    error cmake_ARCH armv7
#  elif defined(__ARM_ARCH_6__) \\
      || defined(__ARM_ARCH_6J__) \\
      || defined(__ARM_ARCH_6T2__) \\
      || defined(__ARM_ARCH_6Z__) \\
      || defined(__ARM_ARCH_6K__) \\
      || defined(__ARM_ARCH_6ZK__) \\
      || defined(__ARM_ARCH_6M__) \\
      || (defined(__TARGET_ARCH_ARM) && __TARGET_ARCH_ARM-0 >= 6) \\
      || (defined(_M_ARM) && _M_ARM-0 >= 6)
#    error cmake_ARCH armv6
#  elif defined(__ARM_ARCH_5TEJ__) \\
      || defined(__ARM_ARCH_5TE__) \\
      || (defined(__TARGET_ARCH_ARM) && __TARGET_ARCH_ARM-0 >= 5) \\
      || (defined(_M_ARM) && _M_ARM-0 >= 5)
#    error cmake_ARCH armv5
#  else
#    error cmake_ARCH arm
#  endif
#endif

#if defined(__avr32__)
#  error cmake_ARCH avr32
#endif

#if defined(__i386) || defined(__i386__) || defined(_M_IX86)
#  if defined(_M_IX86)
#    if _M_IX86 >= 600
#      error cmake_ARCH i686
#    elif _M_IX86 >= 500
#      error cmake_ARCH i586
#    elif _M_IX86 >= 400
#      error cmake_ARCH i486
#    else
#      error cmake_ARCH i386
#    endif
#  elif defined(__i686__) || defined(__athlon__) || defined(__SSE__)
#    error cmake_ARCH i686
#  elif defined(__i586__) || defined(__k6__)
#    error cmake_ARCH i586
#  elif defined(__i486__)
#    error cmake_ARCH i486
#  else
#    error cmake_ARCH i386
#  endif
#endif

#if defined(__x86_64) || defined(__x86_64__) || defined(__amd64) || defined(_M_X64)
#  error cmake_ARCH x86_64
#endif

#if defined(__ia64) || defined(__ia64__) || defined(_M_IA64)
#  error cmake_ARCH ia64
#endif

#if defined(__mips) || defined(__mips__) || defined(_M_MRX000)
#  error cmake_ARCH mips
#endif

#if defined(__ppc__) || defined(__ppc) || defined(__powerpc__) \\
      || defined(_ARCH_COM) || defined(_ARCH_PWR) || defined(_ARCH_PPC) \\
      || defined(_M_MPPC) || defined(_M_PPC)
#    if defined(__ppc64__) || defined(__powerpc64__) || defined(__64BIT__)
#        error cmake_ARCH ppc64
#    else
#        error cmake_ARCH ppc
#    endif
#endif

#if defined(__s390x__)
#  error cmake_ARCH s390x
#elif defined(__s390__)
#  error cmake_ARCH s390
#endif

#if defined(__sh__)
#  error cmake_ARCH sh
#endif

#if defined(__sparc__)
#  error cmake_ARCH sparc
#endif

#error cmake_ARCH unknown
")

set(endiandetect_c_code "
#if defined(__arm__) || defined(__TARGET_ARCH_ARM)
#  if defined(__ARMEL__)
#    define LITTLE_ENDIAN
#  elif defined(__ARMEB__)
#    define BIG_ENDIAN
#  endif
#endif

#if defined(__mips) || defined(__mips__) || defined(_M_MRX000)
#  if defined(__MIPSEL__)
#    define LITTLE_ENDIAN
#  elif defined(__MIPSEB__)
#    define BIG_ENDIAN
#  endif
#endif

#if !defined(LITTLE_ENDIAN) && !defined(BIG_ENDIAN)
#  if defined(__BYTE_ORDER__) && defined(__ORDER_BIG_ENDIAN__) && (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__)
#    define BIG_ENDIAN
#  elif defined(__BYTE_ORDER__) && defined(__ORDER_LITTLE_ENDIAN__) && (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#    define LITTLE_ENDIAN
#  elif defined(__BIG_ENDIAN__) || defined(_big_endian__) || defined(_BIG_ENDIAN)
#    define BIG_ENDIAN
#  elif defined(__LITTLE_ENDIAN__) || defined(_little_endian__) || defined(_LITTLE_ENDIAN)
#    define LITTLE_ENDIAN
#  endif
#endif

#if defined(LITTLE_ENDIAN)
#  error cmake_ARCH el
#elif defined(BIG_ENDIAN)
#  error cmake_ARCH eb
#endif

#error cmake_ARCH unknown
")

set(armhfdetect_c_code "
#if (defined(__arm__) || defined(__TARGET_ARCH_ARM)) \\
      && defined(__VFP_FP__) && !defined(__SOFTFP__)
#    error cmake_ARCH hf
#endif

#error cmake_ARCH unknown
")

function(target_architecture Arch Endian)
    enable_language(C)

    if(APPLE AND CMAKE_OSX_ARCHITECTURES)
        # On OS X we use CMAKE_OSX_ARCHITECTURES *if* it was set
        # First let's normalize the order of the values

        # Note that it's not possible to compile PowerPC applications
        # if you are using the OS X SDK version 10.6 or later,
        # you'll need 10.4/10.5 for that, so we disable it by default.
        # See this page for more information:
        # http://stackoverflow.com/questions/5333490/how-can-we-restore-ppc-ppc64-as-well-as-full-10-4-10-5-sdk-support-to-xcode-4

        # Architecture defaults to i386 or ppc on OS X 10.5 and earlier,
        # depending on the CPU type detected at runtime. On OS X 10.6+
        # the default is x86_64 if the CPU supports it, i386 otherwise.

        foreach(osx_arch ${CMAKE_OSX_ARCHITECTURES})
            if("${osx_arch}" STREQUAL "ppc")
                set(osx_arch_ppc TRUE)
            elseif("${osx_arch}" STREQUAL "i386")
                set(osx_arch_i386 TRUE)
            elseif("${osx_arch}" STREQUAL "x86_64")
                set(osx_arch_x86_64 TRUE)
            elseif("${osx_arch}" STREQUAL "ppc64")
                set(osx_arch_ppc64 TRUE)
            else()
                message(FATAL_ERROR "Invalid OS X arch name: ${osx_arch}")
            endif()
        endforeach(osx_arch ${CMAKE_OSX_ARCHITECTURES})

        # Now add all the architectures in our normalized order
        if(osx_arch_ppc)
            list(APPEND ARCH ppc)
        endif(osx_arch_ppc)

        if(osx_arch_i386)
            list(APPEND ARCH i386)
        endif(osx_arch_i386)

        if(osx_arch_x86_64)
            list(APPEND ARCH x86_64)
        endif(osx_arch_x86_64)

        if(osx_arch_ppc64)
            list(APPEND ARCH ppc64)
        endif(osx_arch_ppc64)
    else(APPLE AND CMAKE_OSX_ARCHITECTURES)
        # Detect the architecture in a rather creative way...
        # This compiles a small C program which is a series of ifdefs that selects a
        # particular #error preprocessor directive whose message string contains the
        # target architecture. The program will always fail to compile (both because
        # file is not a valid C program, and obviously because of the presence of the
        # #error preprocessor directives... but by exploiting the preprocessor in this
        # way, we can detect the correct target architecture even when cross-compiling,
        # since the program itself never needs to be run (only the compiler/preprocessor)

        file(WRITE "${CMAKE_BINARY_DIR}/CMakeFiles/CMakeTmp/arch.c" "${archdetect_c_code}")
        try_compile(RESULT_VAR
                    "${CMAKE_BINARY_DIR}"
                    "${CMAKE_BINARY_DIR}/CMakeFiles/CMakeTmp/arch.c"
                    CMAKE_FLAGS CMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
                    OUTPUT_VARIABLE ARCH)

        # Parse the architecture name from the compiler output
        string(REGEX MATCH "cmake_ARCH [a-zA-Z0-9_]+" ARCH "${ARCH}")

        # Get rid of the value marker leaving just the architecture name
        string(REPLACE "cmake_ARCH " "" ARCH "${ARCH}")

        # If we are compiling with an unknown architecture this variable should
        # already be set to "unknown" but in the case that it's empty (i.e. due
        # to a typo in the code), then set it to unknown
        if(NOT ARCH)
            set(ARCH unknown)
        endif(NOT ARCH)

        # Detect arm hard float support using the same method used to detect the architecture
        if(ARCH MATCHES "arm.*")
            file(WRITE "${CMAKE_BINARY_DIR}/CMakeFiles/CMakeTmp/armhf.c" "${armhfdetect_c_code}")
            try_compile(RESULT_VAR
                        "${CMAKE_BINARY_DIR}"
                        "${CMAKE_BINARY_DIR}/CMakeFiles/CMakeTmp/armhf.c"
                        OUTPUT_VARIABLE ARMHF)

            # Parse the hard float information from the compiler output
            string(REGEX MATCH "cmake_ARCH [a-zA-Z0-9_]+" ARMHF "${ARMHF}")

            # Get rid of the value marker leaving just the hard float information
            string(REPLACE "cmake_ARCH " "" ARMHF "${ARMHF}")

            if(ARMHF MATCHES "hf")
                set(ARCH "${ARCH}hf")
            endif(ARMHF MATCHES "hf")
        endif(ARCH MATCHES "arm.*")
    endif(APPLE AND CMAKE_OSX_ARCHITECTURES)

    set(${Arch} "${ARCH}" PARENT_SCOPE)

    # x86 and x86_64 are always little-endian
    if(ARCH MATCHES "i.86|x86_64")
        set(ENDIAN "el")
    endif(ARCH MATCHES "i.86|x86_64")

    # avr32 and s390 are always big-endian
    if(ARCH MATCHES "avr32|s390")
        set(ENDIAN "eb")
    endif(ARCH MATCHES "avr32|s390")

    if(NOT ENDIAN)
        # Detect endianess (el, eb) using the same method used to detect the architecture
        file(WRITE "${CMAKE_BINARY_DIR}/CMakeFiles/CMakeTmp/endian.c" "${endiandetect_c_code}")
        try_compile(RESULT_VAR
                    "${CMAKE_BINARY_DIR}"
                    "${CMAKE_BINARY_DIR}/CMakeFiles/CMakeTmp/endian.c"
                    OUTPUT_VARIABLE ENDIAN)

        # Parse the endianess from the compiler output
        string(REGEX MATCH "cmake_ARCH [a-zA-Z0-9_]+" ENDIAN "${ENDIAN}")

        # Get rid of the value marker leaving just the endianess
        string(REPLACE "cmake_ARCH " "" ENDIAN "${ENDIAN}")

        if(NOT ENDIAN)
            set(ENDIAN unknown)
        endif(NOT ENDIAN)
    endif(NOT ENDIAN)

    set(${Endian} "${ENDIAN}" PARENT_SCOPE)

endfunction(target_architecture Arch Endian)

if(MINGW)
    # if using MinGW, link C/C++ runtime statically
    # (reduce external dependencies on Windows)
    option(STATIC_BUILD "link statically against runtime libraries" ON)
else(MINGW)
    # for other compilers/platforms link dynamically
    # for MSVC static linking also requires all used static libraries to be
    # statically linked against the C/C++ runtime
    option(STATIC_BUILD "link statically against runtime libraries" OFF)
endif(MINGW)

option(OPTIMIZATION_FLAGS "append additional compiler optimization flags to release build" ON)

# GCC flags (C++11 usage and optimization flags)
if(CMAKE_COMPILER_IS_GNUCXX)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++11 -fno-rtti -fno-exceptions")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wall")
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wall")

    if(OPTIMIZATION_FLAGS)
        if(SYSTEM_ARCHITECTURE MATCHES "i.86|x86_64")
            set(CMAKE_C_FLAGS_RELEASE
                "${CMAKE_C_FLAGS_RELEASE} -msse -msse2 -msse3 -mfpmath=sse")
        endif(SYSTEM_ARCHITECTURE MATCHES "i.86|x86_64")
        set(CMAKE_C_FLAGS_RELEASE
            "${CMAKE_C_FLAGS_RELEASE} -Ofast -ffast-math")
        set(CMAKE_C_FLAGS_RELEASE
            "${CMAKE_C_FLAGS_RELEASE} -floop-optimize -funsafe-loop-optimizations")
        set(CMAKE_C_FLAGS_RELEASE
            "${CMAKE_C_FLAGS_RELEASE} -ffunction-sections -fdata-sections -flto")

        if(SYSTEM_ARCHITECTURE MATCHES "i.86|x86_64")
            set(CMAKE_CXX_FLAGS_RELEASE
                "${CMAKE_CXX_FLAGS_RELEASE} -msse -msse2 -msse3 -mfpmath=sse")
        endif(SYSTEM_ARCHITECTURE MATCHES "i.86|x86_64")
        set(CMAKE_CXX_FLAGS_RELEASE
            "${CMAKE_CXX_FLAGS_RELEASE} -Ofast -ffast-math")
        set(CMAKE_CXX_FLAGS_RELEASE
            "${CMAKE_CXX_FLAGS_RELEASE} -floop-optimize -funsafe-loop-optimizations")
        set(CMAKE_CXX_FLAGS_RELEASE
            "${CMAKE_CXX_FLAGS_RELEASE} -ffunction-sections -fdata-sections -flto")

        set(CMAKE_EXE_LINKER_FLAGS
            "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections -Wl,--as-needed -s")
    endif(OPTIMIZATION_FLAGS)

    if(STATIC_BUILD)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -static-libgcc -static")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libgcc -static-libstdc++ -static")
    endif(STATIC_BUILD)
endif(CMAKE_COMPILER_IS_GNUCXX)

# Clang flags (C++11 usage and optimization flags)
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++11 -fno-rtti -fno-exceptions")
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wall")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wall")

    if(OPTIMIZATION_FLAGS)
        set(CMAKE_C_FLAGS_RELEASE
            "${CMAKE_C_FLAGS_RELEASE} -Ofast -msse -msse2 -msse3 -ffast-math")
        set(CMAKE_C_FLAGS_RELEASE
            "${CMAKE_C_FLAGS_RELEASE} -ffunction-sections -fdata-sections")

        set(CMAKE_CXX_FLAGS_RELEASE
            "${CMAKE_CXX_FLAGS_RELEASE} -Ofast -msse -msse2 -msse3 -ffast-math")
        set(CMAKE_CXX_FLAGS_RELEASE
            "${CMAKE_CXX_FLAGS_RELEASE} -ffunction-sections -fdata-sections")

        if(NOT APPLE)
            set(CMAKE_EXE_LINKER_FLAGS
                "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections -Wl,--as-needed -s")
        else(NOT APPLE)
            # "-Wl,-dead_strip" leads to "atom not found in symbolIndex" during linking
            set(CMAKE_C_FLAGS_RELEASE
                "${CMAKE_C_FLAGS_RELEASE} -flto")
            set(CMAKE_CXX_FLAGS_RELEASE
                "${CMAKE_CXX_FLAGS_RELEASE} -flto")
        endif(NOT APPLE)
    endif(OPTIMIZATION_FLAGS)

    if(APPLE)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
    endif(APPLE)

    if(STATIC_BUILD)
        message(WARNING "Warning: statically linking against the C runtime not supported with Clang")
    endif(STATIC_BUILD)
endif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")

# MinGW flags
if(MINGW)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -include cmath")

    # MinGW is likely to produce erroneous 64-bit executables
    # when using link time optimization
    # this may be related to: http://gcc.gnu.org/bugzilla/show_bug.cgi?id=58042
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -fno-lto")
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -fno-lto")
    endif(CMAKE_SIZEOF_VOID_P EQUAL 8)

    # MinGW is likely to produce erroneous 32-bit executables
    # when using SSE instructions
    # as described at: http://www.peterstock.co.uk/games/mingw_sse/
    if(CMAKE_SIZEOF_VOID_P EQUAL 4)
        foreach(FLAG
                CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
                CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
                CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
                CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
            if(${${FLAG}} MATCHES "sse")
            string(REGEX REPLACE "/GR" "/GR-" ${FLAG} "${${FLAG}}")
                set(${FLAG} "${${FLAG}} -mstackrealign")
            endif(${${FLAG}} MATCHES "sse")
        endforeach(FLAG)
    endif(CMAKE_SIZEOF_VOID_P EQUAL 4)
endif(MINGW)

# MSVC flags
# (no min/max macros, so std::min/std::max can be used,
# make dirent.h available and optimization flags)
if(MSVC)
    foreach(FLAG
            CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
        string(REGEX REPLACE "/GR" "/GR-" ${FLAG} "${${FLAG}}")
    endforeach(FLAG)
    set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} /GR-")

    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SAFESEH:NO")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /SAFESEH:NO")
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /SAFESEH:NO")

    if(OPTIMIZATION_FLAGS)
        set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /Ox /GL")
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Ox /GL")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /D NOMINMAX")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /D NOMINMAX")

        set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /LTCG")
        set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /LTCG")
        set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} /LTCG")
    endif(OPTIMIZATION_FLAGS)

    if(STATIC_BUILD)
        foreach(FLAG
                CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
                CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
            string(REGEX REPLACE "/MD" "/MT" ${FLAG} "${${FLAG}}")
        endforeach(FLAG)
    endif(STATIC_BUILD)
endif(MSVC)

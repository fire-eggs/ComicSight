#
# Version information from Git tags, changelog files, directory names
# and current date
#

if(VERSION_INFERENCE_MODULE_INCLUDED)
    return()
endif(VERSION_INFERENCE_MODULE_INCLUDED)
set(VERSION_INFERENCE_MODULE_INCLUDED YES)

set(DEFAULT_VERSION_REGEX
    "((([vV]([eE]([rR]([sS]([iI]([oO][nN]?)?)?)?)?)?)[ ]*[0-9]+|[0-9]+\\.)([0-9a-zA-Z.:_~+-]*[0-9a-zA-Z])?)")
set(DEFAULT_GENERAL_VERSION_REGEX
    "[0-9]([0-9a-zA-Z.:_~+-]*[0-9a-zA-Z])?")

#
# Tries to retrieve the current date formatted as YYYYMMDD
#
function(get_current_yyyymmdd Date)
    set(DATE)

    if(CMAKE_HOST_WIN32)
        execute_process(COMMAND wmic os get LocalDateTime
                        OUTPUT_VARIABLE DATE
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
        string(REGEX REPLACE "[^0-9]+" "" DATE "${DATE}")
        string(SUBSTRING ${DATE} 0 8 DATE)
    endif(CMAKE_HOST_WIN32)

    if(CMAKE_HOST_UNIX)
        execute_process(COMMAND date +%Y%m%d
                        OUTPUT_VARIABLE DATE
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
    endif(CMAKE_HOST_UNIX)

    if(NOT DATE)
        set(${Date} "unknown" PARENT_SCOPE)
    else(NOT DATE)
        set(${Date} "${DATE}" PARENT_SCOPE)
    endif(NOT DATE)
endfunction(get_current_yyyymmdd Date)

#
# Takes the first regular expression that matches a string
# and optionally replaces it with the given replacement string
#
function(take_first_matching)
    list(GET ARGN 0 OUTPUT)
    list(GET ARGN 1 INPUT)

    set(INPUT_MATCH)
    set(INDEX 2)
    while(INDEX LESS ARGC)
        list(GET ARGN "${INDEX}" REGEX)
        math(EXPR INDEX "${INDEX} + 1")
        if(INDEX LESS ARGC)
            list(GET ARGN "${INDEX}" REPLACE)
            math(EXPR INDEX "${INDEX} + 1")
        else(INDEX LESS ARGC)
            set(REPLACE)
        endif(INDEX LESS ARGC)

        string(REGEX MATCH "${REGEX}" INPUT_MATCH "${INPUT}")
        if(INPUT_MATCH)
            if(REPLACE)
                string(REGEX REPLACE "${REGEX}" "${REPLACE}" INPUT_MATCH "${INPUT_MATCH}")
            endif(REPLACE)
            break(INDEX)
        endif(INPUT_MATCH)
    endwhile(INDEX LESS ARGC)

    set(${OUTPUT} "${INPUT_MATCH}" PARENT_SCOPE)
endfunction(take_first_matching)

#
# Tries to extract a sensible current version string from a Git repository
#
function(version_from_git Version)
    set(REGEX_LIST ${ARGN})
    if(NOT REGEX_LIST)
        set(REGEX_LIST
            ${DEFAULT_VERSION_REGEX} "\\0"
            ${DEFAULT_GENERAL_VERSION_REGEX} "\\0")
    endif(NOT REGEX_LIST)

    if(NOT GIT_FOUND)
        find_package(Git QUIET)
    endif(NOT GIT_FOUND)

    if(PROJECT_SOURCE_DIR)
        set(SOURCE_DIRECTORY "${PROJECT_SOURCE_DIR}")
    else(PROJECT_SOURCE_DIR)
        set(SOURCE_DIRECTORY "${CMAKE_SOURCE_DIR}")
    endif(PROJECT_SOURCE_DIR)

    if(EXISTS "${SOURCE_DIRECTORY}/.git" AND NOT GIT_FOUND)
        message(WARNING "Warning: Found .git directory but Git executable is "
                        "not available to infer version information from Git tags.")
    endif(EXISTS "${SOURCE_DIRECTORY}/.git" AND NOT GIT_FOUND)

    if(GIT_FOUND)
        execute_process(COMMAND "${GIT_EXECUTABLE}"
            describe --tags --dirty=-modified
            WORKING_DIRECTORY "${SOURCE_DIRECTORY}"
            RESULT_VARIABLE PROCESS_RESULT
            OUTPUT_VARIABLE VERSION
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(NOT PROCESS_RESULT EQUAL 0)
            set(VERSION)
        endif(NOT PROCESS_RESULT EQUAL 0)
    endif(GIT_FOUND)

    if(VERSION)
        # parse modified information
        if(VERSION MATCHES "-modified$")
            string(REGEX REPLACE "(.*)-modified$" "\\1" VERSION "${VERSION}")
            set(VERSION_MODIFIED "-modified")
        else(VERSION MATCHES "-modified$")
            set(VERSION_MODIFIED)
        endif(VERSION MATCHES "-modified$")

        # parse commit identification
        if(VERSION MATCHES ".+-[0-9]+-g[0-9a-zA-Z]*$")
            string(REGEX REPLACE "^.+(-[0-9]+-g[0-9a-zA-Z]*)$" "\\1${VERSION_MODIFIED}" VERSION_MODIFIED "${VERSION}")
            string(REGEX REPLACE "^(.+)-[0-9]+-g[0-9a-zA-Z]*$" "\\1" VERSION "${VERSION}")
        endif(VERSION MATCHES ".+-[0-9]+-g[0-9a-zA-Z]*$")

        # parse version information
        # (make sure version always starts with a digit)
        string(REPLACE ";" "\;" VERSION "${VERSION}")
        take_first_matching(VERSION "${VERSION}" ${REGEX_LIST})
        string(REGEX REPLACE "^[^0-9]" "" VERSION "${VERSION}")
    endif(VERSION)

    if(VERSION AND VERSION_MODIFIED)
        set(VERSION "${VERSION}-post")

        execute_process(COMMAND "${GIT_EXECUTABLE}"
            log -1 --format=%ai
            WORKING_DIRECTORY "${SOURCE_DIRECTORY}"
            RESULT_VARIABLE PROCESS_RESULT
            OUTPUT_VARIABLE DATE
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE)

        if(DATE AND PROCESS_RESULT EQUAL 0)
            string(REGEX REPLACE "([0-9]+)-([0-9]+)-([0-9]+).*" "\\1\\2\\3" DATE "${DATE}")
        else(DATE AND PROCESS_RESULT EQUAL 0)
            set(DATE)
        endif(DATE AND PROCESS_RESULT EQUAL 0)

        set(VERSION_MODIFIED "+git${DATE}${VERSION_MODIFIED}")
    endif(VERSION AND VERSION_MODIFIED)

    if(VERSION)
        set(${Version} "${VERSION}${VERSION_MODIFIED}" PARENT_SCOPE)
    else(VERSION)
        set(${Version} "NOTFOUND" PARENT_SCOPE)
    endif(VERSION)
endfunction(version_from_git Version)

#
# Tries to extract a sensible current version string from a given changelog
#
function(version_from_changelog Version File)
    set(REGEX_LIST ${ARGN})
    if(NOT REGEX_LIST)
        set(REGEX_LIST ${DEFAULT_VERSION_REGEX})
    endif(NOT REGEX_LIST)

    # read the changelog and try to match version
    # (make sure version always starts with a digit)
    file(READ "${File}" CHANGELOG)
    string(REPLACE ";" "\;" CHANGELOG "${CHANGELOG}")
    take_first_matching(VERSION "${CHANGELOG}" ${REGEX_LIST})
    string(REGEX REPLACE "^[^0-9]" "" VERSION "${VERSION}")

    if(VERSION)
        get_current_yyyymmdd(DATE)
        set(${Version} "${VERSION}+${DATE}-modified" PARENT_SCOPE)
    else(VERSION)
        set(${Version} "NOTFOUND" PARENT_SCOPE)
    endif(VERSION)
endfunction(version_from_changelog Version File)

#
# Tries to extract a sensible current version string from a directory name
#
function(version_from_directory Version Directory)
    set(Project_Name)

    set(REGEX_LIST ${ARGN})
    if(ARGC GREATER 2)
        list(GET ARGN 0 Project_Name)
        list(REMOVE_AT REGEX_LIST 0)
    endif(ARGC GREATER 2)

    if(NOT REGEX_LIST)
        set(REGEX_LIST
            ${DEFAULT_VERSION_REGEX} "\\0"
            ${DEFAULT_GENERAL_VERSION_REGEX} "\\0")
    endif(NOT REGEX_LIST)

    # get directory name component
    string(REGEX REPLACE "[\\/]+$" "" DIRECTORY_NAME "${Directory}")
    get_filename_component(DIRECTORY_NAME "${DIRECTORY_NAME}" NAME)

    # remove project prefix
    if(Project_Name)
        string(TOLOWER "${Project_Name}" PROJECT_NAME_LOWERCASE)
        string(TOLOWER "${DIRECTORY_NAME}" DIRECTORY_NAME_LOWERCASE)

        string(FIND "${DIRECTORY_NAME_LOWERCASE}" "${PROJECT_NAME_LOWERCASE}" PROJECT_NAME_INDEX)
        string(LENGTH "${PROJECT_NAME_LOWERCASE}" PROJECT_NAME_LENGTH)

        if(NOT PROJECT_NAME_INDEX EQUAL -1)
            math(EXPR PROJECT_NAME_INDEX "${PROJECT_NAME_INDEX} + ${PROJECT_NAME_LENGTH}")
            string(SUBSTRING "${DIRECTORY_NAME}" "${PROJECT_NAME_INDEX}" -1 DIRECTORY_NAME)
        endif(NOT PROJECT_NAME_INDEX EQUAL -1)
    endif(Project_Name)

    # try to match version
    # (make sure version always starts with a digit)
    string(REPLACE ";" "\;" DIRECTORY_NAME "${DIRECTORY_NAME}")
    take_first_matching(VERSION "${DIRECTORY_NAME}" ${REGEX_LIST})
    string(REGEX REPLACE "^[^0-9]" "" VERSION "${VERSION}")

    if(VERSION)
        get_current_yyyymmdd(DATE)
        set(${Version} "${VERSION}+${DATE}-modified" PARENT_SCOPE)
    else(VERSION)
        set(${Version} "NOTFOUND" PARENT_SCOPE)
    endif(VERSION)
endfunction(version_from_directory Version File)

#
# Tries to extract a sensible current version string from a the current date
#
function(version_from_date Version)
    get_current_yyyymmdd(DATE)
    set(${Version} "0.0.0.0+${DATE}-untagged-modified" PARENT_SCOPE)
endfunction(version_from_date Version)

# - Find Inkscape program
#
#   Inkscape_EXECUTABLE - Path to the Inkscape executable
#   Inkscape_FOUND      - True if Inkscape executable found

include(FindPackageHandleStandardArgs)

find_program(Inkscape_EXECUTABLE NAMES inkscape)
find_package_handle_standard_args(Inkscape DEFAULT_MSG Inkscape_EXECUTABLE)

string(REGEX REPLACE "Contents/MacOS/Inkscape$" "Contents/Resources/bin/inkscape"
                     Inkscape_EXECUTABLE_MAC_OS_X_COMMAND_LINE "${Inkscape_EXECUTABLE}")
if(EXISTS "${Inkscape_EXECUTABLE_MAC_OS_X_COMMAND_LINE}")
    set(Inkscape_EXECUTABLE "${Inkscape_EXECUTABLE_MAC_OS_X_COMMAND_LINE}")
endif(EXISTS "${Inkscape_EXECUTABLE_MAC_OS_X_COMMAND_LINE}")

string(REGEX REPLACE "inkscape\\.exe$" "inkscape.com"
                     Inkscape_EXECUTABLE_WIN_COMMAND_LINE "${Inkscape_EXECUTABLE}")
if(EXISTS "${Inkscape_EXECUTABLE_WIN_COMMAND_LINE}")
    set(Inkscape_EXECUTABLE "${Inkscape_EXECUTABLE_WIN_COMMAND_LINE}")
endif(EXISTS "${Inkscape_EXECUTABLE_WIN_COMMAND_LINE}")

mark_as_advanced(Inkscape_EXECUTABLE)

set(Inkscape_FOUND ${INKSCAPE_FOUND})

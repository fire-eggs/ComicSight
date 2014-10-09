# - Find PNGOUT program
#
#   PNGOUT_EXECUTABLE - Path to the PNGOUT executable
#   PNGOUT_FOUND      - True if PNGOUT executable found

include(FindPackageHandleStandardArgs)

find_program(PNGOUT_EXECUTABLE NAMES pngout)
find_package_handle_standard_args(PNGOUT DEFAULT_MSG PNGOUT_EXECUTABLE)

mark_as_advanced(PNGOUT_EXECUTABLE)

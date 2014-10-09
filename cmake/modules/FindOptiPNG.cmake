# - Find OptiPNG program
#
#   OptiPNG_EXECUTABLE - Path to the OptiPNG executable
#   OptiPNG_FOUND      - True if OptiPNG executable found

include(FindPackageHandleStandardArgs)

find_program(OptiPNG_EXECUTABLE NAMES optipng)
find_package_handle_standard_args(OptiPNG DEFAULT_MSG OptiPNG_EXECUTABLE)

mark_as_advanced(OptiPNG_EXECUTABLE)

set(OptiPNG_FOUND ${OPTIPNG_FOUND})

# - Find pngquant program
#
#   pngquant_EXECUTABLE - Path to the pngquant executable
#   pngquant_FOUND      - True if pngquant executable found

include(FindPackageHandleStandardArgs)

find_program(pngquant_EXECUTABLE NAMES pngquant)
find_package_handle_standard_args(pngquant DEFAULT_MSG pngquant_EXECUTABLE)

mark_as_advanced(pngquant_EXECUTABLE)

set(pngquant_FOUND ${PNGQUANT_FOUND})

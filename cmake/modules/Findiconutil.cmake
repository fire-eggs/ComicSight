# - Find iconutil program
#
#   iconutil_EXECUTABLE - Path to the iconutil executable
#   iconutil_FOUND      - True if iconutil executable found

include(FindPackageHandleStandardArgs)

find_program(iconutil_EXECUTABLE NAMES iconutil)
find_package_handle_standard_args(iconutil DEFAULT_MSG iconutil_EXECUTABLE)

mark_as_advanced(iconutil_EXECUTABLE)

set(iconutil_FOUND ${ICONUTIL_FOUND})

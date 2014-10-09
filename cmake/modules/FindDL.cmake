# - Find dl
# Find the native dl library includes and library
#
#  DL_INCLUDE_DIR - where to find dlfcn.h, etc.
#  DL_LIBRARIES   - List of libraries when using dl library.
#  DL_FOUND       - True if dl library found.


if(DL_INCLUDE_DIR)
  # Already in cache, be silent
  set(DL_FIND_QUIETLY TRUE)
endif(DL_INCLUDE_DIR)

find_path(DL_INCLUDE_DIR dlfcn.h)

set(DL_NAMES dl libdl ltdl libltdl)
find_library(DL_LIBRARY NAMES ${DL_NAMES})

# handle the QUIETLY and REQUIRED arguments and set DL_FOUND to TRUE if
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(DL DEFAULT_MSG DL_LIBRARY DL_INCLUDE_DIR)

if(DL_FOUND)
  set(DL_LIBRARIES ${DL_LIBRARY})
else(DL_FOUND)
  set(DL_LIBRARIES)
endif(DL_FOUND)

mark_as_advanced(DL_LIBRARY DL_INCLUDE_DIR)

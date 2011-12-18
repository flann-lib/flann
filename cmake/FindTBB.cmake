###############################################################################
# Find Intel Threading Building Blocks
#
# This sets the following variables:
#
# TBB_INCLUDE_DIRS - Directories containing the TBB include files.
# TBB_LIBRARY_DIRS - Directories containing the TBB libs.
#
# (release libs)
# TBB_FOUND - True if TBB was found.
# TBB_LIBRARIES - Libraries needed to use TBB.
#
# (debug libs)
# TBB_DEBUG_FOUND - True if TBB was found.
# TBB_DEBUG_LIBRARIES - Libraries needed to use TBB.

find_package(PkgConfig)
pkg_check_modules(PC_TBB tbb)

# Find include directory
find_path(TBB_INCLUDE_DIR tbb/task_scheduler_init.h 
    HINTS ${PC_TBB_INCLUDEDIR} ${PC_TBB_INCLUDE_DIRS})

# Find libraries
find_library(TBB_LIBRARY tbb
    HINTS ${PC_TBB_LIBDIR} ${PC_TBB_LIBRARY_DIRS})

find_library(TBB_DEBUG_LIBRARY tbb_debug
    HINTS ${PC_TBB_LIBDIR} ${PC_TBB_LIBRARY_DIRS})

#find_library(TBB_MALLOC_LIBRARY tbbmalloc
#    HINTS ${PC_TBB_LIBDIR} ${PC_TBB_LIBRARY_DIRS})

#find_library(TBB_MALLOC_LIBRARY tbbmalloc_debug
#    HINTS ${PC_TBB_LIBDIR} ${PC_TBB_LIBRARY_DIRS})

#find_library(TBB_MALLOC_PROXY_LIBRARY tbbmalloc_proxy
#    HINTS ${PC_TBB_LIBDIR} ${PC_TBB_LIBRARY_DIRS})

#find_library(TBB_MALLOC_PROXY_LIBRARY tbbmalloc_proxy_debug
#    HINTS ${PC_TBB_LIBDIR} ${PC_TBB_LIBRARY_DIRS})

# Set the appropriate CMake variables and mark them as advanced
set(TBB_INCLUDE_DIRS ${TBB_INCLUDE_DIR})
set(TBB_LIBRARY_DIRS ${PC_TBB_LIBRARY_DIRS})
#set(TBB_LIBRARIES ${TBB_LIBRARY};${TBB_MALLOC_LIBRARY};${TBB_MALLOC_PROXY_LIBRARY})
set(TBB_LIBRARIES ${TBB_LIBRARY})
#set(TBB_DEBUG_LIBRARIES ${TBB_DEBUG_LIBRARY};${TBB_MALLOC_DEBUG_LIBRARY};${TBB_MALLOC_PROXY_DEBUG_LIBRARY})
set(TBB_DEBUG_LIBRARIES ${TBB_DEBUG_LIBRARY})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(tbb DEFAULT_MSG TBB_LIBRARIES TBB_INCLUDE_DIRS)
find_package_handle_standard_args(tbb_debug DEFAULT_MSG TBB_DEBUG_LIBRARIES TBB_INCLUDE_DIRS)

mark_as_advanced(TBB_LIBRARY TBB_DEBUG_LIBRARY TBB_INCLUDE_DIR)
#mark_as_advanced(TBB_LIBRARY TBB_DEBUG_LIBRARY TBB_MALLOC_LIBRARY TBB_DEBUG_MALLOC_LIBRARY TBB_MALLOC_PROXY_LIBRARY TBB_MALLOC_PROXY_DEBUG_LIBRARY TBB_INCLUDE_DIR)


# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find AlembicUtilities
#
# Imported targets
# ----------------
# This module defines the following imported targets:
#
# ``AlembicUtilities::AlembicUtilities``
#   The AlembicUtilities library, if found
#
# Result variables
# ----------------
# ``AlembicUtilities_INCLUDE_DIRS``
#   where to find MmSequence.h etc...
# ``AlembicUtilities_LIBRARIES``
#   the libraries to link against to use AlembicUtilities
#
find_path(AlembicUtilities_INCLUDE_DIR
  NAMES MmSequence.h
  PATH_SUFFIXES dw_abc 
  HINTS $ENV{REZ_ALEMBIC_UTILITIES_ROOT}/include /usr/local/include)

# need to find #include <dw_abc/MmSequence.h>
set(AlembicUtilities_INCLUDE_DIRS ${AlembicUtilities_INCLUDE_DIR}/..)

find_library(AlembicUtilities_LIBRARIES
  NAMES alembic_utilities
  HINTS $ENV{REZ_ALEMBIC_UTILITIES_ROOT}/lib /usr/local/lib)
mark_as_advanced(AlembicUtilities_INCLUDE_DIR AlembicUtilities_INCLUDE_DIRS AlembicUtilities_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(AlembicUtilities
  REQUIRED_VARS AlembicUtilities_LIBRARIES AlembicUtilities_INCLUDE_DIRS
)

if (AlembicUtilities_FOUND AND NOT TARGET AlembicUtilities::AlembicUtilities)
    add_library(AlembicUtilities::AlembicUtilities UNKNOWN IMPORTED)
    set_target_properties(AlembicUtilities::AlembicUtilities PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${AlembicUtilities_LIBRARIES}"
      INTERFACE_INCLUDE_DIRECTORIES "${AlembicUtilities_INCLUDE_DIRS}")
endif()


# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find Amorphous
#
# Imported targets
# ----------------
# This module defines the following imported targets:
#
# ``Amorphous::Amorphous``
#   The Amorphous library, if found
#
# Result variables
# ----------------
# ``Amorphous_INCLUDE_DIRS``
#   where to find ColorGrad.h etc...
# ``Amorphous_LIBRARIES``
#   the libraries to link against to use Amorphous
#
find_path(Amorphous_INCLUDE_DIR
  NAMES ColorGrad.h
  PATH_SUFFIXES amorphous_core
  HINTS $ENV{AMORPHOUS_ROOT}/include /usr/local/include)

# need to find <openvdb/openvdb.h>
set(Amorphous_INCLUDE_DIRS ${Amorphous_INCLUDE_DIR}/..)

find_library(Amorphous_LIBRARIES
  NAMES amorphous_core
  HINTS $ENV{AMORPHOUS_ROOT}/lib /usr/local/lib)
mark_as_advanced(Amorphous_INCLUDE_DIR Amorphous_INCLUDE_DIRS Amorphous_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Amorphous
  REQUIRED_VARS Amorphous_LIBRARIES Amorphous_INCLUDE_DIRS
)

if (Amorphous_FOUND AND NOT TARGET Amorphous::Amorphous)
    add_library(Amorphous::Amorphous UNKNOWN IMPORTED)
    set_target_properties(Amorphous::Amorphous PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${Amorphous_LIBRARIES}"
      INTERFACE_INCLUDE_DIRECTORIES "${Amorphous_INCLUDE_DIRS}")
endif()


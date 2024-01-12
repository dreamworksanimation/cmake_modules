# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find Random123, a header only library
#
# Imported targets
# ----------------
# This module defines the following imported targets:
#
# ``Random123::Random123``
#   The Random123 library, if found
#
# Result variables
# ----------------
# ``Random123_INCLUDE_DIRS``
#   where to find headers for Random123
#
find_path(Random123_INCLUDE_DIR
  NAMES threefry.h
  PATH_SUFFIXES Random123
  HINTS $ENV{RANDOM123_ROOT}/include /usr/local/include)

# need to find <Random123/threefry.h>
set(Random123_INCLUDE_DIRS ${Random123_INCLUDE_DIR}/..)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Random123
  REQUIRED_VARS Random123_INCLUDE_DIRS
)

if (Random123_FOUND AND NOT TARGET Random123::Random123)
    add_library(Random123::Random123 INTERFACE IMPORTED)
    set_target_properties(Random123::Random123 PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      INTERFACE_INCLUDE_DIRECTORIES "${Random123_INCLUDE_DIRS}")
endif()


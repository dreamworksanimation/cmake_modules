# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find OptiX headers
#
# Imported targets
# ----------------
# This module defines the following imported targets:
#
# ``OptiX::OptiX``
#   The OptiX library, if found
#
# Result variables
# ----------------
# ``OptiX_INCLUDE_DIRS``
#   where to find headers for OptiX
#
find_path(OptiX_INCLUDE_DIRS
  NAMES optix.h
  HINTS $ENV{OPTIX_ROOT}/include /usr/local/include)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OptiX
  REQUIRED_VARS OptiX_INCLUDE_DIRS
)

if (OptiX_FOUND AND NOT TARGET OptiX::OptiX)
    add_library(OptiX::OptiX INTERFACE IMPORTED)
    set_target_properties(OptiX::OptiX PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      INTERFACE_INCLUDE_DIRECTORIES "${OptiX_INCLUDE_DIRS}")
endif()



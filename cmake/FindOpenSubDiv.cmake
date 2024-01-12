# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find OpenSubDiv
#
# Imported targets
# ----------------
# This module defines the following imported targets:
#
# ``OpenSubDiv::OpenSubDiv``
#   The OpenSubDiv library, if found
#
# Result variables
# ----------------
# ``OpenSubDiv_INCLUDE_DIRS``
#   where to find headers
# ``OpenSubDiv_LIBRARIES``
#   the libraries to link against to use OpenSubDiv
#
find_path(OpenSubDiv_INCLUDE_DIR
  NAMES version.h
  PATH_SUFFIXES opensubdiv
  HINTS $ENV{OPENSUBDIV_ROOT}/include /usr/local/include)

# need to find <opensubdiv/version.h>
set(OpenSubDiv_INCLUDE_DIRS ${OpenSubDiv_INCLUDE_DIR}/..)

find_library(OpenSubDiv_CPU_LIBRARY
  NAMES osdCPU
  HINTS $ENV{OPENSUBDIV_ROOT}/lib /usr/local/lib)

find_library(OpenSubDiv_GPU_LIBRARY
  NAMES osdGPU
  HINTS $ENV{OPENSUBDIV_ROOT}/lib /usr/local/lib)

set(OpenSubDiv_LIBRARIES "${OpenSubDiv_CPU_LIBRARY};${OpenSubDiv_GPU_LIBRARY}")

mark_as_advanced(OpenSubDiv_INCLUDE_DIR OpenSubDiv_INCLUDE_DIRS OpenSubDiv_CPU_LIBRARY OpenSubDiv_GPU_LIBRARY OpenSubDiv_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OpenSubDiv
  REQUIRED_VARS OpenSubDiv_LIBRARIES OpenSubDiv_INCLUDE_DIRS
)

if (OpenSubDiv_FOUND AND NOT TARGET OpenSubDiv::OpenSubDiv)
    add_library(OpenSubDiv::osdCPU UNKNOWN IMPORTED)
    set_target_properties(OpenSubDiv::osdCPU PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${OpenSubDiv_CPU_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${OpenSubDiv_INCLUDE_DIRS}")
    add_library(OpenSubDiv::osdGPU UNKNOWN IMPORTED)
    set_target_properties(OpenSubDiv::osdGPU PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${OpenSubDiv_GPU_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${OpenSubDiv_INCLUDE_DIRS}")
    add_library(OpenSubDiv::OpenSubDiv UNKNOWN IMPORTED)
    set_target_properties(OpenSubDiv::OpenSubDiv PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${OpenSubDiv_GPU_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${OpenSubDiv_INCLUDE_DIRS}")
    target_link_libraries(OpenSubDiv::OpenSubDiv 
      INTERFACE OpenSubDiv::osdCPU)
endif()


# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find OpenImageIOMoonray, our modified version of openimageio
# filesystem_impl.h is present only in this version
#
# Imported targets
# ----------------
# This module defines the following imported targets:
#
# ``OpenImageIOMoonray::OpenImageIOMoonray``
#   The OpenImageIOMoonray library, if found
#
# Result variables
# ----------------
# ``OpenImageIOMoonray_INCLUDE_DIRS``
#   where to find filesystem_impl.h etc...
# ``OpenImageIOMoonray_LIBRARIES``
#   the libraries to link against to use OpenImageIOMoonray
#
find_path(OpenImageIOMoonray_INCLUDE_DIR
  NAMES filesystem_impl.h
  PATH_SUFFIXES OpenImageIO
  HINTS $ENV{OPENIMAGEIOMOONRAY_ROOT}/include /usr/local/include)

# need to find <OpenImageIO/filesystem_impl.h>
set(OpenImageIOMoonray_INCLUDE_DIRS ${OpenImageIOMoonray_INCLUDE_DIR}/..)

find_library(OpenImageIOMoonray_LIBRARIES
  NAMES OpenImageIO_moonray
  PATH_SUFFIXES avx
  HINTS $ENV{OPENIMAGEIOMOONRAY_ROOT}/lib /usr/local/lib)
mark_as_advanced(OpenImageIOMoonray_INCLUDE_DIR OpenImageIOMoonray_INCLUDE_DIRS OpenImageIOMoonray_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OpenImageIOMoonray
  REQUIRED_VARS OpenImageIOMoonray_LIBRARIES OpenImageIOMoonray_INCLUDE_DIRS
)

if (OpenImageIOMoonray_FOUND AND NOT TARGET OpenImageIOMoonray::OpenImageIOMoonray)
    add_library(OpenImageIOMoonray::OpenImageIOMoonray UNKNOWN IMPORTED)
    target_link_libraries(OpenImageIOMoonray::OpenImageIOMoonray
      INTERFACE MoonrayStats::statistics)
    set_target_properties(OpenImageIOMoonray::OpenImageIOMoonray PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${OpenImageIOMoonray_LIBRARIES}"
      INTERFACE_INCLUDE_DIRECTORIES "${OpenImageIOMoonray_INCLUDE_DIRS}")
    
    find_package(IlmBase REQUIRED)
    target_link_libraries(OpenImageIOMoonray::OpenImageIOMoonray
      INTERFACE IlmBase::Imath)
endif()



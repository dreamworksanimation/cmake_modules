# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

find_path(Libgif_INCLUDE_DIRS
  NAMES gif_lib.h
  HINTS $ENV{LIBGIF_ROOT}/include /usr/include)
find_library(Libgif_LIBRARY
  NAMES gif
  HINTS $ENV{LIBGIF_ROOT}/lib /lib64)

mark_as_advanced(Libgif_INCLUDE_DIRS Libgif_LIBRARY)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Libgif
  REQUIRED_VARS Libgif_LIBRARY Libgif_INCLUDE_DIRS
)

if (Libgif_FOUND AND NOT TARGET Libgif::Libgif)
    add_library(Libgif::Libgif UNKNOWN IMPORTED)
    set_target_properties(Libgif::Libgif PROPERTIES
      IMPORTED_LOCATION "${Libgif_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Libgif_INCLUDE_DIRS}")
endif()


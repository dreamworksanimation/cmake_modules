# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

find_path(Libuuid_INCLUDE_DIRS
  NAMES uuid.h
  HINTS $ENV{LIBUUID_ROOT}/include /usr/include/uuid)
find_library(Libuuid_LIBRARY
  NAMES uuid
  HINTS $ENV{LIBUUID_ROOT}/lib /lib64)

mark_as_advanced(Libuuid_INCLUDE_DIRS Libuuid_LIBRARY)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Libuuid
  REQUIRED_VARS Libuuid_LIBRARY Libuuid_INCLUDE_DIRS
)

if (Libuuid_FOUND AND NOT TARGET Libuuid::Libuuid)
    add_library(Libuuid::Libuuid UNKNOWN IMPORTED)
    set_target_properties(Libuuid::Libuuid PROPERTIES
      IMPORTED_LOCATION "${Libuuid_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Libuuid_INCLUDE_DIRS}")
endif()


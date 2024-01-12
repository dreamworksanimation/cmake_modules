# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

find_path(Libcurl_INCLUDE_DIR
  NAMES curl.h
  PATH_SUFFIXES curl
  HINTS $ENV{LIBCURL_ROOT}/include /usr/include)

# need to find <curl/curl.h>
set(Libcurl_INCLUDE_DIRS ${Libcurl_INCLUDE_DIR}/..)

find_library(Libcurl_LIBRARY
  NAMES libcurl.so.4
  HINTS $ENV{LIBCURL_ROOT}/lib /lib64)

mark_as_advanced(Libcurl_INCLUDE_DIRS Libcurl_LIBRARY)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Libcurl
  REQUIRED_VARS Libcurl_LIBRARY Libcurl_INCLUDE_DIRS)

if (Libcurl_FOUND AND NOT TARGET Libcurl::Libcurl)
    add_library(Libcurl::Libcurl UNKNOWN IMPORTED)
    set_target_properties(Libcurl::Libcurl PROPERTIES
      IMPORTED_LOCATION "${Libcurl_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Libcurl_INCLUDE_DIRS}")
endif()



# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find jsoncpp
#
# Imported targets
# ----------------
# This module defines the following imported targets:
#
# ``JsonCpp::JsonCpp``
#   The jsoncpp library, if found
#
# Result variables
# ----------------
# ``JsonCpp_INCLUDE_DIRS``
#   where to find json.h etc...
# ``JsonCpp_LIBRARIES``
#   the libraries to link against to use jsoncpp
#
find_path(JsonCpp_INCLUDE_DIR
  NAMES json.h
  PATH_SUFFIXES json jsoncpp/json
  HINTS $ENV{JSONCPP_ROOT}/include /usr/local/include)

# need to find <json/json.h>
set(JsonCpp_INCLUDE_DIRS ${JsonCpp_INCLUDE_DIR}/..)

find_library(JsonCpp_LIBRARIES
  NAMES json jsoncpp
  HINTS $ENV{JSONCPP_ROOT}/lib /usr/local/lib)
mark_as_advanced(JsonCpp_INCLUDE_DIR JsonCpp_INCLUDE_DIRS JsonCpp_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(JsonCpp
  REQUIRED_VARS JsonCpp_LIBRARIES JsonCpp_INCLUDE_DIRS
)

if (JsonCpp_FOUND AND NOT TARGET JsonCpp::JsonCpp)
    add_library(JsonCpp::JsonCpp UNKNOWN IMPORTED)
    set_target_properties(JsonCpp::JsonCpp PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${JsonCpp_LIBRARIES}"
      INTERFACE_INCLUDE_DIRECTORIES "${JsonCpp_INCLUDE_DIRS}")
endif()



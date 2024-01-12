# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find OpenVDB
#
# Imported targets
# ----------------
# This module defines the following imported targets:
#
# ``OpenVDB::OpenVDB``
#   The OpenVDB library, if found
#
# Result variables
# ----------------
# ``OpenVDB_INCLUDE_DIRS``
#   where to find openvdb.h etc...
# ``OpenVDB_LIBRARIES``
#   the libraries to link against to use OpenVDB
#
find_path(OpenVDB_INCLUDE_DIR
  NAMES openvdb.h
  PATH_SUFFIXES openvdb
  HINTS $ENV{OPENVDB_ROOT}/include /usr/local/include)

# need to find <openvdb/openvdb.h>
set(OpenVDB_INCLUDE_DIRS ${OpenVDB_INCLUDE_DIR}/..)

find_library(OpenVDB_LIBRARIES
  NAMES openvdb
  HINTS $ENV{OPENVDB_ROOT}/lib /usr/local/lib)
mark_as_advanced(OpenVDB_INCLUDE_DIR OpenVDB_INCLUDE_DIRS OpenVDB_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OpenVDB
  REQUIRED_VARS OpenVDB_LIBRARIES OpenVDB_INCLUDE_DIRS
)

if (OpenVDB_FOUND AND NOT TARGET OpenVDB::OpenVDB)
    add_library(OpenVDB::OpenVDB UNKNOWN IMPORTED)
    set_target_properties(OpenVDB::OpenVDB PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${OpenVDB_LIBRARIES}"
      INTERFACE_INCLUDE_DIRECTORIES "${OpenVDB_INCLUDE_DIRS}")
endif()


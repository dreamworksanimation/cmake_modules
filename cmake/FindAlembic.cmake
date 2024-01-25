# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find Alembic
#
# Imported targets
# ----------------
# This module defines the following imported targets:
#
# ``Alembic::Alembic``
#   The Alembic library, if found
#
# Result variables
# ----------------
# ``Alembic_INCLUDE_DIRS``
#   where to find IObject.h etc...
# ``Alembic_LIBRARIES``
#   the libraries to link against to use Alembic
#
find_path(Alembic_INCLUDE_DIR
  NAMES IObject.h
  PATH_SUFFIXES Alembic/Abc 
  HINTS $ENV{REZ_ALEMBIC_ROOT}/include /usr/local/include)

# need to find #include <Alembic/Abc/IObject.h>
set(Alembic_INCLUDE_DIRS ${Alembic_INCLUDE_DIR}/../..)

find_library(Alembic_LIBRARIES
  NAMES Alembic
  HINTS $ENV{REZ_ALEMBIC_ROOT}/lib /usr/local/lib)
mark_as_advanced(Alembic_INCLUDE_DIR Alembic_INCLUDE_DIRS Alembic_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Alembic
  REQUIRED_VARS Alembic_LIBRARIES Alembic_INCLUDE_DIRS
)

if (Alembic_FOUND AND NOT TARGET Alembic::Alembic)
    add_library(Alembic::Alembic UNKNOWN IMPORTED)
    set_target_properties(Alembic::Alembic PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${Alembic_LIBRARIES}"
      INTERFACE_INCLUDE_DIRECTORIES "${Alembic_INCLUDE_DIRS}")
endif()


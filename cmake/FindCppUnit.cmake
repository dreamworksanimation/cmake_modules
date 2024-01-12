# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

find_path(CppUnit_INCLUDE_DIR
    NAMES Test.h TestResult.h
    PATH_SUFFIXES cppunit
    HINTS $ENV{CPPUNIT_ROOT}/include /usr/local/include)

# need to find <cppunit/Test.h>
set(CppUnit_INCLUDE_DIRS ${CppUnit_INCLUDE_DIR}/..)

find_library(CppUnit_LIBRARIES
    NAMES cppunit
    HINTS $ENV{CPPUNIT_ROOT}/lib /usr/local/lib)

mark_as_advanced(CppUnit_INCLUDE_DIR CppUnit_INCLUDE_DIRS CppUnit_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(CppUnit
    REQUIRED_VARS CppUnit_LIBRARIES CppUnit_INCLUDE_DIRS
)

if (CppUnit_FOUND AND NOT TARGET CppUnit::CppUnit)
    add_library(CppUnit::CppUnit UNKNOWN IMPORTED)
    set_target_properties(CppUnit::CppUnit PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
        IMPORTED_LOCATION "${CppUnit_LIBRARIES}"
        INTERFACE_INCLUDE_DIRECTORIES "${CppUnit_INCLUDE_DIRS}")
endif()




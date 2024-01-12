# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# This module has portions that are based on Autodesk's Maya-USD plugin which
# is under the Apache 2.0 license, and contains contributions from Pixar and
# Animal Logic.

if (NOT PXR_USD_LOCATION)
    set(PXR_USD_LOCATION $ENV{PXR_USD_LOCATION})
endif()

find_path(USD_INCLUDE_DIR
    NAMES
        pxr/pxr.h
    HINTS
        ${PXR_USD_LOCATION}
    PATH_SUFFIXES
        include
    DOC
        "USD Include directory"
)

find_file(USD_GENSCHEMA
    NAMES
        usdGenSchema
    PATHS
        ${PXR_USD_LOCATION}
    PATH_SUFFIXES
        bin
    DOC
        "USD Gen schema application"
)

find_file(USD_CONFIG_FILE
    NAMES
        pxrConfig.cmake
    PATHS
        ${PXR_USD_LOCATION}
        # at DWA, our pxrConfig.cmake comes from usd_imaging, not usd_core
        $ENV{REZ_USD_IMAGING_ROOT}
    DOC
        "USD cmake configuration file"
)

# try to read the config file
include(${USD_CONFIG_FILE})

if(DEFINED PXR_VERSION)
    # pxrConfig.cmake provides the versions as cmake vars starting in USD 12.05
    set(USD_VERSION ${PXR_MAJOR_VERSION}.${PXR_MINOR_VERSION}.${PXR_PATCH_VERSION})
elseif(USD_INCLUDE_DIR AND EXISTS "${USD_INCLUDE_DIR}/pxr/pxr.h")
    # For older versions, parse them from pxr/pxr.h
    foreach(component MAJOR MINOR PATCH)
        file(STRINGS "${USD_INCLUDE_DIR}/pxr/pxr.h" versionDef
            REGEX "#define PXR_${component}_VERSION .*$")
        string(REGEX MATCHALL "[0-9]+" USD_${component}_VERSION ${versionDef})
    endforeach()

    set(USD_VERSION ${USD_MAJOR_VERSION}.${USD_MINOR_VERSION}.${USD_PATCH_VERSION})
    math(EXPR PXR_VERSION "${USD_MAJOR_VERSION} * 10000 + ${USD_MINOR_VERSION} * 100 + ${USD_PATCH_VERSION}")
endif()

# Note that on Windows with USD <= 0.19.11, USD_LIB_PREFIX should be left at
# default (or set to empty string), even if PXR_LIB_PREFIX was specified when
# building core USD, due to a bug.

# On all other platforms / versions, it should match the PXR_LIB_PREFIX used
# for building USD (and shouldn't need to be touched if PXR_LIB_PREFIX was not
# used / left at it's default value). Starting with USD 21.11, the default
# value for PXR_LIB_PREFIX was changed to include "usd_".

if (USD_VERSION VERSION_GREATER_EQUAL "0.21.11")
    set(USD_LIB_PREFIX "${CMAKE_SHARED_LIBRARY_PREFIX}usd_"
        CACHE STRING "Prefix of USD libraries; generally matches the PXR_LIB_PREFIX used when building core USD")
else()
    set(USD_LIB_PREFIX ${CMAKE_SHARED_LIBRARY_PREFIX}
        CACHE STRING "Prefix of USD libraries; generally matches the PXR_LIB_PREFIX used when building core USD")
endif()

if (WIN32)
    # ".lib" on Windows
    set(USD_LIB_SUFFIX ${CMAKE_STATIC_LIBRARY_SUFFIX}
        CACHE STRING "Extension of USD libraries")
else ()
    # ".so" on Linux, ".dylib" on MacOS
    set(USD_LIB_SUFFIX ${CMAKE_SHARED_LIBRARY_SUFFIX}
        CACHE STRING "Extension of USD libraries")
endif ()

# DWA :: usd-0.20.11 switched to pseudo-less lib names
message(STATUS "USD version num: ${PXR_VERSION}")
if (PXR_VERSION GREATER_EQUAL 2011)
    set(USD_LIB_NAME "${USD_LIB_PREFIX}pxr_usd_usd${USD_LIB_SUFFIX}")
else()
    set(USD_LIB_NAME "${USD_LIB_PREFIX}pxr_usd_usd-$ENV{PSEUDO_NAME}${USD_LIB_SUFFIX}")
endif()

find_library(USD_LIBRARY
    NAMES
        ${USD_LIB_NAME}
    HINTS
        ${PXR_USD_LOCATION}
    PATH_SUFFIXES
        lib
    DOC
        "Main USD library"
)

get_filename_component(USD_LIBRARY_DIR ${USD_LIBRARY} DIRECTORY)

# Get the boost version from the one built with USD
if (USD_INCLUDE_DIR)
    file(GLOB _USD_VERSION_HPP_FILE "${USD_INCLUDE_DIR}/boost-*/boost/version.hpp")
    list(LENGTH _USD_VERSION_HPP_FILE found_one)
    if (${found_one} STREQUAL "1")
        list(GET _USD_VERSION_HPP_FILE 0 USD_VERSION_HPP)
        file(STRINGS
            "${USD_VERSION_HPP}"
            _usd_tmp
            REGEX "#define BOOST_VERSION .*$")
        string(REGEX MATCH "[0-9]+" USD_BOOST_VERSION ${_usd_tmp})
        unset(_usd_tmp)
        unset(_USD_VERSION_HPP_FILE)
        unset(USD_VERSION_HPP)
    endif()
endif()

message(STATUS "Pxr USD Location: ${PXR_USD_LOCATION}")
message(STATUS "USD include dir: ${USD_INCLUDE_DIR}")
message(STATUS "USD library dir: ${USD_LIBRARY_DIR}")
message(STATUS "USD library: ${USD_LIBRARY}")
message(STATUS "USD library name: ${USD_LIB_NAME}")
message(STATUS "USD library suffix: ${USD_LIB_SUFFIX}")
message(STATUS "USD version: ${USD_VERSION}")
message(STATUS "Pxr version: ${PXR_VERSION}")
message(STATUS "USD  config file: ${USD_CONFIG_FILE}")

if(DEFINED USD_BOOST_VERSION)
    message(STATUS "USD Boost::boost version: ${USD_BOOST_VERSION}")
endif()

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(USD
    REQUIRED_VARS
        USD_INCLUDE_DIR
        USD_LIBRARY_DIR
        USD_GENSCHEMA
        USD_CONFIG_FILE
        USD_VERSION
        PXR_VERSION
    VERSION_VAR
        USD_VERSION
)

if (NOT TARGET USD::core)
    add_library(USD::core UNKNOWN IMPORTED)
    set_target_properties(USD::core PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${USD_LIBRARY_DIR}"
      INTERFACE_INCLUDE_DIRECTORIES "${USD_INCLUDE_DIR}"
    )
    target_link_libraries(USD::core
        INTERFACE
            Python::Module
    )
endif()



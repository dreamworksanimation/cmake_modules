# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

find_path(Log4cplus_INCLUDE_DIR
    NAMES logger.h
    PATH_SUFFIXES log4cplus
    HINTS $ENV{LOG4CPLUS_ROOT}/include /usr/local/include)

# need to find <log4cplus/logger.h>
set(Log4cplus_INCLUDE_DIRS ${Log4cplus_INCLUDE_DIR}/..)

find_library(Log4cplus_LIBRARIES
    NAMES log4cplus
    HINTS $ENV{LOG4CPLUS_ROOT}/lib /usr/local/lib)

mark_as_advanced(Log4cplus_INCLUDE_DIR Log4cplus_INCLUDE_DIRS Log4cplus_LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Log4cplus
    REQUIRED_VARS Log4cplus_LIBRARIES Log4cplus_INCLUDE_DIRS
)

if (Log4cplus_FOUND AND NOT TARGET Log4cplus::Log4cplus)
    add_library(Log4cplus::Log4cplus UNKNOWN IMPORTED)
    set_target_properties(Log4cplus::Log4cplus PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
        IMPORTED_LOCATION "${Log4cplus_LIBRARIES}"
        INTERFACE_INCLUDE_DIRECTORIES "${Log4cplus_INCLUDE_DIRS}")
endif()


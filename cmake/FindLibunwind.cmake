# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

find_path(Libunwind_INCLUDE_DIRS
    NAMES libunwind.h
    HINTS $ENV{LIBUNWIND_ROOT}/include /usr/local/include)

find_library(Libunwind_LIBRARY
    NAMES unwind
    HINTS $ENV{LIBUNWIND_ROOT}/lib /usr/local/lib)

find_library(Libunwind_LIBRARY-x86_64
    NAMES unwind-x86_64
    HINTS $ENV{LIBUNWIND_ROOT}/lib /usr/local/lib)

list(APPEND Libunwind_LIBRARIES ${Libunwind_LIBRARY} ${Libunwind_LIBRARY-x86_64})

# find_library(Libunwind_LIBRARY_x86_64 unwind-x86_64)
mark_as_advanced(Libunwind_INCLUDE_DIR Libunwind_LIBRARY Libunwind-LIBRARY-x86_64 Libunwind-LIBRARIES)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Libunwind
    REQUIRED_VARS Libunwind_LIBRARIES Libunwind_INCLUDE_DIRS
)

if (Libunwind_FOUND AND NOT TARGET Libunwind::Libunwind)
    add_library(Libunwind::Libunwind UNKNOWN IMPORTED)
    set_target_properties(Libunwind::Libunwind PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
        IMPORTED_LOCATION "${Libunwind_LIBRARY}"
        INTERFACE_LINK_LIBRARIES "${Libunwind_LIBRARY-x86_64}"
        INTERFACE_INCLUDE_DIRECTORIES "${Libunwind_INCLUDE_DIRS}")
endif()


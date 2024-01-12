# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# Find Mkl (Math Kernel Library)
#
find_path(Mkl_INCLUDE_DIR
  NAMES mkl.h
  HINTS $ENV{MKL_ROOT}/include /usr/local/include)

find_library(Mkl_core_LIBRARY
  NAMES mkl_core
  HINTS $ENV{MKL_ROOT}/lib /usr/local/lib)
find_library(Mkl_sequential_LIBRARY
  NAMES mkl_sequential
  HINTS $ENV{MKL_ROOT}/lib /usr/local/lib)
find_library(Mkl_intel_lp64_LIBRARY
  NAMES mkl_intel_lp64
  HINTS $ENV{MKL_ROOT}/lib /usr/local/lib)
find_library(Mkl_avx_LIBRARY
  NAMES mkl_avx
  HINTS $ENV{MKL_ROOT}/lib /usr/local/lib)
find_library(Mkl_def_LIBRARY
  NAMES mkl_def
  HINTS $ENV{MKL_ROOT}/lib /usr/local/lib)
find_library(Mkl_iomp5_LIBRARY
  NAMES iomp5
  HINTS $ENV{MKL_ROOT}/lib /usr/local/lib)

set(Mkl_LIBRARIES 
      Mkl_core_LIBRARY
      Mkl_sequential_LIBRARY
      Mkl_intel_lp64_LIBRARY
      Mkl_avx_LIBRARY
      Mkl_def_LIBRARY
      Mkl_iomp5_LIBRARY
)
mark_as_advanced(Mkl_INCLUDE_DIR Mkl_LIBRARIES
      Mkl_core_LIBRARY Mkl_sequential_LIBRARY
      Mkl_intel_lp64_LIBRARY Mkl_avx_LIBRARY
      Mkl_def_LIBRARY Mkl_iomp5_LIBRARY)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Mkl
  REQUIRED_VARS Mkl_LIBRARIES Mkl_INCLUDE_DIR
)

if (Mkl_FOUND AND NOT TARGET Mkl::Mkl)
    add_library(Mkl::core UNKNOWN IMPORTED)
    set_target_properties(Mkl::core PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${Mkl_core_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Mkl_INCLUDE_DIR}")
    add_library(Mkl::sequential UNKNOWN IMPORTED)
    set_target_properties(Mkl::sequential PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${Mkl_sequential_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Mkl_INCLUDE_DIR}")
    add_library(Mkl::intel_lp64 UNKNOWN IMPORTED)
    set_target_properties(Mkl::intel_lp64 PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${Mkl_intel_lp64_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Mkl_INCLUDE_DIR}")
    add_library(Mkl::avx UNKNOWN IMPORTED)
    set_target_properties(Mkl::avx PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${Mkl_avx_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Mkl_INCLUDE_DIR}")
    add_library(Mkl::def UNKNOWN IMPORTED)
    set_target_properties(Mkl::def PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${Mkl_def_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Mkl_INCLUDE_DIR}")
    add_library(Mkl::iomp5 UNKNOWN IMPORTED)
    set_target_properties(Mkl::iomp5 PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
      IMPORTED_LOCATION "${Mkl_iomp5_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${Mkl_INCLUDE_DIR}")
    add_library(Mkl::Mkl INTERFACE IMPORTED)
    set_property(TARGET Mkl::Mkl PROPERTY
        INTERFACE_LINK_LIBRARIES 
          Mkl::core 
          Mkl::sequential
          Mkl::intel_lp64
          Mkl::avx
          Mkl::def
          Mkl::iomp5)
endif()



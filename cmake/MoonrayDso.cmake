# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

include(OMR_Platform)

function(Moonray_dso_cxx_compile_options target)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(${target}
            PRIVATE
                $<$<BOOL:${ABI_SET_VERSION}>:
                    -fabi-version=${ABI_VERSION} # corrects the promotion behavior of C++11 scoped enums and the mangling of template argument packs.
                >
                -fexceptions                    # Enable exception handling.
                -fno-omit-frame-pointer         # TODO: add a note
                -fno-strict-aliasing            # TODO: add a note
                -fno-var-tracking-assignments   # Turn off variable tracking
                -fpermissive                    # Downgrade some diagnostics about nonconformant code from errors to warnings.
                -march=core-avx2                # Specify the name of the target architecture
                -mavx                           # x86 options
                -pipe                           # Use pipes rather than intermediate files.
                -pthread                        # Define additional macros required for using the POSIX threads library.
                -w                              # Inhibit all warning messages.
                -Wall                           # Enable most warning messages.
                -Wcast-align                    # Warn about pointer casts which increase alignment.
                -Wcast-qual                     # Warn about casts which discard qualifiers.
                -Wdisabled-optimization         # Warn when an optimization pass is disabled.
                -Wextra                         # This enables some extra warning flags that are not enabled by -Wall
                -Woverloaded-virtual            # Warn about overloaded virtual function names.
                -Wno-conversion                 # Disable certain warnings that are enabled by -Wall
                -Wno-sign-compare               # Disable certain warnings that are enabled by -Wall
                -Wno-switch                     # Disable certain warnings that are enabled by -Wall
                -Wno-system-headers             # Disable certain warnings that are enabled by -Wall
                -Wno-unused-parameter           # Disable certain warnings that are enabled by -Wall

                $<$<CONFIG:RELWITHDEBINFO>:
                    -O3                         # the default is -O2 for RELWITHDEBINFO
                >
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL Clang)
        target_compile_options(${target}
            # TODO: Some if not all of these should probably be PUBLIC
            PRIVATE
                -march=core-avx2                # Specify the name of the target architecture
                -mavx                           # x86 options
                -fdelayed-template-parsing      # Shader.h has a template method that uses a moonray class which is no available to scene_rdl2 and is only used in moonray+
                -Wno-deprecated-declarations    # disable auto_ptr deprecated warnings from log4cplus-1.
                -Wno-unused-value               # For opt-debug build MNRY_VERIFY(exp) the value is not used.
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL Intel)
        target_compile_options(${target}
            # TODO: Some if not all of these should probably be PUBLIC
            PRIVATE
                -march=core-avx2                # Specify the name of the target architecture
                -mavx                           # x86 options
        )
    endif()
endfunction()

function(Moonray_dso_ispc_compile_options target)
    set(commonOptions
        ${GLOBAL_ISPC_FLAGS}
        --opt=force-aligned-memory          # always issue "aligned" vector load and store instructions
        --pic                               # Generate position-independent code.  Ignored for Windows target
        #--werror                            # Treat warnings as errors
        --wno-perf                          # Don't issue warnings related to performance-related issues
    )
    set_property(TARGET ${target}
                 PROPERTY TARGET_OBJECTS $<TARGET_OBJECTS:${target}>)
    # Custom property to track the ISPC dependency target (e.g., ${target}_ispc_dep)
    # for ensuring proper build order when ISPC compilation is required
    set_property(TARGET ${target}
                 PROPERTY ISPC_DEP_TARGET "")
    check_language(ISPC)
    if(NOT CMAKE_ISPC_COMPILER)
        get_target_property(SOURCES ${target} SOURCES)
        get_target_property(ISPC_HEADER_SUFFIX ${target} ISPC_HEADER_SUFFIX)
        get_target_property(ISPC_HEADER_DIRECTORY ${target} ISPC_HEADER_DIRECTORY)
        get_target_property(ISPC_INSTRUCTION_SETS ${target} ISPC_INSTRUCTION_SETS)

        set(configDepFlags "")
        if (CMAKE_BUILD_TYPE STREQUAL "Debug")
            set(configDepFlags
                    -g                              # emit debug info
                    --dwarf-version=2               # use DWARF version 2 for debug symbols
                )
        elseif (CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
            set(configDepFlags
                    -g                              # emit debug info
                    -O3                             # the default is -O2 for RELWITHDEBINFO
                    --dwarf-version=2               # use DWARF version 2 for debug symbols
                    --opt=disable-assertions        # disable all of the assertions
                )
        elseif (CMAKE_BUILD_TYPE STREQUAL "Release")
            set(configDepFlags
                    --opt=disable-assertions        # disable all of the assertions
                )
        endif()

        foreach(src ${SOURCES})
            get_filename_component(srcExt ${src} LAST_EXT)

            if (NOT srcExt STREQUAL ".ispc")
                continue()
            endif()

            get_filename_component(srcName ${src} NAME_WE)

            set(objOut "${CMAKE_CURRENT_BINARY_DIR}/${srcName}.o")
            set(depFile "${CMAKE_CURRENT_BINARY_DIR}/${srcName}.dep")
            add_custom_command(
                OUTPUT ${objOut}
                COMMAND ${ISPC_COMPILER} ${CMAKE_CURRENT_SOURCE_DIR}/${src}
                    -o ${objOut}
                    -h "./${ISPC_HEADER_DIRECTORY}/${srcName}${ISPC_HEADER_SUFFIX}"
                    -M -MF ${depFile}
                    --arch=aarch64                      # TODO: hardcoded...
                    --target=${ISPC_INSTRUCTION_SETS}
                    --target-os=macos
                    ${commonOptions}
                    ${configDepFlags}
                    "-I$<JOIN:$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>,;-I>"
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                COMMAND_EXPAND_LISTS
                VERBATIM
                DEPFILE ${depFile}
                DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${src})
            list(APPEND ISPC_TARGET_OBJECTS ${objOut})
        endforeach()
        target_link_libraries(${target}
                PRIVATE ${ISPC_TARGET_OBJECTS})
        add_custom_target(${target}_ispc_dep DEPENDS ${ISPC_TARGET_OBJECTS})
        add_dependencies(${target} ${target}_ispc_dep)
        # Store the ISPC dependency target name for later retrieval
        set_property(TARGET ${target}
                 PROPERTY ISPC_DEP_TARGET ${target}_ispc_dep)
        set_property(
                TARGET ${target}
                PROPERTY
                    TARGET_OBJECTS ${ISPC_TARGET_OBJECTS})
    else ()
        target_compile_options(${target}
            PRIVATE
                ${commonOptions}
                $<$<CONFIG:DEBUG>:
                    --dwarf-version=2               # use DWARF version 2 for debug symbols
                >

                $<$<CONFIG:RELWITHDEBINFO>:
                    -O3                             # the default is -O2 for RELWITHDEBINFO
                    --dwarf-version=2               # use DWARF version 2 for debug symbols
                    --opt=disable-assertions        # disable all of the assertions
                >

                $<$<CONFIG:RELEASE>:
                    --opt=disable-assertions        # disable all of the assertions
                >
        )
    endif()
endfunction()

function(Moonray_dso_cxx_compile_definitions target)
    if(CMAKE_BINARY_DIR MATCHES ".*refplat-vfx2020.*")
        # Use openvdb abi version 7 for vfx2020 to match up with Houdini 18.5
        set(abi OPENVDB_ABI_VERSION_NUMBER=7)
    endif()

    if(${TBB_VERSION} VERSION_GREATER_EQUAL "2021.0")
        set(tbb_oneapi TBB_ONEAPI)
    endif()

    target_compile_definitions(${target}
        PRIVATE
            ${GLOBAL_CPP_FLAGS}                 # TODO: add comment
            BOOST_FILESYSTEM_VERSION=3          # TODO: add comment
            DWA_BOOST_VERSION=1082000           # TODO: add comment
            OPENVDB_USE_BLOSC                   # TODO: Move this to where it is needed?
            OPENVDB_USE_LOG4CPLUS               # TODO: Move this to where it is needed?
            DWREAL_IS_DOUBLE=1                  # TODO: add comment
            dwreal=double                       # TODO: add comment
            GL_GLEXT_PROTOTYPES=1               # TODO: add comment
            ${abi}                              # Which version of the openvdb ABI to use
            PDI_2l                              # TODO: add comment
            PDI_DL                              # TODO: add comment
            PDI_OGL                             # TODO: add comment
            PDI_pc                              # TODO: add comment
            PDI_USE_GLX_1_3                     # TODO: add comment
            _LIBCPP_ENABLE_CXX17_REMOVED_AUTO_PTR=1 # Clang - enable auto_ptr when targeting c++17
            _LIBCPP_ENABLE_CXX17_REMOVED_RANDOM_SHUFFLE=1 # Clang - ensure std::random_shuffle is available
            ${tbb_oneapi}                       # define TBB_ONEAPI if TBB version >= 2021.0

            $<$<BOOL:${MOONRAY_DWA_BUILD}>:
                DWA_OPENVDB                     # Enables some SIMD computations in DWA's version of openvdb
            >

            $<$<CONFIG:DEBUG>:
                DEBUG                           # TODO: add comment
                PDI_DEBUG                       # TODO: add comment
            >
            $<$<CONFIG:RELWITHDEBINFO>:
                BOOST_DISABLE_ASSERTS           # TODO: add comment
            >
            $<$<CONFIG:RELEASE>:
                BOOST_DISABLE_ASSERTS           # TODO: add comment
            >

        PUBLIC
            TBB_SUPPRESS_DEPRECATED_MESSAGES    # TODO: add comment
    )
endfunction()

function(Moonray_dso_cxx_compile_features target)
    target_compile_features(${target}
        PRIVATE
            cxx_std_17
    )
endfunction()

function(Moonray_dso_link_options target)
    if(NOT IsDarwinPlatform)
        target_link_options(${target}
            PRIVATE
                -Wl,--enable-new-dtags              # Use RUNPATH instead of RPATH
        )
    else()
        target_link_options(${target}
            PRIVATE
                -Wl,-ld_classic
                -undefined dynamic_lookup
    )
    endif()
endfunction()

# Create a DSO target from .cc, and attribute.cc sources
# Parameters:
#   targetName          : The name of the target and source filename, eg. ${name}.cc
#                         if DSO_NAME is not provided
#   SKIP_INSTALL        : Skips the installation, useful for test DSOs
#   DSO_NAME            : The name of the DSO and source filename, eg. ${DSO_NAME}.cc,
#                         useful when the target name is not the same as the DSO/source file
#   SOURCE_DIR          : relative path from ${CMAKE_CURRENT_LIST_DIR}/
#                         where the source files live
#   DEPENDENCIES        : list of target libraries to link
#
# attributes.cc is expected with the source.
function(moonray_dso_simple targetName)
    set(options SKIP_INSTALL TEST_DSO)
    set(oneValueArgs DSO_NAME SOURCE_DIR)
    set(multiValueArgs DEPENDENCIES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    add_library(${targetName} SHARED "")
    add_library(${targetName}_proxy SHARED "")

    set(attrs attributes.cc)
    set(includeDir ${CMAKE_CURRENT_SOURCE_DIR})

    set(dsoName ${targetName})

    if (ARG_DSO_NAME)
        set(dsoName ${ARG_DSO_NAME})
        set_target_properties(${targetName}       PROPERTIES OUTPUT_NAME ${ARG_DSO_NAME})
        set_target_properties(${targetName}_proxy PROPERTIES OUTPUT_NAME ${ARG_DSO_NAME}_proxy)
    endif()

    set(src ${dsoName}.cc)

    if (ARG_SOURCE_DIR)
        string(PREPEND src ${ARG_SOURCE_DIR}/)
        string(PREPEND attrs ${ARG_SOURCE_DIR}/)
        string(APPEND includeDir "/${ARG_SOURCE_DIR}")
    endif()

    # full dso
    set_target_properties(${targetName} PROPERTIES PREFIX "") # removes "lib" prefix from .so
    if(IsDarwinPlatform)
        set_target_properties(${targetName} PROPERTIES SUFFIX ".so") # switch .dylib for .so
    endif()
    target_sources(${targetName} PRIVATE ${src})
    target_include_directories(${targetName} PRIVATE ${includeDir})
    target_link_libraries(${targetName} PUBLIC ${ARG_DEPENDENCIES})
    Moonray_dso_cxx_compile_definitions(${targetName})
    Moonray_dso_cxx_compile_features(${targetName})
    Moonray_dso_cxx_compile_options(${targetName})
    Moonray_dso_link_options(${targetName})

    # proxy dso
    set_target_properties(${targetName}_proxy PROPERTIES
        PREFIX "" OUTPUT_NAME ${dsoName} SUFFIX ".so.proxy")
    target_sources(${targetName}_proxy PRIVATE ${attrs})
    target_include_directories(${targetName}_proxy PRIVATE ${includeDir})
    target_link_libraries(${targetName}_proxy PUBLIC SceneRdl2::scene_rdl2)
    Moonray_dso_cxx_compile_definitions(${targetName}_proxy)
    Moonray_dso_cxx_compile_features(${targetName}_proxy)
    Moonray_dso_cxx_compile_options(${targetName}_proxy)
    Moonray_dso_link_options(${targetName}_proxy)

   # json class file
   if (NOT ARG_TEST_DSO)
       if (XCODE)
           set(configDir "${CMAKE_BUILD_TYPE}")
       endif()
       # Defines a custom command that when run generates the json files
       # needed for third party apps
       add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${dsoName}.json
           POST_BUILD
           COMMAND rdl2_json_exporter --dso_path ${CMAKE_CURRENT_BINARY_DIR}/${configDir}
           --in $<TARGET_FILE:${targetName}_proxy>
           --out ${CMAKE_CURRENT_BINARY_DIR}/${dsoName}.json
           DEPENDS ${targetName}_proxy
           BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/${dsoName}.json
           VERBATIM
           )
       add_custom_target(coredata_${targetName} ALL DEPENDS
           ${CMAKE_CURRENT_BINARY_DIR}/${dsoName}.json)

       # copy resulting DSOs to <build>/rdl2dso dir to be found by tests
       add_custom_command(TARGET ${targetName} POST_BUILD
           COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/rdl2dso
           COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:${targetName}> ${CMAKE_BINARY_DIR}/rdl2dso/$<TARGET_FILE_NAME:${targetName}>
           COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:${targetName}_proxy> ${CMAKE_BINARY_DIR}/rdl2dso/$<TARGET_FILE_NAME:${targetName}_proxy>
       )
   endif()

    if (NOT ARG_SKIP_INSTALL)
        install(TARGETS ${targetName} COMPONENT ${targetName}
            LIBRARY DESTINATION ${RDL2DSO_INSTALL_DIR}
            NAMELINK_SKIP
            )
        install(TARGETS ${targetName}_proxy COMPONENT ${targetName}
            LIBRARY DESTINATION ${RDL2DSO_INSTALL_DIR}
            NAMELINK_SKIP
            )
        if (NOT ARG_TEST_DSO)
            install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${dsoName}.json
                COMPONENT ${targetName} DESTINATION coredata
                )
        endif()
    endif()
endfunction()

if(EXISTS ${CMAKE_SOURCE_DIR}/openmoonray/cmake_modules/build_scripts/ispc_dso_generate)
    set(ISPC_DSO_GENERATE
        ${CMAKE_SOURCE_DIR}/openmoonray/cmake_modules/build_scripts/ispc_dso_generate)
elseif(EXISTS ${CMAKE_SOURCE_DIR}/cmake_modules/build_scripts/ispc_dso_generate)
    set(ISPC_DSO_GENERATE
        ${CMAKE_SOURCE_DIR}/cmake_modules/build_scripts/ispc_dso_generate)
elseif(EXISTS $ENV{CMAKE_MODULES_ROOT}/build_scripts/ispc_dso_generate)
    set(ISPC_DSO_GENERATE $ENV{CMAKE_MODULES_ROOT}/build_scripts/ispc_dso_generate)
else()
    message(SEND_ERROR "Location of ispc_dso_generate is unknown can not continue")
endif()

set(ISPC_DSO_GEN_SCRIPT ${ISPC_DSO_GENERATE} CACHE FILEPATH
    "The ispc_dso_generate script for generating sources and headers for a DSO from the .json file")

if (NOT DEFINED PYTHON_EXECUTABLE)
    set(PYTHON_EXECUTABLE python)
endif()

# Create a DSO target from .cc, .ispc sources and JSON attribute description
# Parameters:
#   name                : The name of the target and source filenames, eg.
#                         ${name}.cc, ${name}.ispc, ${name}.json
#   SKIP_INSTALL        : Skips the installation, useful for test DSOs
#   SOURCE_DIR          : Optional relative path from ${CMAKE_CURRENT_LIST_DIR}/
#                         where the source files live
#   JSON_INCLUDE_DIR    : Optional list of paths to search for .json files requested
#                         from any 'include' directives within the json file(s)
#   DEPENDENCIES        : Optional list of target libraries to link
#
# files attributes.cc, attributesISPC.cc attributes.isph labels.h and labels.isph
# will be autogenerated in the build tree based on the JSON file.
function(moonray_ispc_dso name)
    set(options SKIP_INSTALL TEST_DSO)
    set(oneValueArgs SOURCE_DIR)
    set(multiValueArgs DEPENDENCIES JSON_INCLUDE_DIRS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(ccSrc   ${name}.cc)
    set(ispcSrc ${name}.ispc)
    set(jsonSrc ${name}.json)
    set(jsonIncludeDir ${PROJECT_SOURCE_DIR})
    set(genDir ${CMAKE_CURRENT_BINARY_DIR})

    if (ARG_SOURCE_DIR)
        string(PREPEND ccSrc   "${ARG_SOURCE_DIR}/")
        string(PREPEND ispcSrc "${ARG_SOURCE_DIR}/")
        string(PREPEND jsonSrc "${ARG_SOURCE_DIR}/")
        string(APPEND  genDir  "/${ARG_SOURCE_DIR}")
    endif()

    if (ARG_JSON_INCLUDE_DIRS)
        list(APPEND jsonIncludeDir ${ARG_JSON_INCLUDE_DIRS})
    endif()

    # Generate C++ and ISPC source files from JSON metadata.
    # Uses add_custom_command with OUTPUT to track file dependencies and
    # avoid unnecessary rebuilds when content hasn't changed.
    add_custom_command(
        OUTPUT
            ${genDir}/attributes.cc
            ${genDir}/attributesISPC.cc
            ${genDir}/attributes.isph
            ${genDir}/labels.h
            ${genDir}/labels.isph
        COMMAND
            ${CMAKE_COMMAND} -E make_directory ${genDir}
        COMMAND
            ${ISPC_DSO_GEN_SCRIPT} ${jsonSrc}
            -o ${genDir} -i ${jsonIncludeDir}
        DEPENDS
            ${jsonSrc}
        WORKING_DIRECTORY
            ${CMAKE_CURRENT_LIST_DIR}
        COMMENT
            "Generating DSO files from ${jsonSrc}"
    )

    # Mark files as generated so CMake doesn't expect them to exist at configure time
    set_source_files_properties(
        ${genDir}/attributes.cc
        ${genDir}/attributesISPC.cc
        ${genDir}/attributes.isph
        ${genDir}/labels.h
        ${genDir}/labels.isph
        PROPERTIES
            GENERATED TRUE
    )

    # compile ispc to .o
    set(objLib ${name}_objlib)
    add_library(${objLib} OBJECT ${ispcSrc} ${genDir}/attributes.isph)
    target_include_directories(${objLib} PRIVATE ${genDir})
    
    # ISPC sources must wait for generated headers before compilation
    set_property(SOURCE ${ispcSrc}
        PROPERTY OBJECT_DEPENDS ${genDir}/attributes.isph ${genDir}/labels.isph)
    
    file(RELATIVE_PATH relBinDir ${CMAKE_BINARY_DIR} ${genDir})
    set_target_properties(${objLib} PROPERTIES
        ISPC_HEADER_SUFFIX _ispc_stubs.h
        ISPC_HEADER_DIRECTORY /${relBinDir}
        ISPC_INSTRUCTION_SETS ${GLOBAL_ISPC_INSTRUCTION_SETS}
        LINKER_LANGUAGE CXX
    )
    target_link_libraries(${objLib} PRIVATE ${ARG_DEPENDENCIES})
    Moonray_dso_ispc_compile_options(${objLib})

    # Ensure ISPC header generation completes before ISPC compilation starts
    get_target_property(objLibIspcDep ${objLib} ISPC_DEP_TARGET)
    if(objLibIspcDep)
        add_custom_command(
            OUTPUT ${genDir}/.ispc_headers_ready
            COMMAND ${CMAKE_COMMAND} -E touch ${genDir}/.ispc_headers_ready
            DEPENDS ${genDir}/attributes.isph ${genDir}/labels.isph
            COMMENT "Waiting for ISPC header generation"
        )
        add_custom_target(${name}_ispc_headers_dep DEPENDS ${genDir}/.ispc_headers_ready)
        add_dependencies(${objLibIspcDep} ${name}_ispc_headers_dep)
    endif()

    get_target_property(objLibDeps ${objLib} ISPC_DEP_TARGET)
    if(objLibDeps)
        add_dependencies(${objLibDeps}
            ${ARG_DEPENDENCIES})
    endif()

    # full dso
    add_library(${name} SHARED "")
    set_target_properties(${name} PROPERTIES PREFIX "") # removes "lib" prefix from .so
    set_target_properties(${name} PROPERTIES SUFFIX ".so")
    get_target_property(ISPC_TARGET_OBJECTS ${objLib} TARGET_OBJECTS)
    target_sources(${name}
            PRIVATE
                ${ccSrc}
                ${genDir}/attributesISPC.cc
                ${ISPC_TARGET_OBJECTS}
    )
    target_include_directories(${name} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${genDir})
    target_link_libraries(${name} PUBLIC ${ARG_DEPENDENCIES})
    add_dependencies(${name} ${objLib})
    Moonray_dso_cxx_compile_definitions(${name})
    Moonray_dso_cxx_compile_features(${name})
    Moonray_dso_cxx_compile_options(${name})
    Moonray_dso_link_options(${name})

    # proxy dso
    add_library(${name}_proxy SHARED "")
    set_target_properties(${name}_proxy PROPERTIES
        PREFIX "" OUTPUT_NAME ${name} SUFFIX ".so.proxy")
    target_compile_features(${name}_proxy
        PRIVATE cxx_std_17)
    target_sources(${name}_proxy PRIVATE ${genDir}/attributes.cc)
    target_include_directories(${name}_proxy PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(${name}_proxy PUBLIC SceneRdl2::scene_rdl2)

    # Xcode requires both targets using custom command outputs to share a common dependency
    add_dependencies(${name}_proxy ${objLib})

    Moonray_dso_cxx_compile_options(${name}_proxy)
    Moonray_dso_link_options(${name}_proxy)

   # Create symlinks in rdl2dso/ for tests and generate JSON metadata.
   # JSON generation in POST_BUILD avoids circular dependencies with Xcode.
   if (NOT ARG_TEST_DSO)
       if (XCODE)
           set(configDir "$<CONFIG>")  # "Debug" or "Release"
       else()
           set(configDir "")
       endif()
       set(proxyDsoPath "${CMAKE_CURRENT_BINARY_DIR}/${configDir}/${name}.so.proxy")
       add_custom_command(TARGET ${name} POST_BUILD
           COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/rdl2dso
           COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:${name}> ${CMAKE_BINARY_DIR}/rdl2dso/$<TARGET_FILE_NAME:${name}>
           COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:${name}_proxy> ${CMAKE_BINARY_DIR}/rdl2dso/$<TARGET_FILE_NAME:${name}_proxy>
           COMMAND rdl2_json_exporter --dso_path ${CMAKE_CURRENT_BINARY_DIR}/${configDir}
               --in ${proxyDsoPath}
               --out ${CMAKE_CURRENT_BINARY_DIR}/${name}.json
           COMMENT "Creating symlinks and generating JSON metadata for ${name}"
           VERBATIM
       )
   endif()

    if (NOT ARG_SKIP_INSTALL)
        install(TARGETS ${name} COMPONENT ${name}
            LIBRARY DESTINATION ${RDL2DSO_INSTALL_DIR}
            NAMELINK_SKIP
        )
        install(TARGETS ${name}_proxy COMPONENT ${name}
            LIBRARY DESTINATION ${RDL2DSO_INSTALL_DIR}
            NAMELINK_SKIP
        )
        if (NOT ARG_TEST_DSO)
            install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${name}.json
                COMPONENT ${name} DESTINATION coredata
            )
        endif()
    endif()
endfunction()


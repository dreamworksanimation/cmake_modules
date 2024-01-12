# Copyright 2023-2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

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
    target_compile_options(${target}
        PRIVATE
            --opt=force-aligned-memory          # always issue "aligned" vector load and store instructions
            --pic                               # Generate position-independent code.  Ignored for Windows target
            --werror                            # Treat warnings as errors
            --wno-perf                          # Don't issue warnings related to performance-related issues

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
endfunction()

function(Moonray_dso_cxx_compile_definitions target)
    if(CMAKE_BINARY_DIR MATCHES ".*refplat-vfx2020.*")
        # Use openvdb abi version 7 for vfx2020 to match up with Houdini 18.5
        set(abi OPENVDB_ABI_VERSION_NUMBER=7)
    endif()

    target_compile_definitions(${target}
        PRIVATE
            __AVX__                             # TODO: add comment
            BOOST_FILESYSTEM_VERSION=3          # TODO: add comment
            DWA_BOOST_VERSION=1073000           # TODO: add comment
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
    target_link_options(${target}
        PRIVATE
            -Wl,--enable-new-dtags              # Use RUNPATH instead of RPATH
    )
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
        # Defines a custom command that when run generates the json files
        # needed for third party apps
        add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${dsoName}.json
            POST_BUILD
            COMMAND rdl2_json_exporter --dso_path ${CMAKE_CURRENT_BINARY_DIR}
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

if(EXISTS ${CMAKE_SOURCE_DIR}/cmake_modules/build_scripts/ispc_dso_generate)
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

    # Make sure the directory exists to place the generated files
    add_custom_target(${name}_make_build_dir
        COMMAND
            ${CMAKE_COMMAND} -E make_directory ${genDir}
    )

    # autogenerate sources attributes.cc etc
    add_custom_command( OUTPUT
                            ${genDir}/attributes.cc
                            ${genDir}/attributesISPC.cc
                            ${genDir}/attributes.isph
                            ${genDir}/labels.h
                            ${genDir}/labels.isph
                        DEPENDS
                           ${name}_make_build_dir
                           ${jsonSrc}
                        WORKING_DIRECTORY
                            ${CMAKE_CURRENT_LIST_DIR}
                        COMMAND
                            ${PYTHON_EXECUTABLE} ${ISPC_DSO_GEN_SCRIPT} ${jsonSrc}
                            -o ${genDir} -i ${jsonIncludeDir}
    )

    # compile ispc to .o
    set(objLib ${name}_objlib)
    add_library(${objLib} OBJECT)
    target_sources(${objLib} PRIVATE ${ispcSrc} ${genDir}/attributes.isph)
    target_include_directories(${objLib} PRIVATE ${genDir})
    file(RELATIVE_PATH relBinDir ${CMAKE_BINARY_DIR} ${genDir})
    set_target_properties(${objLib} PROPERTIES
        ISPC_HEADER_SUFFIX _ispc_stubs.h
        ISPC_HEADER_DIRECTORY /${relBinDir}
        ISPC_INSTRUCTION_SETS avx1-i32x8
    )
    target_link_libraries(${objLib} PRIVATE ${ARG_DEPENDENCIES})
    Moonray_dso_ispc_compile_options(${objLib})

    # full dso
    add_library(${name} SHARED "")
    set_target_properties(${name} PROPERTIES PREFIX "") # removes "lib" prefix from .so
    target_sources(${name}
            PRIVATE
                ${ccSrc}
                ${genDir}/attributesISPC.cc
                $<TARGET_OBJECTS:${objLib}>
    )
    target_include_directories(${name} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR} ${genDir})
    target_link_libraries(${name} PUBLIC ${ARG_DEPENDENCIES})
    Moonray_dso_cxx_compile_definitions(${name})
    Moonray_dso_cxx_compile_features(${name})
    Moonray_dso_cxx_compile_options(${name})
    Moonray_dso_link_options(${name})

    # proxy dso
    add_library(${name}_proxy SHARED "")
    set_target_properties(${name}_proxy PROPERTIES
        PREFIX "" OUTPUT_NAME ${name} SUFFIX ".so.proxy")
    target_sources(${name}_proxy PRIVATE ${genDir}/attributes.cc)
    target_include_directories(${name}_proxy PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(${name}_proxy PUBLIC SceneRdl2::scene_rdl2)
    Moonray_dso_cxx_compile_options(${name}_proxy)
    Moonray_dso_link_options(${name}_proxy)

    # json class file
    if (NOT ARG_TEST_DSO)
        # Defines a custom command that when run generates the json files
        # needed for third party apps
        add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${name}.json
            POST_BUILD
            COMMAND rdl2_json_exporter --dso_path ${CMAKE_CURRENT_BINARY_DIR}
            --in $<TARGET_FILE:${name}_proxy>
            --out ${CMAKE_CURRENT_BINARY_DIR}/${name}.json
            DEPENDS ${name}_proxy
            BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}/${name}.json
            VERBATIM
            )
        add_custom_target(coredata_${name} ALL DEPENDS
            ${CMAKE_CURRENT_BINARY_DIR}/${name}.json)

        # copy resulting DSO to <build>/rdl2dso dir to be found by tests
        add_custom_command(TARGET ${name} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/rdl2dso
            COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:${name}> ${CMAKE_BINARY_DIR}/rdl2dso/$<TARGET_FILE_NAME:${name}>
            COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:${name}_proxy> ${CMAKE_BINARY_DIR}/rdl2dso/$<TARGET_FILE_NAME:${name}_proxy>
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


# Copyright 2024 DreamWorks Animation LLC
# SPDX-License-Identifier: Apache-2.0

# -*- coding: utf-8 -*-

name = 'cmake_modules'

@early()
def version():
    """
    Increment the build in the version.
    """
    from json import load
    _version = '0.1'
    from rezbuild import earlybind
    return earlybind.version(this, _version)

description = 'Common CMake modules needed to build Moonbase packages with CMake.'

authors = [
    'R&D Rendering and Shading',
    'moonbase-dev@dreamworks.com',
    'Ron.Woods@dreamworks.com'
]

requires = ['cmake-3.23']

build_command = ("[ {install} ] && "
                 "rsync -tavz --exclude '.git*' --exclude 'build' --exclude 'package.py' {root}/ `printenv REZ_BUILD_INSTALL_PATH` || "
                 "echo No --install flag found, build\(s\) are no-ops.")

def commands():
    prependenv('CMAKE_MODULE_PATH', '{root}/cmake')
    setenv('CMAKE_MODULES_ROOT', '{root}')

uuid = '13b00c83-0482-4141-b68e-d7b80b0e3eab'

config_version = 0

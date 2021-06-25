# Copyright 2017 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Need support for CMAKE_C_COMPILER_TARGET
cmake_minimum_required(VERSION 3.0)

set(CMAKE_C_COMPILER "${TOOLCHAIN_DIR}/bin/clang")
set(CMAKE_C_COMPILER_TARGET ${CUSTOM_COMPILER_TARGET} CACHE STRING "")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_DIR}/bin/clang++")
set(CMAKE_CXX_COMPILER_TARGET ${CUSTOM_COMPILER_TARGET} CACHE STRING "")
set(CMAKE_ASM_COMPILER "${TOOLCHAIN_DIR}/bin/clang")
set(CMAKE_ASM_COMPILER_TARGET ${CUSTOM_COMPILER_TARGET} CACHE STRING "")

set(CMAKE_LINKER "${TOOLCHAIN_DIR}/bin/ld.lld" CACHE PATH "")
set(CMAKE_AR "${TOOLCHAIN_DIR}/bin/llvm-ar" CACHE PATH "")
set(CMAKE_RANLIB "${TOOLCHAIN_DIR}/bin/llvm-ranlib" CACHE PATH "")
set(CMAKE_NM "${TOOLCHAIN_DIR}/bin/llvm-nm" CACHE PATH "")
set(CMAKE_OBJCOPY "${TOOLCHAIN_DIR}/bin/llvm-objcopy" CACHE PATH "")
set(CMAKE_OBJDUMP "${TOOLCHAIN_DIR}/bin/llvm-objdump" CACHE PATH "")
set(CMAKE_STRIP "${TOOLCHAIN_DIR}/bin/llvm-strip" CACHE PATH "")

set(CMAKE_SYSROOT ${TOOLCHAIN_SYSROOT} CACHE STRING "Sysroot path")

set(CMAKE_FIND_ROOT_PATH "${TOOLCHAIN_SYSROOT}" "${CMAKE_PREFIX_PATH}" "${CMAKE_INSTALL_PREFIX}")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

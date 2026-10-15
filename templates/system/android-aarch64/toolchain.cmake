# CMake toolchain file — Android aarch64 (arm64-v8a), any API level.
# Portable: nothing here is retrolunar-specific. It reads the compilers and the
# sysroot from the environment, so source snippets/systems/android-aarch64.sh first.
#
# Usage:
#   . snippets/systems/android-aarch64.sh
#   cmake -S . -B build \
#     -DCMAKE_TOOLCHAIN_FILE=templates/system/android-aarch64/toolchain.cmake \
#     -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
#     -DTHREADS_PREFER_PTHREAD_FLAG=ON \
#     -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
#     -DCMAKE_INSTALL_PREFIX="$PREFIX"
#
# Reference: references/systems/android-aarch64.md

# Keep CMAKE_SYSTEM_NAME = Linux. Setting it to "Android" makes CMake run its own
# NDK integration; here the NDK is wired up by hand via the environment.
set(CMAKE_SYSTEM_NAME Linux)

# CPU architecture (the triplet in $CC carries the API level).
set(CMAKE_SYSTEM_PROCESSOR "aarch64")

# Compilers from the environment if not already set.
if(NOT CMAKE_C_COMPILER)
  set(CMAKE_C_COMPILER "$ENV{CC}" CACHE FILEPATH "C compiler" FORCE)
endif()
if(NOT CMAKE_CXX_COMPILER)
  set(CMAKE_CXX_COMPILER "$ENV{CXX}" CACHE FILEPATH "C++ compiler" FORCE)
endif()

set(CMAKE_AR "$ENV{AR}" CACHE FILEPATH "archiver" FORCE)
set(CMAKE_RANLIB "$ENV{RANLIB}" CACHE FILEPATH "ranlib" FORCE)
set(CMAKE_STRIP "$ENV{STRIP}" CACHE FILEPATH "strip" FORCE)
set(CMAKE_READELF "$ENV{READELF}" CACHE FILEPATH "readelf" FORCE)
set(CMAKE_OBJDUMP "$ENV{OBJDUMP}" CACHE FILEPATH "objdump" FORCE)
set(CMAKE_OBJCOPY "$ENV{OBJCOPY}" CACHE FILEPATH "objcopy" FORCE)
set(CMAKE_NM "$ENV{NM}" CACHE FILEPATH "nm" FORCE)
set(CMAKE_ASM_COMPILER "$ENV{AS}" CACHE FILEPATH "assembler" FORCE)
set(CMAKE_LINKER "$ENV{LD}" CACHE FILEPATH "linker" FORCE)
set(CMAKE_SYSROOT "$ENV{SYSROOT}")
set(CMAKE_INSTALL_PREFIX "$ENV{PREFIX}" CACHE PATH "install prefix")

# find_library/find_path look in PREFIX first, then the NDK sysroot.
set(CMAKE_FIND_ROOT_PATH "$ENV{PREFIX};$ENV{SYSROOT}")

# Never look for runnable utilities in CMAKE_FIND_ROOT_PATH (target binaries).
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# Libraries, headers and CMake packages only in SYSROOT or PREFIX.
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

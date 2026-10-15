# CMake toolchain file — Windows x86 via mingw-w64 (i686-w64-mingw32).
# Portable: reads compilers from the environment; source snippets/systems/mingw32.sh first.
# NO sysroot: CMAKE_FIND_ROOT_PATH covers PREFIX only. Reference: references/systems/mingw32.md
#
# Usage:
#   . snippets/systems/mingw32.sh
#   cmake -S . -B build \
#     -DCMAKE_TOOLCHAIN_FILE=templates/system/mingw32/toolchain.cmake \
#     -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
#     -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX="$PREFIX"

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR "i686")

if(NOT CMAKE_C_COMPILER)
  set(CMAKE_C_COMPILER "$ENV{CC}" CACHE FILEPATH "C compiler" FORCE)
endif()
if(NOT CMAKE_CXX_COMPILER)
  set(CMAKE_CXX_COMPILER "$ENV{CXX}" CACHE FILEPATH "C++ compiler" FORCE)
endif()

# Resource compiler for .rc files
set(CMAKE_RC_COMPILER "i686-w64-mingw32-windres" CACHE FILEPATH "resource compiler" FORCE)

set(CMAKE_AR "$ENV{AR}" CACHE FILEPATH "archiver" FORCE)
set(CMAKE_RANLIB "$ENV{RANLIB}" CACHE FILEPATH "ranlib" FORCE)
set(CMAKE_STRIP "$ENV{STRIP}" CACHE FILEPATH "strip" FORCE)
set(CMAKE_READELF "$ENV{READELF}" CACHE FILEPATH "readelf" FORCE)
set(CMAKE_OBJDUMP "$ENV{OBJDUMP}" CACHE FILEPATH "objdump" FORCE)
set(CMAKE_OBJCOPY "$ENV{OBJCOPY}" CACHE FILEPATH "objcopy" FORCE)
set(CMAKE_NM "$ENV{NM}" CACHE FILEPATH "nm" FORCE)
set(CMAKE_ASM_COMPILER "$ENV{AS}" CACHE FILEPATH "assembler" FORCE)
set(CMAKE_LINKER "$ENV{LD}" CACHE FILEPATH "linker" FORCE)
set(CMAKE_INSTALL_PREFIX "$ENV{PREFIX}" CACHE PATH "install prefix")

# No sysroot: look in PREFIX only.
set(CMAKE_FIND_ROOT_PATH "$ENV{PREFIX}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

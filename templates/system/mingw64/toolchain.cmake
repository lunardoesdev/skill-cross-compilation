# CMake toolchain file — Windows x86-64 via mingw-w64 (x86_64-w64-mingw32).
# Portable: reads compilers from the environment; source snippets/systems/mingw64.sh first.
# There is NO sysroot: CMAKE_FIND_ROOT_PATH covers PREFIX only.
# Reference: references/systems/mingw64.md
#
# Usage:
#   . snippets/systems/mingw64.sh
#   cmake -S . -B build \
#     -DCMAKE_TOOLCHAIN_FILE=templates/system/mingw64/toolchain.cmake \
#     -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
#     -DCMAKE_REQUIRED_LIBRARIES="crypt32;ole32;oleaut32;uuid;gdi32" \
#     -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX="$PREFIX"
#
# Note CMAKE_REQUIRED_LIBRARIES: the Windows import libraries must land at the END of the
# link line (after the archives that reference them). See the README in this directory.

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR "x86_64")

if(NOT CMAKE_C_COMPILER)
  set(CMAKE_C_COMPILER "$ENV{CC}" CACHE FILEPATH "C compiler" FORCE)
endif()
if(NOT CMAKE_CXX_COMPILER)
  set(CMAKE_CXX_COMPILER "$ENV{CXX}" CACHE FILEPATH "C++ compiler" FORCE)
endif()

# Resource compiler for .rc files (windres ships with mingw-w64)
set(CMAKE_RC_COMPILER "x86_64-w64-mingw32-windres" CACHE FILEPATH "resource compiler" FORCE)

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

# Never look for runnable utilities in PREFIX (would find target .exe); host tools win.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

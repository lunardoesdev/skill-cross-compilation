#!/bin/sh
# expat 2.7.1 -- cmake build. No great traps; the point is that every host-side
# target is switched off by name, because cmake builds them by default.
#
# Environment: cmake cross toolchain, $PREFIX, $DESTDIR, $CORES.
#
# OVERRIDES AND WHY
#   -DEXPAT_SHARED_LIBS=OFF   static-first prefix.
#   -DEXPAT_BUILD_TOOLS=OFF   xmlwf etc. are target programs the host cannot run.
#   -DEXPAT_BUILD_TESTS=OFF   target test programs.
#   -DEXPAT_BUILD_EXAMPLES=OFF
#   -DEXPAT_BUILD_DOCS=OFF    docs need a host toolchain; of no use in a prefix.
#
# The cmake cross toolchain already pins CMAKE_MAKE_PROGRAM to a HOST make and sets
# CMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY so the compiler check links instead of
# running a target binary -- see the cmake driver snippet for why that matters.
set -eu

cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DTHREADS_PREFER_PTHREAD_FLAG=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_MAKE_PROGRAM="$CMAKE_MAKE_PROGRAM" \
  -DEXPAT_SHARED_LIBS=OFF \
  -DEXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_TESTS=OFF \
  -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_DOCS=OFF

cmake --build build --parallel "$CORES"
DESTDIR="$DESTDIR" cmake --install build

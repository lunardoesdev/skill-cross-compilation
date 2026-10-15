#!/bin/sh
# zlib 1.3.1 -- cmake build (the CMakeLists drives the same sources). Straightforward,
# except for one cross-system naming trap.
#
# Environment: cmake cross toolchain, $PREFIX, $DESTDIR, $CORES.
#
# OVERRIDES
#   -DZLIB_BUILD_EXAMPLES=OFF   the examples are target programs that cannot run on
#                               the build host.
#
# THE TRAP -- the library name differs by target family.
#   On mingw, zlib installs its library as libzlib, while configure scripts across
#   the tree hardcode -lz. So the alias libz.* -> libzlib.* has to exist, and it
#   belongs in zlib's own lib/ directory (where the library is), not scattered.
#   The loop below creates the alias for every extension actually present, which is
#   what makes it work whether the build produced a .a, a .so, or both. It is left
#   here unconditionally -- harmless where the library is already named libz.
set -eu

cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DTHREADS_PREFER_PTHREAD_FLAG=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_MAKE_PROGRAM="$CMAKE_MAKE_PROGRAM" \
  -DZLIB_BUILD_EXAMPLES=OFF

cmake --build build --parallel "$CORES"
DESTDIR="$DESTDIR" cmake --install build

# Alias any libzlib.* onto libz.* for the -lz that configure scripts hardcode.
for _f in "$PREFIX"/lib/libzlib.*; do
  [ -f "$_f" ] || continue
  _ext="${_f##*libzlib}"
  [ -f "$PREFIX/lib/libz$_ext" ] || ln -s "libzlib$_ext" "$PREFIX/lib/libz$_ext"
done
unset _f _ext

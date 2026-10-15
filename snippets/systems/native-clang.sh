# snippets/systems/native-clang.sh
# Native host build environment using clang (no cross toolchain).
#
# Triple:    x86_64-pc-linux-gnu  — build == host == target (one triplet).
# Target OS: linux   Meson: native (no cross-file)
#
# What the platform provides: the running host's glibc, libm, libstdc++/libc++, headers.
# Build yourself into $PREFIX: anything not already on the host.
# There is NO cross-file and NO CMake toolchain file: the native toolchain is the host's.
#
# Description: references/systems/native-clang.md
# Usage:   . snippets/systems/native-clang.sh

PREFIX="${PREFIX:-${OUTPKG:-/usr/local}}"   # this system's nest dir, where deps landed

CC="clang"
CXX="clang++"
AR="ar"
RANLIB="ranlib"
LD="ld"
AS="$CC"
STRIP="strip"
OBJCOPY="objcopy"
READELF="readelf"
OBJDUMP="objdump"

# $CFLAGS/$CXXFLAGS stay clean for direct $CC users; the probe-only flags live in
# $CPPFLAGS (provided by your harness) — e.g. libpng's zlib check reads $CPPFLAGS.
CFLAGS="-O2 -fPIC $CPPFLAGS"
CXXFLAGS="-O2 -fPIC $CPPFLAGS"
# -Wl,--undefined-version is a GNU-ld relaxation and is ELF-only: it must NOT appear in
# a mingw (PE) LDFLAGS. It is kept here so projects with version scripts still link.
LDFLAGS="$LDFLAGS -Wl,--undefined-version"

# Ignore host .pc files: only ours ($PREFIX) count.
PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"

BUILD_TRIPLET="x86_64-pc-linux-gnu"
HOST_TRIPLET="$BUILD_TRIPLET"
TARGET_TRIPLET="$HOST_TRIPLET"
HOST_ARCH="x86_64"
HOST_OS="linux"

export PREFIX CC CXX AR RANLIB LD AS STRIP OBJCOPY READELF OBJDUMP \
       CFLAGS CXXFLAGS LDFLAGS PKG_CONFIG_PATH \
       BUILD_TRIPLET HOST_TRIPLET TARGET_TRIPLET HOST_ARCH HOST_OS

# Host facts the source system exposes as `probe` (output + exit status feed freshness):
#   clang --version ; meson --version ; cmake --version ; pkg-config --version

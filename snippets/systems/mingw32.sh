# snippets/systems/mingw32.sh
# Windows / x86 via mingw-w64 (i686-w64-mingw32). 32-bit sibling of mingw64.sh.
#
# Triple:    i686-w64-mingw32
# Target OS: windows (PE)   Meson: system=windows cpu_family=x86 cpu=i686 exe_suffix=exe
# Toolchain: distro mingw-w64 gcc/binutils — NO NDK, NO sysroot.
#
# Same "no $ORIGIN" and "no -fPIC" facts as mingw64 (read references/systems/mingw32.md).
# The retrolunar source for this target sets no import-library plumbing at all and leaves
# CARGO_BUILD_TARGET empty; treat those as unfinished here too.
#
# Description: references/systems/mingw32.md
# Usage:   . snippets/systems/mingw32.sh

PREFIX="${PREFIX:-${OUTPKG:-/usr/local}}"

CC="i686-w64-mingw32-gcc"
CXX="i686-w64-mingw32-g++"
AR="i686-w64-mingw32-ar"
RANLIB="i686-w64-mingw32-ranlib"
LD="i686-w64-mingw32-ld"
STRIP="i686-w64-mingw32-strip"
OBJCOPY="i686-w64-mingw32-objcopy"
READELF="i686-w64-mingw32-readelf"
NM="i686-w64-mingw32-nm"
OBJDUMP="i686-w64-mingw32-objdump"
WINDRES="i686-w64-mingw32-windres"

CFLAGS="-O2"
CXXFLAGS="$CFLAGS"
# No LDFLAGS (no -Wl,--undefined-version: ELF-only; no rpath: PE has no $ORIGIN).
# If a package needs the Windows certificate store / COM, add these at the END of the
# link line (there is no CMAKE_REQUIRED_LIBRARIES plumbing in the source for i686):
#   -lcrypt32 -lole32 -loleaut32 -luuid -lgdi32

PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"

BUILD_TRIPLET="x86_64-pc-linux-gnu"
HOST_TRIPLET="i686-w64-mingw32"
TARGET_TRIPLET="$HOST_TRIPLET"
HOST_ARCH="i686"
HOST_OS="mingw32"

export PREFIX CC CXX AR RANLIB LD STRIP OBJCOPY READELF NM OBJDUMP WINDRES \
       CFLAGS CXXFLAGS PKG_CONFIG_PATH \
       BUILD_TRIPLET HOST_TRIPLET TARGET_TRIPLET HOST_ARCH HOST_OS

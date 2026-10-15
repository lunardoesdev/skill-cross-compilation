# snippets/systems/mingw64.sh
# Windows / x86-64 via mingw-w64 (x86_64-w64-mingw32).
#
# Triple:    x86_64-w64-mingw32
# Target OS: windows (PE)   Meson: system=windows cpu_family=x86_64 exe_suffix=exe
# Toolchain: the distro's mingw-w64 gcc/g++ and binutils — NO NDK, NO sysroot.
#
# What the toolchain provides: Windows ABI headers, libgcc, winpthreads, and the import
#   libraries (crypt32, ole32, oleaut32, uuid, gdi32).
# Build yourself into $PREFIX: everything else (zlib, openssl, ...).
# No $ORIGIN: a PE file resolves imports through the search path, so there is no rpath.
#   Consequently the autoconf/cargo drivers emit NO -Wl,-rpath; a bundle gets a launcher.
#
# Description: references/systems/mingw64.md
# Usage:   . snippets/systems/mingw64.sh

PREFIX="${PREFIX:-${OUTPKG:-/usr/local}}"

CC="x86_64-w64-mingw32-gcc"
CXX="x86_64-w64-mingw32-g++"
AR="x86_64-w64-mingw32-ar"
RANLIB="x86_64-w64-mingw32-ranlib"
LD="x86_64-w64-mingw32-ld"
STRIP="x86_64-w64-mingw32-strip"
OBJCOPY="x86_64-w64-mingw32-objcopy"
READELF="x86_64-w64-mingw32-readelf"
NM="x86_64-w64-mingw32-nm"
OBJDUMP="x86_64-w64-mingw32-objdump"
WINDRES="x86_64-w64-mingw32-windres"   # .rc resource compiler (mingw-only)

# -O2 only. No -fPIC (PE has no such requirement), no -DANDROID.
CFLAGS="-O2"
CXXFLAGS="$CFLAGS"

# There is deliberately NO LDFLAGS. Two reasons, both load-bearing:
#  * -Wl,--undefined-version is ELF-only; ld for PE fails on it.
#  * the Windows import libraries must go at the END of the link line, AFTER the archives
#    that reference them. CMake seeds CMAKE_EXE_LINKER_FLAGS from $LDFLAGS, which places
#    them BEFORE the archives; ld does not revisit an archive it already passed, so
#    -lcrypt32 there yields `undefined reference to __imp_CertFindCertificateInStore'.
#    Put them in CMAKE_REQUIRED_LIBRARIES instead (see templates/system/mingw64/README.md):
#      -lcrypt32 -lole32 -loleaut32 -luuid -lgdi32
# No -Wl,-rpath: PE has no $ORIGIN.

# Ignore host .pc files: only ours ($PREFIX) count.
PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"

BUILD_TRIPLET="x86_64-pc-linux-gnu"
HOST_TRIPLET="x86_64-w64-mingw32"
TARGET_TRIPLET="$HOST_TRIPLET"
HOST_ARCH="x86_64"
HOST_OS="mingw32"     # the mingw "OS" spelling is the same for 64- and 32-bit

export PREFIX CC CXX AR RANLIB LD STRIP OBJCOPY READELF NM OBJDUMP WINDRES \
       CFLAGS CXXFLAGS PKG_CONFIG_PATH \
       BUILD_TRIPLET HOST_TRIPLET TARGET_TRIPLET HOST_ARCH HOST_OS

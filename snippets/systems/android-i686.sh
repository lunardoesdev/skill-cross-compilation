# snippets/systems/android-i686.sh
# Android / x86 (i686) cross-compilation environment.
#
# Triple:            i686-linux-android   (wrapper filename carries the API)
# Target OS:         android  (Bionic libc)   Meson: system=android cpu_family=x86 cpu=i686
# Tunable:           ANDROID_API (default 33)
# Required input:    ANDROID_HOME = an Android SDK that contains ndk/
#
# What the toolchain provides: NDK LLVM wrappers + llvm-* binutils + the x86 NDK sysroot.
# What the platform provides: Bionic libc/libm/libdl, liblog, libc++, and nothing else.
# Build yourself into $PREFIX: every third-party library.
#
# Description: references/systems/android-i686.md
# Usage:   ANDROID_HOME=~/Android/Sdk . snippets/systems/android-i686.sh

: "${ANDROID_HOME:?set ANDROID_HOME to an Android SDK with an NDK}"
: "${ANDROID_API:=33}"

_ndk_ver="$(for _c in "$ANDROID_HOME/ndk"/*; do
  [ -d "$_c" ] && printf '%s\n' "${_c##*/}"
done | sort -V | tail -1)"
if [ -z "$_ndk_ver" ]; then
  echo "android-i686: no NDK under $ANDROID_HOME/ndk" >&2
  unset _ndk_ver _c
  return 1 2>/dev/null || exit 1
fi
NDK="$ANDROID_HOME/ndk/$_ndk_ver"
unset _ndk_ver _c
TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64"
TOOLBIN="$TOOLCHAIN/bin"
SYSROOT="$TOOLCHAIN/sysroot"

CC="$TOOLBIN/i686-linux-android${ANDROID_API}-clang"
CXX="$TOOLBIN/i686-linux-android${ANDROID_API}-clang++"
AR="$TOOLBIN/llvm-ar"
RANLIB="$TOOLBIN/llvm-ranlib"
LD="$TOOLBIN/ld.lld"
STRIP="$TOOLBIN/llvm-strip"
OBJCOPY="$TOOLBIN/llvm-objcopy"
READELF="$TOOLBIN/llvm-readelf"
NM="$TOOLBIN/llvm-nm"
OBJDUMP="$TOOLBIN/llvm-objdump"

PREFIX="${PREFIX:-${OUTPKG:-/usr/local}}"
# CXXFLAGS = CFLAGS here (the sysroot -isystem goes to C++ as well, unlike aarch64).
CFLAGS="-O2 -fPIC -DANDROID -I$PREFIX/include -isystem $SYSROOT/usr/include"
CXXFLAGS="$CFLAGS"
CPPFLAGS="$CPPFLAGS -I$PREFIX/include -isystem $SYSROOT/usr/include"
LDFLAGS="$LDFLAGS -L$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -lm -llog"
# Runtime path (per build-system driver):
#   make/autoconf: -Wl,-rpath,'$$ORIGIN' -Wl,-rpath,'$$ORIGIN/../lib' -Wl,-rpath,'$$ORIGIN/../lib64'
#   cmake/meson/cargo: -Wl,-rpath,'$ORIGIN'  -Wl,-rpath,'$ORIGIN/../lib'  -Wl,-rpath,'$ORIGIN/../lib64'

PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:$SYSROOT/usr/lib/pkgconfig:$SYSROOT/usr/share/pkgconfig"
PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"

ac_cv_func_ffsl=yes
gl_cv_func_strcasecmp_works=yes

BUILD_TRIPLET="x86_64-pc-linux-gnu"
HOST_TRIPLET="i686-linux-android"
TARGET_TRIPLET="$HOST_TRIPLET"
HOST_ARCH="i686"
HOST_OS="android"

export NDK TOOLCHAIN TOOLBIN SYSROOT ANDROID_API PREFIX \
       CC CXX AR RANLIB LD STRIP OBJCOPY READELF NM OBJDUMP \
       CFLAGS CXXFLAGS CPPFLAGS LDFLAGS \
       PKG_CONFIG_LIBDIR PKG_CONFIG_PATH \
       ac_cv_func_ffsl gl_cv_func_strcasecmp_works \
       BUILD_TRIPLET HOST_TRIPLET TARGET_TRIPLET HOST_ARCH HOST_OS

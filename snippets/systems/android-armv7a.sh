# snippets/systems/android-armv7a.sh
# Android / armeabi-v7a (armv7a) cross-compilation environment.
#
# Triple:            armv7a-linux-androideabi   (Rust spells it armv7-linux-androideabi)
# Target OS:         android  (Bionic libc)      Meson: system=android cpu_family=arm cpu=armv7
# Tunable:           ANDROID_API (default 33)
# Required input:    ANDROID_HOME = an Android SDK that contains ndk/
#
# What the toolchain provides: NDK LLVM wrappers + llvm-* binutils + the armeabi-v7a
#   NDK sysroot.
# What the platform provides: Bionic libc/libm/libdl, liblog, libc++, and nothing else.
# Build yourself into $PREFIX: zlib, openssl, ... everything.
#
# NOTE on the wrapper name: the retrolunar sources pin armv7a to `...androideabi21-clang`
#   for every API level (system@armv7a-android33/system.toml:30-31), which is inconsistent
#   with ANDROID_API and leaves their CMake toolchain reference dangling for API >= 23
#   (references/systems/android-armv7a.md). Here the wrapper tracks $ANDROID_API, matching
#   the aarch64/i686/x86_64 systems. If you must reproduce the pinned-21 behaviour, set
#   WRAPPER_API=21 below.
#
# Description: references/systems/android-armv7a.md
# Usage:   ANDROID_HOME=~/Android/Sdk . snippets/systems/android-armv7a.sh

: "${ANDROID_HOME:?set ANDROID_HOME to an Android SDK with an NDK}"
: "${ANDROID_API:=33}"
: "${WRAPPER_API:=$ANDROID_API}"   # set to 21 to reproduce the pinned wrapper

_ndk_ver="$(for _c in "$ANDROID_HOME/ndk"/*; do
  [ -d "$_c" ] && printf '%s\n' "${_c##*/}"
done | sort -V | tail -1)"
if [ -z "$_ndk_ver" ]; then
  echo "android-armv7a: no NDK under $ANDROID_HOME/ndk" >&2
  unset _ndk_ver _c
  return 1 2>/dev/null || exit 1
fi
NDK="$ANDROID_HOME/ndk/$_ndk_ver"
unset _ndk_ver _c
TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64"
TOOLBIN="$TOOLCHAIN/bin"
SYSROOT="$TOOLCHAIN/sysroot"

# --- compilers and binutils ---------------------------------------------------
CC="$TOOLBIN/armv7a-linux-androideabi${WRAPPER_API}-clang"
CXX="$TOOLBIN/armv7a-linux-androideabi${WRAPPER_API}-clang++"
AR="$TOOLBIN/llvm-ar"
RANLIB="$TOOLBIN/llvm-ranlib"
LD="$TOOLBIN/ld.lld"
STRIP="$TOOLBIN/llvm-strip"
OBJCOPY="$TOOLBIN/llvm-objcopy"
READELF="$TOOLBIN/llvm-readelf"
NM="$TOOLBIN/llvm-nm"
OBJDUMP="$TOOLBIN/llvm-objdump"
# (no AS/ASM assignment in the armv7a source; AS defaults to $CC is left to you)

# --- flags --------------------------------------------------------------------
PREFIX="${PREFIX:-${OUTPKG:-/usr/local}}"
# Unlike aarch64, armv7a passes the sysroot include to C++ too: CXXFLAGS=$CFLAGS here.
CFLAGS="-O2 -fPIC -DANDROID -I$PREFIX/include -isystem $SYSROOT/usr/include"
CXXFLAGS="$CFLAGS"
CPPFLAGS="$CPPFLAGS -I$PREFIX/include -isystem $SYSROOT/usr/include"
LDFLAGS="$LDFLAGS -L$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -lm -llog"
# Runtime path (per build-system driver):
#   make/autoconf: -Wl,-rpath,'$$ORIGIN' -Wl,-rpath,'$$ORIGIN/../lib' -Wl,-rpath,'$$ORIGIN/../lib64'
#   cmake/meson/cargo: -Wl,-rpath,'$ORIGIN'  -Wl,-rpath,'$ORIGIN/../lib'  -Wl,-rpath,'$ORIGIN/../lib64'

# --- pkg-config ---------------------------------------------------------------
PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:$SYSROOT/usr/lib/pkgconfig:$SYSROOT/usr/share/pkgconfig"
PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"

# --- autoconf cross probes ----------------------------------------------------
ac_cv_func_ffsl=yes
gl_cv_func_strcasecmp_works=yes

# --- triplets / arch ----------------------------------------------------------
BUILD_TRIPLET="x86_64-pc-linux-gnu"
HOST_TRIPLET="armv7a-linux-androideabi"
TARGET_TRIPLET="$HOST_TRIPLET"
HOST_ARCH="armv7a"
HOST_OS="android"

export NDK TOOLCHAIN TOOLBIN SYSROOT ANDROID_API WRAPPER_API PREFIX \
       CC CXX AR RANLIB LD STRIP OBJCOPY READELF NM OBJDUMP \
       CFLAGS CXXFLAGS CPPFLAGS LDFLAGS \
       PKG_CONFIG_LIBDIR PKG_CONFIG_PATH \
       ac_cv_func_ffsl gl_cv_func_strcasecmp_works \
       BUILD_TRIPLET HOST_TRIPLET TARGET_TRIPLET HOST_ARCH HOST_OS

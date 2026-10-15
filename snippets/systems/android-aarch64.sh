# snippets/systems/android-aarch64.sh
# Android / arm64-v8a (aarch64) cross-compilation environment.
#
# Triple:            aarch64-linux-android   (the *wrapper filename* carries the API)
# Target OS:         android  (Bionic libc)   Meson: system=android cpu_family=aarch64
# Tunable:           ANDROID_API (default 33)
# Required input:    ANDROID_HOME = an Android SDK that contains ndk/
#
# What the toolchain provides (NDK "unified" LLVM, no per-arch gcc):
#   clang/clang++ API wrappers, llvm-ar/ranlib/strip/objcopy/readelf/nm/objdump,
#   ld.lld, and the NDK sysroot (Bionic headers + per-API stub libs).
# What the platform provides: Bionic libc/libm/libdl, liblog, libc++/libc++abi,
#   and only these. Everything else (zlib, openssl, ...) you must build into $PREFIX.
# What it does NOT do: it never puts the cross toolchain on PATH (a cross binutils at
#   the front of PATH makes host tools run target binaries); every tool is a full path.
#
# Description + rationale: references/systems/android-aarch64.md
# Usage:   ANDROID_HOME=~/Android/Sdk . snippets/systems/android-aarch64.sh

: "${ANDROID_HOME:?set ANDROID_HOME to an Android SDK with an NDK}"
: "${ANDROID_API:=33}"

# Newest NDK under $ANDROID_HOME/ndk. Shell glob, not ls: aliases (eza) mangle ls.
_ndk_ver="$(for _c in "$ANDROID_HOME/ndk"/*; do
  [ -d "$_c" ] && printf '%s\n' "${_c##*/}"
done | sort -V | tail -1)"
if [ -z "$_ndk_ver" ]; then
  echo "android-aarch64: no NDK under $ANDROID_HOME/ndk" >&2
  unset _ndk_ver _c
  return 1 2>/dev/null || exit 1
fi
NDK="$ANDROID_HOME/ndk/$_ndk_ver"
unset _ndk_ver _c
TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64"
TOOLBIN="$TOOLCHAIN/bin"
SYSROOT="$TOOLCHAIN/sysroot"

# --- compilers and binutils (all LLVM, from the same bin/) --------------------
CC="$TOOLBIN/aarch64-linux-android${ANDROID_API}-clang"
CXX="$TOOLBIN/aarch64-linux-android${ANDROID_API}-clang++"
AR="$TOOLBIN/llvm-ar"
RANLIB="$TOOLBIN/llvm-ranlib"
LD="$TOOLBIN/ld.lld"
AS="$CC"
ASM="$CC"
STRIP="$TOOLBIN/llvm-strip"
OBJCOPY="$TOOLBIN/llvm-objcopy"
READELF="$TOOLBIN/llvm-readelf"
NM="$TOOLBIN/llvm-nm"
OBJDUMP="$TOOLBIN/llvm-objdump"

# --- flags --------------------------------------------------------------------
# $PREFIX is where your built dependencies landed.
PREFIX="${PREFIX:-${OUTPKG:-/usr/local}}"
# EPREFIX is the same fact under a different name in some toolchains; it is $PREFIX here.

# -DANDROID: Bionic code paths keyed on the macro.
# -isystem (not -I) so the NDK sysroot is searched after -I dirs: autoconf probes call
#   $CC -E and would otherwise find the NDK's own ancient zlib.h instead of yours.
#   Must stay C-ONLY: applied to C++ it reorders libc++ before its own C headers and
#   breaks <cstdint>. libc++ gets the sysroot via --sysroot from the wrapper.
CFLAGS="-O2 -fPIC -DANDROID -I$PREFIX/include -isystem $SYSROOT/usr/include"
CXXFLAGS="-O2 -fPIC -DANDROID -I$PREFIX/include"
# CPPFLAGS covers the $CC -E probes that run without $CFLAGS.
CPPFLAGS="$CPPFLAGS -I$PREFIX/include -isystem $SYSROOT/usr/include"

# -lm : Bionic keeps math in libm (glibc folds it into libc), so log2/pow/exp fail to
#       link without it; libm is in every sysroot, so it costs nothing.
# -llog: __android_log_write (abseil AndroidLogSink, glog AlsoErrorWrite); API 21+.
# -L$PREFIX/lib is required so -l<dep> resolves to what you built, not the sysroot stub.
LDFLAGS="$LDFLAGS -L$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -lm -llog"

# Runtime search path (added by every build-system driver; spelling of $ORIGIN depends
# on the tool). Three entries because the binary is in bin/ and its libs in lib/:
#   make/autoconf: -Wl,-rpath,'$$ORIGIN' -Wl,-rpath,'$$ORIGIN/../lib' -Wl,-rpath,'$$ORIGIN/../lib64'
#   cmake/meson/cargo: -Wl,-rpath,'$ORIGIN'  -Wl,-rpath,'$ORIGIN/../lib'  -Wl,-rpath,'$ORIGIN/../lib64'

# --- pkg-config ---------------------------------------------------------------
# $PREFIX first, then the NDK sysroot; host .pc files must not leak in.
PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:$SYSROOT/usr/lib/pkgconfig:$SYSROOT/usr/share/pkgconfig"
PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"

# --- autoconf cross probes (link-and-run cannot work cross) -------------------
# Bionic defines these as inline functions.
ac_cv_func_ffsl=yes
gl_cv_func_strcasecmp_works=yes

# --- triplets / arch (for autoconf --host and non-autoconf configure scripts) --
BUILD_TRIPLET="x86_64-pc-linux-gnu"
HOST_TRIPLET="aarch64-linux-android"
TARGET_TRIPLET="$HOST_TRIPLET"
HOST_ARCH="aarch64"
HOST_OS="android"

export NDK TOOLCHAIN TOOLBIN SYSROOT ANDROID_API PREFIX \
       CC CXX AR RANLIB LD AS ASM STRIP OBJCOPY READELF NM OBJDUMP \
       CFLAGS CXXFLAGS CPPFLAGS LDFLAGS \
       PKG_CONFIG_LIBDIR PKG_CONFIG_PATH \
       ac_cv_func_ffsl gl_cv_func_strcasecmp_works \
       BUILD_TRIPLET HOST_TRIPLET TARGET_TRIPLET HOST_ARCH HOST_OS

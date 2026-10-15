#!/bin/sh
# openssl 4.0.3 -- hand-written Configure + Makefile, NOT autoconf, and it needs
# $TOOLBIN on PATH for the Android target (a recipe-local exception to the rule that
# a cross toolchain is never put in front of PATH).
#
# Environment: $CC (the NDK wrapper), $TOOLBIN (the NDK toolchain bin/), $NDK,
# $ANDROID_API, $HOST_ARCH / $HOST_OS, $PREFIX, $CORES. $TOOLBIN must be defined for
# the Android recipe.
#
# WHY NO NDK PLUMBING IN THE NATIVE CASE
#   An android-* target WITHOUT the NDK does NOT fail loudly: android_ndk() in
#   Configurations/15-android.conf returns EARLY for any target name beginning with
#   "android", before it ever reads $ENV{ANDROID_NDK_ROOT}. So the build would run
#   against host headers with no sysroot and no API level -- silently wrong. That is
#   why the native path picks a native target and the android path is a separate
#   branch.
#
# THE ANDROID TRAP -- OPENSSL PROBES FOR ITS TOOLS BY NAME IN PATH.
#   Upstream's android-* config tests `which clang`, then `which <triple>-gcc`, and
#   dies without a flag to change that. Current NDKs ship neither a bare clang in
#   bin/ nor a triple-gcc wrapper. So this ONE build prepends $TOOLBIN to PATH. It is
#   a recipe-local exception: systems do not do this, and no other recipe may rely on
#   it. (The rest of the tree names every tool by full path precisely so a cross
#   toolchain never sits at the front of PATH.)
#
# WHAT IS DISABLED (identical on both targets)
#   no-shared no-tests no-docs no-engine no-dso no-dynamic-engine -- static-first,
#   and the test suite / docs are target programs and host tooling this build neither
#   wants nor can run. install_sw (not install) installs software only, skipping the
#   docs target.
#
# SIGNATURE OF A SILENT FAILURE: if you ever see the build proceed with an android-*
# target but no sysroot/API in the compile lines, android_ndk() returned early --
# your $NDK/$ANDROID_NDK_ROOT was empty.
set -eu

# Choose the target from the SYSTEM, not from a hardcoded name, so the recipe builds
# any Android/host target. The `*)` arm REFUSES rather than guessing.
case "$HOST_OS" in
  android)
    case "$HOST_ARCH" in
      aarch64) ssl_target=android-arm64 ;;
      armv7a)  ssl_target=android-arm ;;
      i686)    ssl_target=android-x86 ;;
      x86_64)  ssl_target=android-x86_64 ;;
      *) echo "openssl: unknown HOST_ARCH $HOST_ARCH" >&2; exit 1 ;;
    esac
    export ANDROID_NDK_ROOT="$NDK"
    PATH="$TOOLBIN:$PATH"; export PATH
    ./Configure "$ssl_target" -D__ANDROID_API__="$ANDROID_API" \
      --prefix="$PREFIX" --libdir=lib \
      no-shared no-tests no-docs no-engine no-dso no-dynamic-engine
    ;;
  linux)
    ./Configure linux-x86_64 --prefix="$PREFIX" --libdir=lib \
      no-shared no-tests no-docs no-engine no-dso no-dynamic-engine
    ;;
  mingw32)
    ./Configure mingw64 --prefix="$PREFIX" --libdir=lib \
      no-shared no-tests no-docs no-engine no-dso no-dynamic-engine
    ;;
  *)
    echo "openssl: unsupported HOST_OS $HOST_OS" >&2; exit 1 ;;
esac

make -j"$CORES"
make install_sw DESTDIR="$DESTDIR"

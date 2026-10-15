#!/bin/sh
# libvpx 1.15.0 -- its ./configure is HAND-WRITTEN (FFmpeg-style), NOT autoconf.
# That single fact drives every override below.
#
# Environment: as in xz.sh, plus $SYSROOT (the target sysroot) and $HOST_ARCH /
# $HOST_OS (the target, e.g. aarch64 / android) and $LDFLAGS, whose global
# content may carry -llog (see below).
#
# OVERRIDES AND WHY
#   No --host/--build        hand-written configure knows neither, so the driver's
#                            autotools flags do NOT apply and must be trimmed to the
#                            prefix. Passing them gives
#                                Unknown option "--host=aarch64-linux-android"
#                                See ./configure --help for available options.
#                            so:
#                                AUTOCONF_CONFIGURE_FLAGS="--prefix=$PREFIX"
#   --target=$vpx_arch       Android cannot be inferred from the build machine:
#                            a hand-written configure has no target guess. libvpx
#                            spells 64-bit ARM "arm64" and 32-bit x86 "x86"; every
#                            other arch is the system's own name.
#   --extra-cflags/--extra-cxxflags=--sysroot=$SYSROOT
#                            the sysroot goes in as a plain flag, NOT as -isystem:
#                            passed as -isystem it reorders libc++ before its own C
#                            headers and breaks <cstdint>. (-isystem is safe for C
#                            only, which is why the system's C-only -isystem stays
#                            out of the C++ path.)
#   --disable-examples/docs/unit-tests/tools
#                            all of these are target programs the host must not build
#                            or run.
#   --enable-static --disable-shared --enable-pic  static-first prefix.
#
# THE TRAP 1 -- --target is set in `pre`, AFTER the argument list is built.
#   A driver that expands a recipe's fields before the recipe's own shell runs will
#   expand --target=$vpx_arch before the case below has set it, and set -u reports
#   the name as unbound:
#       sh: line 1420: vpx_arch: unbound variable
#   So --target joins the argument list HERE, where the name exists. (ffmpeg's
#   --arch=$ffmpeg_arch is the same shape.)
#
# THE TRAP 2 -- libvpx's configure probes link with -static, and Bionic has liblog
#   only as a shared object, so the system's global -llog turns every probe into
#       ld.lld: error: unable to find library -llog
#       Toolchain is unable to link executables
#   The variable is rebuilt (not filtered in place) so the rest of the system's
#   flags survive untouched. LD="$CC" points the link at the compiler driver, not
#   a raw linker, so the probe links the way the target actually links.
set -eu

case "$HOST_ARCH" in
  aarch64) vpx_arch=arm64 ;;
  i686)    vpx_arch=x86 ;;
  *)       vpx_arch="$HOST_ARCH" ;;
esac

_ldflags=""
for _f in $LDFLAGS; do
  [ "$_f" = "-llog" ] || _ldflags="$_ldflags $_f"
done
LDFLAGS="${_ldflags# }"
unset _f _ldflags

LD="$CC"
export LD

# The hand-written configure takes only these; the autotools pair is dropped.
./configure \
  --prefix="$PREFIX" \
  --target="$vpx_arch-$HOST_OS-gcc" \
  --extra-cflags=--sysroot="$SYSROOT" \
  --extra-cxxflags=--sysroot="$SYSROOT" \
  --disable-examples --disable-docs --disable-unit-tests --disable-tools \
  --enable-pic --enable-static --disable-shared

make -j"$CORES"
make install DESTDIR="$DESTDIR"

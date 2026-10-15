#!/bin/sh
# ffmpeg (6.1.6 / 7.1.5 / 8.1.3 / 9.0.2 -- all branches share this shape).
# ffmpeg's ./configure is HAND-WRITTEN (libav family), NOT autoconf. It also
# IGNORES $CFLAGS/$LDFLAGS from the environment, so the system's flags have to be
# handed to it explicitly. Every branch below is one of the four parse traps.
#
# Environment: $CC/$CXX/$AR/$RANLIB/$STRIP, $CFLAGS (system), $HOST_ARCH/$HOST_OS,
# $PREFIX, $DESTDIR, $CORES, pkg-config search path already set by the closure.
#
# TRAP 1 -- no --host/--build.
#   The driver puts --host=$HOST_TRIPLET --build=$BUILD_TRIPLET into its autotools
#   flag string; ffmpeg stops at the first of them with
#       Unknown option "--host=aarch64-linux-android".
#       See ./configure --help for available options.
#   Trim the driver's flags to the install prefix (which ffmpeg does take) and pass
#   the toolchain through its own --cc/--cxx/--ar/--ranlib/--strip. Cross builds use
#   the explicit pair --enable-cross-compile with --target-os=$HOST_OS.
#
# TRAP 2 -- flag lists get word-split, and --extra-cflags must be handed over ONE
#   TOKEN AT A TIME.
#   --extra-cflags is on the parser's CMDLINE_APPEND list, so it accumulates. Passing
#   --extra-cflags=$CFLAGS (the system's CFLAGS is several words) reaches configure as
#   several arguments and the second word is rejected:
#       Unknown option "-fPIC".
#       See ./configure --help for available options.
#   So loop over $CFLAGS and emit one --extra-cflags= per word.
#
# TRAP 3 -- --extra-ldflags DOES NOT EXIST in ffmpeg's parser.
#   It is advertised in --help, but the name appears in neither CMDLINE_SET nor
#   CMDLINE_APPEND, so passing it is the same trap one word later:
#       Unknown option "--extra-ldflags=..."
#   Linker flags are therefore left to ffmpeg's own target rules -- a static-only
#   build links no program -- and dependencies are found through pkg-config, whose
#   search path the closure sets, via --pkg-config-flags=--static.
#
# TRAP 4 -- --arch is set in `pre`, AFTER the argument list is built.
#   Writing --arch=$ffmpeg_arch among the arguments expands it before the case below
#   has run; set -u reports an unbound name:
#       sh: line NN: ffmpeg_arch: unbound variable
#   (libvpx's --target=$vpx_arch is the same shape.) Join it to the list here.
#
# Also: assert make/install/targets/make_args/install_args. A driver that reads a
# field as "$field" (defaulting to whatever the PREVIOUS package left behind) will
# otherwise inherit make=false / install=false from a prior node that builds in its
# own post step, skip this build in silence, publish an empty prefix and exit 0.
set -eu

case "$HOST_ARCH" in
  armv7a) ffmpeg_arch=arm ;;
  i686)   ffmpeg_arch=x86 ;;
  *)      ffmpeg_arch="$HOST_ARCH" ;;
esac

# One --extra-cflags= per word, and nowhere to put linker flags.
_extra_cflags=""
for _f in $CFLAGS; do
  _extra_cflags="$_extra_cflags --extra-cflags=$_f"
done
unset _f

./configure \
  --prefix="$PREFIX" \
  --enable-cross-compile --target-os="$HOST_OS" --arch="$ffmpeg_arch" \
  --cc="$CC" --cxx="$CXX" --ar="$AR" --ranlib="$RANLIB" --strip="$STRIP" \
  --pkg-config-flags=--static \
  --enable-static --disable-shared \
  --disable-doc --disable-programs --disable-network --disable-iconv --disable-libxcb \
  --enable-zlib --enable-bzlib --enable-lzma \
  --enable-libopus --enable-libvpx --enable-libmp3lame \
  --enable-pic \
  $_extra_cflags

make -j"$CORES"
make install DESTDIR="$DESTDIR"

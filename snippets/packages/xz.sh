#!/bin/sh
# xz / liblzma 5.8.1 -- autoconf package, release tarball with generated
# configure + Makefile.in (no autotools needed at build time).
#
# Environment assumed (same for every snippet here): the toolchain is in
# $CC/$CXX/$AR/$RANLIB/$STRIP, the target is $HOST_TRIPLET (autoconf --host),
# the build machine is $BUILD_TRIPLET (--build), configure installs under
# $PREFIX, $DESTDIR is the staging root the install is redirected into, and
# $CORES is the job count.
#
# OVERRIDES AND WHY
#   --disable-nls       no gettext in the target prefix; xz's own is off by name.
#   --disable-shared    policy: this prefix is static-first; liblzma's shared
#                       object is not load-bearing, all five consumers link the
#                       archive through pkg-config. (libtool builds both by
#                       default, so the flag has to be said out loud.)
#   --disable-unxz/lzmadec/lzmainfo/lzlinks/scripts/doc
#                       the optional tooling and the man pages are not part of
#                       what a consumer of liblzma reads, and doc wants a host
#                       toolchain.
#
# THE TRAP (this is the one that costs an hour)
#   install_args must carry DESTDIR *on the command line*:
#       make install DESTDIR="$DESTDIR"
#   xz's installed automake Makefile *assigns* DESTDIR itself (DESTDIR = ...),
#   and a Makefile variable beats the environment. A DESTDIR exported in the
#   environment NEVER reaches this install: make install wrote straight into
#   the published $PREFIX, nothing was staged, and the publish step then died
#   with a missing staging path, i.e.
#       sh: line 50: <stage>/.../store/<hash>/../.relax-list: No such file or directory
#   A command-line assignment outranks the Makefile. help2man and openssl carry
#   the same line for the same reason (both generate a Makefile that sets DESTDIR).
#   SIGNATURE: it only shows on a REBUILD -- a fresh entry is skipped, so the bad
#   install path is never exercised the first time. Test path changes on a rebuild.
#
#   The touch loop guards the other automake trap: a release tarball unpacks with
#   mtimes older than the shipped configure/Makefile.in, so make would try to
#   regenerate them with autotools -- which these systems deliberately do not have.
set -eu

./configure \
  --host="$HOST_TRIPLET" --build="$BUILD_TRIPLET" --prefix="$PREFIX" \
  --disable-nls --disable-shared \
  --disable-unxz --disable-lzmadec --disable-lzmainfo --disable-lzlinks \
  --disable-scripts --disable-doc

# Keep the shipped autotools files newer than everything that depends on them.
for _f in aclocal.m4 configure config.h.in; do
  [ -f "$_f" ] && touch "$_f"
done
find . -name 'Makefile.in' -exec touch {} + 2>/dev/null || true
unset _f

make -j"$CORES"

# DESTDIR on the command line -- see the trap above.
make install DESTDIR="$DESTDIR"

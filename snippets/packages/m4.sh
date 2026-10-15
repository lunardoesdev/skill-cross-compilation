#!/bin/sh
# m4 1.4.20 -- GNU m4, an autoconf build that must NOT run its own target binary
# during the build. The trap is order of the doc/version steps and the man page.
#
# Environment: as in xz.sh.
#
# THE TRAP -- regenerating the shipped man page would RUN the Android m4 binary.
#   m4's build regenerates doc/m4.1 (and the info file) from the just-built m4
#   program. That program is a TARGET binary; running it on the build host is
#   emulation, which is never done. The shipped man page and info are already in the
#   tarball, so TOUCH them to make them newer than their inputs and keep them as-is:
#       touch doc/m4.1 doc/m4.info*
#   The explicit sub-make order below (lib, src, .version, -C doc version.texi, then
#   touch, then the real `make`) is what produces the version stamp before the doc
#   step without ever executing a target binary.
set -eu

./configure \
  --host="$HOST_TRIPLET" --build="$BUILD_TRIPLET" --prefix="$PREFIX"

# Build in the order m4 expects, producing the version stamp without running m4.
make -j"$CORES" -C lib
make -j"$CORES" -C src
make -j"$CORES" .version
make -j"$CORES" -C doc version.texi

# Keep the SHIPPED man page and info; regenerating them would run the target m4.
touch doc/m4.1 doc/m4.info*

make -j"$CORES"
make install DESTDIR="$DESTDIR"

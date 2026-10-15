#!/bin/sh
# gmp 6.3.0 -- the bignum library nettle and gnutls build on. Release tarball
# ships a generated configure (no autotools needed at build time).
#
# Environment: as in xz.sh ($CC/$CXX/$AR/$RANLIB, --host/--build triplets,
# $PREFIX, $DESTDIR, $CORES).
#
# OVERRIDES AND WHY
#   --enable-cxx   build the C++ interface too (mpz_class...); cheap, and a
#                  consumer may link it.
#   --disable-static
#                  GMP's default is BOTH static and shared, and a shared build is
#                  what its ABI test/relink machinery expects; a static-only GMP
#                  is awkward across the C/C++ split. (This is a deliberate
#                  departure from an otherwise static-first prefix.)
#   install-html   the manual is a separate target in GMP, off `all`; run it in a
#                  post step so the doc lands with the install. No --docdir is
#                  pinned: upstream's default already lands under the prefix, and a
#                  hardcoded version in --docdir would go stale on a bump.
#
# THE TRAP
#   GMP's configure runs `config.guess`-style probes and, on a cross build, needs a
#   real toolchain -- the driver's --host/--build pair is what keeps it from
#   building for the host machine. If you drop them, GMP configures for the build
#   host and every consumer gets a host-arch libgmp: no error at build time, a link
#   failure later. Keep the triplets.
set -eu

./configure \
  --host="$HOST_TRIPLET" --build="$BUILD_TRIPLET" --prefix="$PREFIX" \
  --enable-cxx --disable-static

make -j"$CORES"
# DESTDIR on the command line: gmp's generated Makefile assigns DESTDIR too.
make install DESTDIR="$DESTDIR"

# The HTML manual is its own target, not part of `all`.
make -j"$CORES" install-html DESTDIR="$DESTDIR"

#!/bin/sh
# nettle 3.10.2 -- libnettle + libhogweed (public-key on top of GMP). Release
# tarball ships a generated configure, Makefile.in and config.h.in (the config
# template is the SINGULAR top-level config.h.in; configure.ac:11 is
# AC_CONFIG_HEADER([config.h])).
#
# Environment: as in xz.sh. Depends on gmp (found through the prefix's pkg-config
# path).
#
# OVERRIDES AND WHY
#   --disable-mini-gmp       nettle bundles a small GMP shim and uses it by
#                            default. The real GMP is already in the prefix,
#                            discovered via pkg-config; disable the shim so the
#                            backend is the real library and not a silent fallback.
#   --disable-documentation  drops the texinfo manual, which would otherwise want
#                            makeinfo/sgml on the host.
#   --enable-public-key      ON by default; it is nettle's own code, no external
#                            library, so it is left alone (stated for clarity).
#
# THE TRAP -- a flag that does not exist is worse than no flag.
#   nettle's configure.ac:60-62 declares AC_ARG_ENABLE(pic, [--disable-pic], ...)
#   with enable_pic=yes -- PIC is ON by default and the ONLY spelling is the
#   negative one. Do NOT pass --with-pic or --enable-pic: they are not nettle
#   options at all, and configure accepts an unknown option SILENTLY --
#       WARNING: unrecognized options: --with-pic
#   -- then carries on. The recipe looks deliberate and is not; you believe you
#   turned PIC on when it was already on and you said nothing.
#   (libtasn1 does take --with-pic; nettle does not. Do not copy the flag across.)
set -eu

./configure \
  --host="$HOST_TRIPLET" --build="$BUILD_TRIPLET" --prefix="$PREFIX" \
  --disable-shared --enable-static \
  --disable-mini-gmp --disable-documentation

make -j"$CORES"
make install DESTDIR="$DESTDIR"

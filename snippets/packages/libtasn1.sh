#!/bin/sh
# libtasn1 4.21.0 -- turns DER/BER into a tree; libtasn1.a + libtasn1.h + libtasn1.pc
# (module LIBTASN1, what gnutls' PKG_CHECK_MODULES reads). Release tarball ships a
# generated configure and the GENERATED PARSER lib/ASN1.c -- load-bearing, because
# these systems carry no autotools and no bison.
#
# Environment: as in xz.sh.
#
# OVERRIDES AND WHY
#   --enable-static --disable-shared --with-pic
#                            static-first: a cross target prefix has no loader
#                            path we control, and the archive is meant to be linked
#                            into a shared library later. (LT_INIT's default is
#                            both, so --disable-shared has to be said out loud.
#                            NOTE --with-pic is valid HERE, unlike nettle.)
#   --disable-doc            the ENABLE_DOC conditional gates `SUBDIRS += doc
#                            examples` -- and examples/ holds more target programs,
#                            so this is not only about the manual.
#   -C lib                   THERE IS NO SWITCH FOR THE TOOLS. Upstream builds
#                            src/ (bin_PROGRAMS = asn1Parser asn1Coding asn1Decoding),
#                            which are target programs this host cannot run. Name
#                            the library subdirectory instead: `make -C lib` builds
#                            lib/ and its own lib/gl and installs exactly what a
#                            consumer reads (lib_LTLIBRARIES, include_HEADERS,
#                            pkgconfig_DATA in lib/Makefile.am).
#
# WHY IT STILL PARSE-BUILDS WITHOUT A YACC
#   ASN1.c and ASN1.y carry the same mtime in the tarball, so make never calls
#   $(YACC) -- do not perturb mtimes with an unguarded copy. tests/ and fuzz/ stay
#   in SUBDIRS but build nothing under `all` (check_PROGRAMS / noinst_PROGRAMS behind
#   the off-by-default FUZZING conditional). Never run `make check`.
set -eu

./configure \
  --host="$HOST_TRIPLET" --build="$BUILD_TRIPLET" --prefix="$PREFIX" \
  --enable-static --disable-shared --with-pic --disable-doc

make -j"$CORES" -C lib
make -C lib install DESTDIR="$DESTDIR"

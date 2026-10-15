#!/bin/sh
# leptonica 1.87.0 -- the image-processing library tesseract needs. Release tarball
# (GitHub release ASSET, a real `make dist` output) ships a generated configure and
# the m4/libtool set, so no autotools at build time.
# Installs Libleptonica.a, the leptonica/*.h set and lib/pkgconfig/lept.pc -- module
# name is "lept" (what tesseract's pkg-config check looks up).
#
# Environment: as in xz.sh. Depends on zlib, libpng, libjpeg-turbo, giflib, libtiff,
# libwebp, openjpeg (the closure).
#
# OVERRIDES AND WHY
#   --enable-static --disable-shared --with-pic
#                            static-first; the archive is meant to be linked into a
#                            shared library later.
#   --disable-programs       gates ENABLE_PROGRAMS (configure.ac:32-33); prog/Makefile.am
#                            puts bin_PROGRAMS (convertformat, fileinfo, imagetops,
#                            xtractprotos, ...) and the *_reg regression programs behind
#                            it, so `make`/`make install` reach src/ only.
#   --with-zlib/libpng/jpeg/giflib/libtiff/libwebp/libopenjpeg
#                            ASK FOR EACH FORMAT BY NAME. Left to configure's "check"
#                            default, a missing library is silently skipped and the
#                            build "succeeds" reading fewer formats. By name, a miss
#                            is a hard configure error:
#                                "zlib support requested but ... not found"
#   --without-libwebpmux      this tree's libwebp is built with
#                            -DWEBP_BUILD_LIBWEBPMUX=OFF, so there is no libwebpmux;
#                            leptonica then compiles webpanimiostub.c instead of the
#                            animation reader webpanimio.c. Nothing is invented -- no
#                            format library is declared that the tree does not have.
#
# NO SWITCH NEEDED for fuzzers/tests/doc: they are off the default target.
#   fuzzers  Makefile.am:63-68 -- `fuzzers: $(FUZZERS)` is its own phony target; the
#            -fsanitize=fuzzer link never runs during `make`. No configure option at all.
#   tests    prog/Makefile.am:130-131 -- check_PROGRAMS only `make check` builds.
#   doc      doc/ is not in SUBDIRS; the Doxyfile is only used by `doc`, which needs
#            doxygen.
#
# THE ONE TARGET-BINARY PATH -- do NOT invoke it. src/Makefile.am:91-92: the
# `allheaders` target builds prog/xtractprotos and RUNS it to regenerate
# src/allheaders.h. It is a standalone target, not a prerequisite of `all`. The
# generated src/allheaders.h and src/alltypes.h ship in the tarball as
# pkginclude_HEADERS, so the installed header set is complete without it. Never run
# `make allheaders`.
#
# Nothing here differs for Android: the driver passes --host and the system's CFLAGS
# carry -DANDROID; configure's library checks are compile/link tests, never runs.
set -eu

./configure \
  --host="$HOST_TRIPLET" --build="$BUILD_TRIPLET" --prefix="$PREFIX" \
  --enable-static --disable-shared --with-pic --disable-programs \
  --with-zlib --with-libpng --with-jpeg --with-giflib --with-libtiff \
  --with-libwebp --without-libwebpmux --with-libopenjpeg

make -j"$CORES"
make install DESTDIR="$DESTDIR"

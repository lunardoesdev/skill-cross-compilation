#!/bin/sh
# tesseract 5.5.3 -- NOT FINISHED in this tree. This file records what is known and
# what is still open; the code below is the intended shape, not a verified recipe.
#
# WHY IT IS HARD
#   tesseract publishes NO dist tarball. Its GitHub release object for 5.5.3 carries
#   a single asset (the Windows installer), and the tag archive is a PLAIN git
#   archive: it ships autogen.sh, configure.ac, Makefile.am and m4/ but NO generated
#   ./configure, NO aclocal.m4, NO Makefile.in, NO pkg.m4. So unlike every other
#   autoconf package here (whose release tarball carries a generated configure),
#   tesseract's configure has to be GENERATED -- by running upstream's own autogen.sh
#   -- which means the autotools must be present as NATIVE dependencies of the build
#   (a code generator/build tool comes from the native system, never the target).
#
#   Two submodules the archive leaves EMPTY -- test/ and
#   unittest/third_party/googletest -- belong to `make check`, which this package
#   never runs; neither is a build input of the library, so neither is fetched. Same
#   story for the langdata_lstm / tessdata trees the test programs would want.
#
# WHAT IT NEEDS
#   leptonica (pkg-config module "lept") and leptonica's own dependency closure,
#   found through the closure's pkg-config path.
#
# OPEN / UNVERIFIED
#   * whether upstream autogen.sh produces a configure that survives a cross build
#     without further patching (autoreconf's own probes and any pkg.m4 it needs);
#   * the exact tesseract-side --disable-* set for tools/training programs
#     (tesseract's build has target binaries the host must not run) -- not settled;
#   * whether the generated configure's checks that RUN a program exist and need
#     ac_cv_* overrides, as other autoconf packages here sometimes do.
#   Until those are answered this package is a source node with no working build
#   recipe; the block below is the intended approach.
set -eu

# The tag archive ships sources only: generate the configure with upstream's script.
# The autotools (autoconf/automake/libtool, and pkg-config macros) must be NATIVE
# dependencies of the build step -- they run on the build host.
./autogen.sh

./configure \
  --host="$HOST_TRIPLET" --build="$BUILD_TRIPLET" --prefix="$PREFIX" \
  --enable-static --disable-shared --with-pic \
  --disable-doc
  # --disable-* for tesseract's target programs: NOT YET SETTLED (see OPEN above).

make -j"$CORES"
make install DESTDIR="$DESTDIR"

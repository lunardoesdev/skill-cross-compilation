#!/bin/sh
# bzip2 1.0.8 -- a bare hand-written Makefile, NO configure, NO DESTDIR SUPPORT.
# That one fact drives everything below.
#
# Environment: $CC/$AR/$RANLIB (a bare Makefile says CC=gcc and IGNORES the
# environment, so the toolchain must be passed as command-line ARGUMENTS),
# $CFLAGS/$LDFLAGS, $PREFIX, $CORES. Note $PREFIX here is the *staged* destination
# (see below) -- not the published one.
#
# TRAP 1 -- the default target runs tests.
#   `make` in bzip2 builds and RUNS a test suite of target binaries, which cannot run
#   on the build host. Name the two products explicitly instead:
#       make ... bzip2 bzip2recover
#
# TRAP 2 -- the install hardcodes bare names and there is no EXEEXT variable.
#   On a PE target the link steps (Makefile:41,44 `-o bzip2`) produce bzip2.exe and
#   bzip2recover.exe, but `install` hardcodes the bare names (`cp -f bzip2 ...`,
#   :77-80) and this Makefile has no EXEEXT to set. So install dies with
#       cannot stat 'bzip2'
#   The fix is branch-CONDITIONAL: copy the suffixed name onto the bare name only
#   WHEN IT EXISTS. An unconditional copy is what once broke every non-mingw build
#       cp: cannot stat 'bzip2.exe': No such file or directory
#   (an ELF link written as `-o bzip2` produces bzip2, no bzip2.exe beside it).
#
# TRAP 3 -- there is no DESTDIR at all.
#   bzip2's install rule copies into $(PREFIX)/bin, /lib, /man, /include itself; the
#   PREFIX you pass IS the destination a copy is written to. Pass the STAGED prefix
#   (the stage root, not the published one). Handing it the published $PREFIX wrote
#   straight into the live tree, nothing was staged, and the publish step then died
#   with a missing staging path:
#       sh: line 50: <stage>/.../store/<hash>/../.relax-list: No such file or directory
#   (publishing then rm -rf'd the entry and mkdir'd it empty). DESTDIR is exported
#   and bzip2 ignores it entirely -- that is exactly why the path must be right in
#   the argument. Here $STAGE_PREFIX is stage-root-prefixed by the caller.
set -eu

# Build the two products directly (no tests).
make -j"$CORES" CC="$CC" AR="$AR" RANLIB="$RANLIB" \
  CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" bzip2 bzip2recover

# Only a PE target appends .exe -- copy onto the bare name only if it is there.
for _b in bzip2 bzip2recover; do
  [ -f "$_b.exe" ] && cp "$_b.exe" "$_b"
done
unset _b

# $STAGE_PREFIX is the staged destination (stage root + PREFIX); bzip2 has no DESTDIR.
make -j"$CORES" CC="$CC" AR="$AR" RANLIB="$RANLIB" \
  CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" PREFIX="$STAGE_PREFIX" install

#!/bin/sh
# ncurses 6.6 -- autoconf. Deliberately a SHARED, wide-char-only build, and the
# un-suffixed link names are aliased afterwards.
#
# Environment: as in xz.sh.
#
# OVERRIDES AND WHY -- this is a deliberate departure from a static-first prefix.
#   --with-shared          SHARED on purpose: ncurses' tic/infocmp and the
#                          wide-character ABI are awkward to build static-only.
#                          (There is no --with-static companion.)
#   --without-normal       build ONLY the wide-character (w) variants -- half the
#                          artifact set. The un-suffixed names (curses, form, menu,
#                          panel) are then missing, and consumers in this tree link
#                          exactly those, so the aliases below restore them.
#   --with-cxx-shared      the C++ bindings, shared to match.
#   --enable-pc-files --with-pkg-config-libdir=$PREFIX/lib/pkgconfig
#                          emit .pc files; the wide-char .pc files still describe
#                          the wide-char libraries, hence the .pc aliases below.
#   --disable-stripping    do not strip during install (the strip step needs a
#                          target strip and can fail or corrupt across a cross build).
#
# NOTE the asymmetry: the recipe carries ONLY the wide-char libraries. The .so
# symlink aliases and the .pc symlink aliases below are what make the traditional
# names resolve. Skip them and a consumer's -lcurses / pkg-config ncurses fails with
# a missing library / missing .pc, even though the build "succeeded".
set -eu

./configure \
  --host="$HOST_TRIPLET" --build="$BUILD_TRIPLET" --prefix="$PREFIX" \
  --with-shared --without-debug --without-normal --with-cxx-shared \
  --enable-pc-files --with-pkg-config-libdir="$PREFIX/lib/pkgconfig" \
  --disable-stripping

make -j"$CORES"
make install DESTDIR="$DESTDIR"

# Traditional link names -> the wide-char libraries ncurses actually built.
ln -sf libncursesw.so "$PREFIX/lib/libcurses.so"
ln -sf libncursesw.so "$PREFIX/lib/libncurses.so"
ln -sf libformw.so    "$PREFIX/lib/libform.so"
ln -sf libmenuw.so    "$PREFIX/lib/libmenu.so"
ln -sf libpanelw.so   "$PREFIX/lib/libpanel.so"
ln -sf ncursesw.pc "$PREFIX/lib/pkgconfig/ncurses.pc"
ln -sf formw.pc    "$PREFIX/lib/pkgconfig/form.pc"
ln -sf menuw.pc    "$PREFIX/lib/pkgconfig/menu.pc"
ln -sf panelw.pc   "$PREFIX/lib/pkgconfig/panel.pc"

#!/bin/sh
# gnutls 3.8.13 -- the TLS library. Release tarball ships a generated configure
# (autoconf 2.72) with aclocal.m4, every Makefile.in and the gnulib copies under
# gl/, po/ and lib/unistring, so no autotools is needed at build time.
# Depends on gmp, nettle, libtasn1, zlib (all in the same prefix/system closure).
#
# Environment: as in xz.sh; the closure supplies include/lib dirs and .pc files.
#
# OVERRIDES AND WHY -- every line names a dependency this tree does not have, or a
# program the host cannot run. Read from `configure --help` of 3.8.13, not guessed:
#   --without-p11-kit         NOT optional in the useful sense: configure.ac:929-951
#                             runs PKG_CHECK_MODULES(p11-kit-1) unless the flag is
#                             given; with nothing to find it calls AC_MSG_ERROR --
#                                 "p11-kit >= 0.23.1 was not found"
#                             so WITHOUT this line configure cannot finish at all.
#   --without-tpm2            tpm2-tss absent. Default `yes` + no dlopen in a cross
#                             build means `link` and a pkg-config probe for
#                             tss2-esys/tss2-mu, which fails.
#   --without-tpm             the older trousers TPM, also absent.
#   --disable-libdane         libdane needs libunbound (absent); configure.ac:856-884
#                             turns it off itself after a failed link test -- this
#                             states it instead of relying on that.
#   --without-idn             libidn2/libunistring IDNA; libidn2 absent.
#   --without-brotli/--without-zstd
#                             want ONE decompression backend, not three. zlib is
#                             kept (configure wants it by default and the tree has
#                             it); letting brotli/zstd fall back silently is how a
#                             build "succeeds" with compression missing.
#   --with-included-unistring THE one dependency that cannot be switched off: with
#                             no libunistring, configure.ac:522-532 fails with
#                                 "Libunistring was not found. To use the included
#                                  one, use --with-included-unistring"
#                             so use gnutls' bundled copy (lib/unistring) -- a copy
#                             inside the package, not a host library.
#   --without-included-libtasn1
#                             the same choice the other way: use this tree's
#                             libtasn1 (>= 4.9) rather than the bundled minitasn1.
#   --disable-srp-authentication / --disable-openssl-compatibility
#                             enable-style options whose default is already no;
#                             stated so intent lives in the file, not a default.
#   --disable-nls             no gettext at build time (po/ is in SUBDIRS
#                             unconditionally, AM_GNU_GETTEXT([external])).
#   --disable-tools           drops src/ from SUBDIRS (Makefile.am:29-33): certtool,
#                             gnutls-cli, gnutls-serv, ocsptool, psk-tool -- and
#                             with them the cligen generator that writes their arg
#                             tables with python.
#   --disable-tests           drops `tests fuzz` (Makefile.am:35-37): target programs,
#                             and the extended suite wants python and libev.
#   --disable-doc             drops doc/ and doc/manpages (Makefile.am:39-45).
#   --enable-static --disable-shared
#                             REQUIRED, not default: gnutls' configure is
#                             LT_INIT([disable-static,win32-dll,shared])
#                             (configure.ac:660) -- the default is a SHARED library
#                             and NO archive at all. Say it out loud or you get .so.
#
# WHAT IS LEFT: gl/ lib/ extra/ po/, libraries only. The one place gnutls' own build
# would RUN a target binary is inside `if ENABLE_FIPS140` (lib/Makefile.am:266-281),
# a noinst_PROGRAMS fipshmac with an all-local rule that runs it. FIPS140 is off by
# default; never pass --enable-fips140-mode.
#
# Nothing here is Android-specific: the driver passes --host=$HOST_TRIPLET and the
# system's CFLAGS carry -DANDROID; gnutls' configure already knows the platform
# (configure.ac:203-215 sets have_android/have_elf for an *android* host) and its
# probes are compile/link tests, never runs. So there is one recipe, no per-system copy.
set -eu

./configure \
  --host="$HOST_TRIPLET" --build="$BUILD_TRIPLET" --prefix="$PREFIX" \
  --enable-static --disable-shared \
  --disable-tools --disable-tests --disable-doc --disable-nls \
  --without-p11-kit --without-tpm2 --without-tpm --disable-libdane \
  --without-idn --without-brotli --without-zstd \
  --with-included-unistring --without-included-libtasn1 \
  --disable-srp-authentication --disable-openssl-compatibility

make -j"$CORES"
make install DESTDIR="$DESTDIR"

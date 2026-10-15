#!/bin/sh
# help2man 1.49.3 -- a BUILD TOOL, not a target library. It turns a program's
# --help output into a man page; texinfo's build runs it (its Makefile.am builds
# man/makeinfo.1 with a $(HELP2MAN) rule). Release tarball ships generated
# configure + Makefile.in, so no autotools is needed.
#
# Environment: as in xz.sh, plus $NATIVE_PERL -- the *native* perl this build
# must RUN. It is not a convenience: help2man.PL is expanded into bin/help2man
# by @PERL@, and the installed script keeps that interpreter in its shebang, so
# the same perl has to exist at build time and at run time. Cross-compiled tools
# cannot run on the build host -- a code generator or help2man is always a native
# package, and its path is spelled into the recipe that runs it.
#
# OVERRIDES AND WHY
#   --disable-nls   with NLS on, configure.ac wants the perl module Locale::gettext,
#                   MSGFMT, dlsym and bindtextdomain, and sets extra_make_all to
#                   'preload man_l10n info_l10n' -- the build would run msgfmt on the
#                   translations and compile a preload shim. help2man is a build tool
#                   here, its own localised man pages are of no use, and this tree has
#                   no gettext that builds. The flag keeps the dependency out instead
#                   of quietly taking the host's msgfmt.
#   PERL=$NATIVE_PERL
#                   named explicitly because this build RUNS the interpreter it bakes
#                   into the installed script. Resolved from PATH, the shebang came
#                   out as the host's /usr/bin/perl -- the machine fact the @native
#                   dependency exists to keep out of a cross build.
#
# THE TRAP
#   install_args must carry DESTDIR on the command line:
#       make install DESTDIR="$DESTDIR"
#   help2man's Makefile.in defines `DESTDIR =` itself and a Makefile variable beats
#   the environment, so a DESTDIR from the environment installed straight into the
#   published $PREFIX and the publish step reported
#       sh: line 50: <stage>/.../store/<hash>/../.relax-list: No such file or directory
#   (openssl's generated Makefile has the same shape.)
#
#   The touches keep the SHIPPED manual instead of rebuilding it. help2man.1 and
#   help2man.info both ship in the tarball and install_base installs them as they
#   are; but `all` depends on `man` and `info`, and neither a cp -r copy nor the
#   copy into the work directory preserves mtimes, so help2man.PL can land newer
#   than the manual and make would rebuild it -- for `info` that means makeinfo,
#   the very program this package exists to help build. Touch newest last (info
#   first, then the man page) so nothing they depend on stays newer than they are.
set -eu

for _f in help2man.info help2man.1; do
  [ -f "$_f" ] && touch "$_f"
done
unset _f

./configure \
  --host="$HOST_TRIPLET" --build="$BUILD_TRIPLET" --prefix="$PREFIX" \
  --disable-nls PERL="$NATIVE_PERL"

make -j"$CORES"

# DESTDIR on the command line -- see the trap above.
make install DESTDIR="$DESTDIR"

# autoconf

`./configure` + `make` + `make install` for Autotools projects (autoconf, automake,
libtool). The driver owns the configure triplet, the rpath and the prefix; the recipe
owns only extra `./configure` arguments, the make targets, the install arguments, and
the `make`/`install` toggles (`system@aarch64-android33/autoconf.toml:1-4`,
`docs/recipes.md:78`).

## The cross skeleton

```sh
# --- driver-owned, from the system ---
# cross:  --host=$HOST_TRIPLET --build=$BUILD_TRIPLET --prefix=$OUTPKG
# native: --build=$BUILD_TRIPLET --prefix=$OUTPKG   (no --host; build==host==target)
AUTOCONF_CONFIGURE_FLAGS="--host=$HOST_TRIPLET --build=$BUILD_TRIPLET --prefix=$OUTPKG"

LDFLAGS="$LDFLAGS -Wl,-rpath,'\$\$ORIGIN' -Wl,-rpath,'\$\$ORIGIN/../lib' -Wl,-rpath,'\$\$ORIGIN/../lib64'"
cd "${BS_source_dir:-.}"

./configure $AUTOCONF_CONFIGURE_FLAGS $BS_configure_args

# freeze the Autotools inputs so make does not try to regenerate them
for _f in aclocal.m4 configure config.h.in; do
  [ -f "$_f" ] && touch "$_f"
done
find . -name 'Makefile.in' -exec touch {} + 2>/dev/null || true

if [ "$BS_make" != "false" ]; then
  make -j"$CORES" $BS_make_args $BS_targets
fi
if [ "$BS_install" != "false" ]; then
  make $BS_install_args install
fi
```

`$HOST_TRIPLET`/`$BUILD_TRIPLET` are the two Autoools triples: **build** is the machine
running the build, **host** is the machine the artifacts run on
(`system@aarch64-android33/system.toml:81-88`). There is no separate `--target`: no
compiler is built for a further machine, so target == host
(`system@aarch64-android33/system.toml:85`).

## Required variables and flags

- `CC`, `CXX`, `AR`, `RANLIB`, `STRIP` — full paths into the cross toolchain; the
  toolchain is deliberately kept off `PATH` (`system@aarch64-android33/system.toml:20-41`).
  Autotools pick these up from the environment.
- `--host=$HOST_TRIPLET --build=$BUILD_TRIPLET` — without `--host` configure builds for
  the build machine.
- `--prefix=$OUTPKG` — the **final** path, so the staged tree names itself correctly
  (`docs/recipes.md:178-182`).
- `CFLAGS`/`CXXFLAGS` — carry `-O2 -fPIC` and any platform define (e.g. `-DANDROID`)
  (`system@aarch64-android33/system.toml:49-50,71`).
- `CPPFLAGS` — covers the Autoconf probes that call `$CC -E` **without** `$CFLAGS`
  (libpng's zlib check, `pnglibconf.h` generation). Put the dependency prefix first,
  or those probes find an old header in the sysroot instead of the one just built
  (`system@aarch64-android33/system.toml:42-45`).
- `LDFLAGS` — the `$ORIGIN` triple above, plus any always-cost-nothing libs the
  platform needs (Bionic keeps math in `libm` and logging in `liblog`, so `-lm -llog`
  saves every package from a link failure, `system@aarch64-android33/system.toml:72-78`).
- Cache variables for probes that link and run a target program:
  `ac_cv_func_ffsl=yes`, `gl_cv_func_strcasecmp_works=yes`
  (`system@aarch64-android33/system.toml:60-63`).

## Install and staging — where it breaks

`automake`'s installed `Makefile` **assigns `DESTDIR` itself** (`DESTDIR =`, e.g.
`help2man`'s `Makefile.in:29`). An exported `DESTDIR` therefore never reaches the
install; a Makefile variable outranks the environment. `make install` then writes
straight into `$OUTPKG`, nothing is staged, and publication reports:

```
sh: line 50: <stage>/.../store/<hash>/../.relax-list: No such file or directory
```

Fix: carry `DESTDIR` as a **command-line assignment**, which outranks the makefile.
This is expressed as the recipe's `install_args`:

```toml
install_args = "DESTDIR=$DESTDIR"
```

(`xz/generic.toml:19-28`, `help2man/generic.toml:49-58`). The install line is
`make $BS_install_args install`, so `install_args` must sit **after** `make` and
before the target.

The defect is invisible on a first build: a fresh entry is skipped, so it only shows
on a rebuild (`xz/generic.toml:27-28`).

## Dependency discovery

- **`pkg-config`** for library deps: the closure puts each dependency's `.pc`
  directory into `$PKG_CONFIG_LIBDIR` (`system@aarch64-android33/system.toml:57-59`),
  and `PKG_CONFIG_PATH` is kept to the build's own prefix so host `.pc` files outside
  those dirs are ignored (`system@aarch64-android33/system.toml:79-80`,
  `docs/recipes.md:59-61`).
- **`--static`** when only an archive is installed: `PKG_CONFIG` should be asked for
  static link lines, or the `.pc`'s private deps are dropped
  (ffmpeg uses `--pkg-config-flags=--static`, `ffmpeg-9/generic.toml:9`).
- Autotools' own `PKG_CHECK_MODULES` reads the same environment, so nothing extra is
  needed beyond `PKG_CONFIG_LIBDIR`.
- Turn off stages that would need a tool the prefix does not carry, rather than
  silently taking the host's: `--disable-nls` keeps gettext/`msgfmt` out
  (`help2man/generic.toml:14-21`), `--disable-tools/--disable-tests/--disable-doc`
  drop programs the host must not run (`gnutls/generic.toml:53-64`).

## Known pitfalls

| symptom in the log | cause | fix |
| --- | --- | --- |
| `make` tries to re-run `aclocal`/`automake`/`autoconf`; `command not found` | a release tarball unpacks with mtimes older than the shipped `configure`/`Makefile.in`, so make regenerates them — and autotools is not installed, because building from a release tarball must not need it (`autoconf.toml:6-9`) | `touch aclocal.m4 configure config.h.in` and every `Makefile.in` before `make` (`autoconf.toml:16-19`) |
| install wrote into the published path; `.../.relax-list: No such file or directory` | the Makefile assigns `DESTDIR` itself and beats the exported one (`help2man/generic.toml:49-58`) | `install_args = "DESTDIR=$DESTDIR"` — a command-line assignment (`xz/generic.toml:19-28`) |
| `Unknown option "--host=aarch64-linux-android"` | the project's `configure` is **hand-written** (FFmpeg/libvpx-style), not autoconf, and knows no `--host`/`--build` (`libvpx/android.toml:27-31`, `ffmpeg-9/generic.toml:11-18`) | trim `AUTOCONF_CONFIGURE_FLAGS` to `--prefix=...` and pass the toolchain the project's way (`--target-os`, `--arch`, `--cc`, `--cxx`, `--ar`, `--ranlib`, `--strip`) |
| `Unknown option "-fPIC"` (the *second word* of a flag) | a list field is expanded unquoted, so an element that holds spaces reaches `configure` as several arguments (`ffmpeg-9/generic.toml:20-24`) | hand the flags over one token at a time — `for _f in $CFLAGS; do BS_configure_args="$BS_configure_args --extra-cflags=$_f"; done` (`ffmpeg-9/generic.toml:25-41`) |
| `Unknown option "--extra-ldflags=..."` | `--extra-ldflags` is advertised but is in neither `CMDLINE_SET` nor `CMDLINE_APPEND`, so it is the same space trap one word later (`ffmpeg-9/generic.toml:29-33`) | do not pass it; let the project's own target rules link, and find deps through `pkg-config` (`ffmpeg-9/generic.toml:33-37`) |
| `sh: line NNN: vpx_arch: unbound variable` (or `ffmpeg_arch`) | the driver expands the recipe's fields **before** the recipe's own shell runs, so a variable computed in `pre` is not yet set when the field is expanded (`libvpx/android.toml:17-24`) | compute the name in `pre` and append it to `$BS_configure_args` there, where the name exists (`libvpx/android.toml:25`) |
| both build and install steps **skipped in silence**; `.../.relax-list: No such file or directory` | the driver reads an unset field as `${BS_make:-}`, so it inherits whatever the *previous* node left behind; a dependency that sets `make = false`/`install = false` (its own `post` builds) makes this node skip its steps too (`gnutls/generic.toml:88-94`, `ffmpeg-9/generic.toml:44-53`) | assert `make = true`, `install = true`, and clear `targets`/`make_args`/`install_args` so the previous node's values do not arrive as this one's arguments |
| probe fails with `ld.lld: error: unable to find library -llog` / `Toolchain is unable to link executables` | a hand-written configure probes by linking with `-static`, and the platform ships `liblog` only as a shared object (`libvpx/android.toml:33-38`) | strip that flag from `$LDFLAGS` for that build, rebuilding the list so the rest survives (`libvpx/android.toml:39-46`) |
| a `-isystem $SYSROOT/usr/include` breaks C++ (`<cstdint>` errors) | on C++ `-isystem` reorders libc++ before its own C headers (`system@aarch64-android33/system.toml:46-48`) | keep that flag C-only; get the sysroot into C++ via `--sysroot` (or `--extra-cxxflags=--sysroot=$SYSROOT`) |
| `configure` cannot finish, a dependency "was not found" | an optional feature defaults on and its dependency is absent (`gnutls/generic.toml:12-43`) | turn it off by name, and state the choice you take rather than leaving a default that can move: `--without-p11-kit`, `--with-included-unistring`, `--without-included-libtasn1` |
| a shipped manual/`info` page gets rebuilt, needing a tool you do not have | neither the source fetch nor the copy into the work dir preserves mtimes, so a `.PL`/`.in` can land newer than the shipped generated file; `all` then rebuilds it (`help2man/generic.toml:23-32`) | `touch` the shipped generated files in `pre`, newest last (`help2man/generic.toml:40-44`) |

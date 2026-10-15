# make

A bare hand-written `Makefile` — no `configure`, no cmake, no meson. The driver owns
the toolchain arguments, the flags and the staging; the recipe owns `targets`,
`make_args`, `install_args` and the `make`/`install` toggles
(`system@aarch64-android33/make.toml:1-6`, `docs/recipes.md:81`).

## The cross skeleton

```sh
LDFLAGS="$LDFLAGS -Wl,-rpath,'\$\$ORIGIN' -Wl,-rpath,'\$\$ORIGIN/../lib' -Wl,-rpath,'\$\$ORIGIN/../lib64'"

if [ "$BS_make" != "false" ]; then
  make -j"$CORES" CC="$CC" AR="$AR" RANLIB="$RANLIB" CFLAGS="$CFLAGS" \
       CXXFLAGS="$CXXFLAGS" LDFLAGS="$LDFLAGS" $BS_make_args $BS_targets
fi
if [ "$BS_install" != "false" ]; then
  DESTDIR="$DESTDIR" make CC="$CC" AR="$AR" RANLIB="$RANLIB" $BS_install_args install
fi
```

The `$ORIGIN` rpath is written `'$$ORIGIN'` inside shell double quotes: `make` reads
`$ORIGIN` as `$O` followed by `RIGIN` unless it is doubled, and the quotes keep the
shell from eating it first (`docs/systems.md:98-101`, `make.toml:12`).

## Required variables and flags

- **The toolchain is passed as make arguments, not through the environment.** A
  Makefile that says `CC=gcc` ignores the environment and would build with the host's
  compiler (`make.toml:7-9`). So `CC="$CC" AR="$AR" RANLIB="$RANLIB"` sit on the
  command line.
- `CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$LDFLAGS"` are passed the same way
  in the driver — but read the **exception** below before relying on it.
- `DESTDIR="$DESTDIR"` on the install line — a command-line assignment, so a Makefile
  that assigns `DESTDIR` itself cannot win (see [autoconf.md](autoconf.md); the
  mechanism is the same).

## The two ways flags cause a silent wrong build

1. **`CFLAGS=` on the command line defeats the project's own `CFLAGS +=`.** GNU make
   ignores makefile assignments, appends included, to a variable that came from the
   command line. For a project that appends — `-fno-strict-aliasing`, `-fPIC`, `-O3`,
   `-DNDEBUG`, `-march=armv8-a` — a command-line `CFLAGS` silently drops all of it and
   compiles code the upstream never tested (`openh264/generic.toml:10-21`). For those
   projects pass the **toolchain as arguments** (`CC`, `CXX`, `AR`, `RANLIB`, plus the
   target arch) but leave `CFLAGS`/`CXXFLAGS`/`LDFLAGS` to the **environment**, where
   the makefile's appends land (`openh264/generic.toml:19-21,58-64`).

2. **`PREFIX` must be the *staged* prefix, not `$OUTPKG`, when there is no `DESTDIR`
   support.** A Makefile whose install rule copies straight into `$(PREFIX)/bin`,
   `$(PREFIX)/lib`, … ignores `DESTDIR` entirely, so `PREFIX` *is* the destination.
   Give it `$PREFIX` (the staged path); given `$OUTPKG` it writes into the published
   path, nothing is staged, and publication reports
   `sh: line 50: <stage>/.../store/<hash>/../.relax-list: No such file or directory`
   before publishing an empty entry (`bzip2/generic.toml:31-42`).

   When the Makefile *does* know `DESTDIR`, pass `DESTDIR="$DESTDIR" PREFIX="$OUTPKG"`:
   the `.pc` file a project writes names the final prefix, and `DESTDIR` routes the
   copy through the stage (`openh264/generic.toml:45-47,62`).

## Target arch and the host

A Makefile that picks its sources from `uname -m` takes the **build** host's branch on
a cross build — x86 `.asm` sources for an aarch64 target. Pass the arch the makefile's
filters want:

```sh
make -j"$CORES" ARCH="$HOST_ARCH" CC="$CC" CXX="$CXX" AR="$AR" RANLIB="$RANLIB" <target>
```

and **repeat it on every make invocation**, including the install run, because a
target like `install-static` depends on the archive and recomputes the object list;
an invocation without `ARCH` falls back to `uname -m` and dies with
`nasm: No such file or directory` on an x86 `.asm` object
(`openh264/generic.toml:38-55`).

## Dependency discovery

The Makefile reads whatever it reads; the usual route is `pkg-config`, driven by the
closure's `$PKG_CONFIG_LIBDIR` / `$PKG_CONFIG_PATH` (`docs/recipes.md:59-61`). Since
there is no configure step, anything the Makefile needs must be visible either as
`pkg-config` output or as the closure's `-I`/`-L` flags (`docs/recipes.md:59-60`).

## Known pitfalls

| symptom in the log | cause | fix |
| --- | --- | --- |
| built with the **host** compiler | the Makefile hardcodes `CC=gcc`, which beats the environment (`make.toml:7-9`) | pass the toolchain as make arguments: `make CC="$CC" AR="$AR" RANLIB="$RANLIB" …` |
| project flags silently missing (wrong optimisation, no `-fPIC`, no `-fno-strict-aliasing`) | a command-line `CFLAGS=` switches off every `CFLAGS +=` in the makefile (`openh264/generic.toml:10-21`) | pass the toolchain as arguments and leave `CFLAGS`/`CXXFLAGS`/`LDFLAGS` in the environment |
| install wrote into the published path; `.../.relax-list: No such file or directory` | either the Makefile assigns `DESTDIR` itself (exported one ignored) or it has no `DESTDIR` support at all (`bzip2/generic.toml:31-42`) | put `DESTDIR="$DESTDIR"` on the command line; if unsupported, pass `PREFIX="$PREFIX"` (the staged path) |
| `nasm: No such file or directory` on an x86 `.asm` object during a cross build | the makefile picked its arch from `uname -m`; the install run recomputed the object list without the arch argument (`openh264/generic.toml:38-55`) | pass `ARCH="$HOST_ARCH"` on **every** make invocation |
| `cp: cannot stat 'bzip2.exe': No such file or directory` on a non-PE target | the build appends `.exe` on a PE target (Windows) but an ELF link leaves the bare name; an unconditional rename/copy breaks the other family (`bzip2/generic.toml:20-30`) | copy only when the suffixed name is actually present |
| a target program (test, encoder, decoder) is built and the host must not run it | the default goal includes programs, not just the library (`openh264/generic.toml:29-36`) | name the library target explicitly instead of `all`/`libraries`, and turn host programs off by name |
| the build step's default target runs a **test suite** | upstream's `all` runs tests (`bzip2/generic.toml:6-7`) | name the artifact target you want, not the default goal |

# Build systems — cross-compilation map

How to drive each build system by hand, from a POSIX shell, when the compiler on
`CC` targets another machine than the one running the build. One file per system:

- [autoconf.md](autoconf.md) — `./configure && make && make install`
- [cmake.md](cmake.md) — `cmake -S -B && cmake --build && cmake --install`
- [meson.md](meson.md) — `meson setup --cross-file && ninja install`
- [make.md](make.md) — a bare hand-written `Makefile`
- [cargo.md](cargo.md) — `cargo build --target`
- [python.md](python.md) — pure-Python packages, no compilation

## The model every driver follows

A build script names one build system and hands it **only the fields that are its
own**; the toolchain, flags, prefix, rpath and staging all come from the driver,
never from the recipe:

| `buildsystem` | recipe-owned fields |
| --- | --- |
| `autoconf` | `configure_args`, `targets`, `install_args`, `make`, `install` |
| `cmake` | `args`, `source_dir` |
| `meson` | `args`, `source_dir` |
| `make` | `targets`, `make_args`, `install_args`, `make`, `install` |
| `cargo` | `bin` (required), `features`, `no_default_features`, `install`, `env` |
| `python` | `modules`, `licenses`, `scripts`, `whole_tree` |

Source: `retrolunar2/docs/recipes.md:76-83`. The driver lives in the system's own
directory (`system@<name>/<bs>.toml`), not in the package:
`retrolunar2/docs/systems.md:8-18`.

Recipe scalar fields reach the driver as `$BS_<field>` — `$BS_args`, `$BS_bin`,
`$BS_configure_args`, `$BS_make`, `$BS_install`, `$BS_targets`, `$BS_make_args`,
`$BS_install_args`, `$BS_source_dir`, `$BS_env` — because a build-system recipe does
not get them as plain names, which would collide with the driver's own fields
(`retrolunar2/docs/recipes.md:120-126`).

## The environment a body starts from

| variable | meaning | source |
| --- | --- | --- |
| `$OUTPKG` | the entry's **final** path on the target machine | `docs/recipes.md:130` |
| `$PREFIX` | where to install **now** = `$DESTDIR$OUTPKG` (the staged tree) | `docs/recipes.md:131` |
| `$DESTDIR` | the staging root, exported so installers honour it | `docs/recipes.md:132` |
| `$SYSDIR` | the system's directory (holds toolchain/crossfile companions) | `docs/recipes.md:134` |
| `$NESTDIR`, `$WORK`, `$STAGE`, `$CORES` | nest, work dir, stage, job count | `docs/recipes.md:135` |
| `<dep>_PREFIX`, `DEPS`, `CPPFLAGS`, `LDFLAGS`, `PKG_CONFIG_*`, `CMAKE_PREFIX_PATH` | the dependency closure | `docs/recipes.md:136` |

Toolchain and target facts come from the system and are the same shape everywhere:
`$CC $CXX $AR $RANLIB $LD $AS $STRIP $OBJCOPY $READELF $NM $OBJDUMP`, `$CFLAGS`
`$CXXFLAGS $LDFLAGS $CPPFLAGS`, `$PKG_CONFIG_LIBDIR $PKG_CONFIG_PATH`,
`$SYSROOT`, `$BUILD_TRIPLET $HOST_TRIPLET $TARGET_TRIPLET`,
`$HOST_ARCH $HOST_OS`, `$MAKEFLAGS` (`system@aarch64-android33/system.toml:30-97`,
`system@clang-native/system.toml:3-37`).

## The seven cross-cutting rules

These are the failures that are not specific to one build system. Each build-system
file repeats the ones that hit it.

1. **Stage through `$DESTDIR`; never install into `$OUTPKG` directly.** An installer
   is told the *staged* prefix (`$PREFIX`) and writes through `$DESTDIR`; the staged
   tree then names itself correctly and publication moves it
   (`docs/recipes.md:178-192`). An install that reaches `$OUTPKG` writes into the
   published path, nothing is staged, and publication reports
   `sh: line 50: <stage>/.../store/<hash>/../.relax-list: No such file or directory`
   (`xz/generic.toml:19-28`).

2. **A Makefile variable beats the environment.** `DESTDIR=` exported into the
   environment is ignored by any Makefile that assigns `DESTDIR` itself; the value
   must be a **command-line assignment** (`make DESTDIR="$DESTDIR" ...`), which
   outranks the makefile (`help2man/generic.toml:49-58`, `xz/generic.toml:19-28`).

3. **Pass the toolchain where it cannot be ignored.** A Makefile that says `CC=gcc`
   ignores the environment, so the compiler goes in as a make argument, not
   `export CC=` (`system@aarch64-android33/make.toml:7-9`). The exception is a
   project whose makefile does `CFLAGS += ...`: a command-line assignment switches
   those appends off, so *those* flags must come from the environment
   (`openh264/generic.toml:10-21`).

4. **Keep the cross toolchain off `PATH`.** A cross compiler at the front of `PATH`
   makes every host tool run a target binary. Name each tool by full path instead
   (`system@aarch64-android33/system.toml:20-23`). The one exception is a build that
   resolves its own tools by name and has no flag to change that — a
   recipe-local `PATH="$TOOLBIN:$PATH"` (`openssl/android.toml:6-13`).

5. **Write the runtime path as `$ORIGIN`, `$ORIGIN/../lib`, `$ORIGIN/../lib64` — all
   three.** A program lands in `bin/` and its libraries in `lib/`, so `$ORIGIN` alone
   is the `bin` directory, where the loader finds nothing and silently takes a host
   library of the same soname (`docs/systems.md:101-104`). The spelling is the
   driver's job: shell in double quotes needs `$$ORIGIN` so `make` does not read
   `$O` + `RIGIN`, while `cmake`/`meson` hand the value to the compiler directly and
   take a single `$ORIGIN` (`docs/systems.md:98-101`, `autoconf.toml:13` vs
   `cmake.toml:22`).

6. **Never run a target binary.** Every probe that links a test program *and runs
   it* fails while cross compiling. Link a static library instead (cmake's
   `CMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY`,
   `system@aarch64-android33/cmake.toml:6-9`), or answer the probe with a cache
   variable (`ac_cv_func_ffsl=yes`, `gl_cv_func_strcasecmp_works=yes`,
   `system@aarch64-android33/system.toml:60-63`), or disable the stage that would
   run one (`--disable-tests`, `gnutls/generic.toml:58-60`).

7. **Decide the target explicitly; do not let the build guess the host.** A
   hand-written `configure` that is not autoconf cannot infer Bionic from the build
   machine — it needs `--target=...`/`--arch`/`--target-os`
   (`libvpx/android.toml:3-6`, `ffmpeg-9/android.toml:3-6`). Any build that reads
   `uname -m` must be handed the target arch as an argument
   (`openh264/generic.toml:38-43`).

## Finding dependencies

The closure hands every dependency over as include/library flags, `.pc` search
directories and cmake prefix entries (`docs/recipes.md:59-61`). The build system
consumes them through its own mechanism:

| build system | mechanism | file |
| --- | --- | --- |
| `autoconf` | `pkg-config` via `$PKG_CONFIG_LIBDIR`; `CPPFLAGS`/`LDFLAGS` for direct probes | [autoconf.md](autoconf.md) |
| `cmake` | `find_package`/`find_library` via `$CMAKE_PREFIX_PATH` + `CMAKE_FIND_ROOT_PATH` in the toolchain file | [cmake.md](cmake.md) |
| `meson` | native `pkg-config` + the cross file's `[binaries]` | [meson.md](meson.md) |
| `make` | whatever the Makefile reads, usually `pkg-config` | [make.md](make.md) |
| `cargo` | the `cc`/`pkg-config` crates, via `PKG_CONFIG_ALLOW_CROSS` and `cc`-crate env | [cargo.md](cargo.md) |
| `python` | none — pure source copy | [python.md](python.md) |

## A companion file is part of the system

A cross system usually needs a file the driver names: a cmake toolchain file and a
meson cross file here. Those files are part of the system's fingerprint, so editing
one makes every package of the system stale (`docs/systems.md:119-121`), and they
are referenced by name from the driver, not inlined
(`system@aarch64-android33/cmake.toml:5`, `meson.toml:5`).

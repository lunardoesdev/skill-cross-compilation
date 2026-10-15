# Libraries — what specific projects need and why

One file per library. Each records the build system, where the source comes from, which
recipe fields it overrides and why, what it requires from the *system*, and the traps it
is known for — each trap written as a **log signature** so it can be matched against a
real failure. `path:line` references point into
`retrolunar2-packages/<name>/{generic,android,<sys>}.toml`.

This directory is the per-project layer. The model itself (system / driver / package /
closure) and the driver-level rules live in `../SKILL.md` and
`../buildsystems/`; read those first — the entries here assume them.

## Index

| library | build system | what makes it distinctive |
| --- | --- | --- |
| [ffmpeg](ffmpeg.md) | autoconf (hand-written, libav-style) | ignores `$CFLAGS`/`$LDFLAGS`; rejects `--host`; flag lists word-split; `--extra-cflags` one token at a time |
| [libvpx](libvpx.md) | autoconf (hand-written) | needs explicit `--target`; strips `-llog` from `$LDFLAGS` so `-static` probes link |
| [opus](opus.md) | autoconf | the clean baseline — nothing but `--disable-shared --disable-doc` |
| [lame](lame.md) | autoconf | `make=false/install=false`, installs subdirs in `post`; is the node that leaks `make=false` downstream |
| [xz](xz.md) | autoconf | `DESTDIR` on the command line; `--disable-shared` is a policy correction |
| [zlib](zlib.md) | cmake | mingw installs `libzlib`, so a `post` makes the `libz` alias |
| [bzip2](bzip2.md) | make (no configure) | no DESTDIR at all; `.exe` suffix handling; pass the *staged* prefix |
| [gnutls](gnutls.md) | autoconf | every optional dep turned off by name; `--with-included-unistring`; FIPS runs a target binary |
| [nettle](nettle.md) | autoconf | "unrecognized option" accepts `--with-pic` silently — PIC is on by default |
| [libtasn1](libtasn1.md) | autoconf | no switch for the tools, so build only `lib/` (`-C lib`) |
| [gmp](gmp.md) | autoconf | `--disable-static` — ships the *shared* gmp, opposite of the convention |
| [help2man](help2man.md) | autoconf | a *host tool*; `PERL=` pins the interpreter; `touch` the shipped docs |
| [texinfo](texinfo.md) | make | nested configures use host tools; `help2man_PREFIX` on `PATH` manually |
| [sdl](sdl.md) | cmake | `-DANDROID=ON` + `-DANDROID_NDK=$NDK` because the toolchain keeps `CMAKE_SYSTEM_NAME Linux` |
| [leptonica](leptonica.md) | autoconf | each image format asked for by name so a miss is a hard error |
| [tesseract](tesseract.md) | autoconf (runs `autogen.sh`) | tag archive has no generated configure; empty submodules |
| [m4](m4.md) | autoconf | `post` build order; `touch` docs so the target `m4` is not run |
| [libpng](libpng.md) | autoconf | zlib probe hardcodes `-lz`; alias lives in zlib's recipe |
| [openssl](openssl.md) | make (its own `Configure`) | per-system target name; `TOOLBIN` on `PATH`; early-return NDK trap |
| [ncurses](ncurses.md) | autoconf | shared is deliberate; wide-char-only libs aliased to classic names |
| [expat](expat.md) | cmake | the minimal clean CMake recipe — one `args` line |
| [openh264](openh264.md) | make (hand-written) | toolchain on the make line; `ARCH` on *every* line; rewrites `.pc` to drop `-lpthread` |
| [portaudio](portaudio.md) | cmake (chosen over autotools) | autotools aborts on `-lpthread`; host ALSA/JACK leak into the `.pc` |
| [libnl-3](libnl-3.md) | autoconf | `flex`/`bison@native`; `--disable-pthreads` (Bionic has no libpthread) |
| [libjxl](libjxl.md) | cmake | empty `third_party/`; fetches submodules at the pinned commit |
| [glog](glog.md) | cmake (only) | `-DANDROID=ON` fixes the exported `.pc`; `post` adds `GLOG_USE_GLOG_EXPORT` |
| [chromaprint](chromaprint.md) | cmake | `CMAKE_FIND_ROOT_PATH_MODE` defeats `find_path`, so hand it the path |
| [libass](libass.md) | autoconf | hard pkg-config font checks; refuses to configure with no font provider |
| [liblc3](liblc3.md) | meson | project sets `b_lto=true`; meson archives LLVM bitcode → `-Db_lto=false` |
| [xvidcore](xvidcore.md) | autoconf | build body in `build/generic` (`source_dir`); `DESTDIR` on the command line |
| [vid.stab](vid.stab.md) | cmake | `USE_OMP=OFF` so OpenMP does not leak into the `.pc` |
| [srt](srt.md) | cmake (perl `Configure`) | `perl@native`; leave `USE_ENCLIB` unset for OpenSSL 4 (EVP path) |
| [zimg](zimg.md) | autoconf (runs `autogen.sh`) | tag archive has no configure; `@native` autotools; field leak published an empty entry |
| [libcap](libcap.md) | make (no configure) | `CC :=` in the makefile beats the env → make line; `BUILD_CC` is the host; `lib=lib` |
| [swig](swig.md) | cmake | a *host tool* in practice; CMake because autotools lacks a header template |
| [pixman](pixman.md) | meson | no `DESTDIR` (double prefix); `cpu-features.h` absent on 32-bit ARM |
| [protobuf-c](protobuf-c.md) | autoconf | `--disable-protoc` removes the entire protobuf dependency |
| [libaom](libaom.md) | cmake | googlesource archive has no leading dir; `perl@native` for `rtcd.pl` |
| [lexbor](lexbor.md) | cmake | generated `.pc` says `-llexbor` but only `liblexbor_static.a` exists |
| [glew](glew.md) | make (its cmake needs `OpenGL REQUIRED`) | config picked from the build host; install by hand; `STRIP=`/`LIBDIR=` |
| [physfs](physfs.md) | cmake | `PHYSFS_BUILD_TEST` would *install* a test program into `$PREFIX/bin` |
| [raylib](raylib.md) | cmake | `$<BUILD_INTERFACE:...>` drops private libs from the `.pc`/cmake targets |
| [libgit2](libgit2.md) | cmake | `USE_ICONV=OFF` needed below API 28; `STATIC_LIBRARY` try-compile gives a false positive |
| [rubberband](rubberband.md) | meson | `jni` must be off for reproducibility; all optional deps off by name |
| [capnproto](capnproto.md) | autoconf | `make all`/`install` **run** the target `capnp`; install targets named directly |
| [openblas](openblas.md) | make (no configure) | `HOSTCC` must be the host compiler; `TARGET` for the cross CPU |

`ffmpeg` covers the whole `ffmpeg` / `ffmpeg-6/7/8/9` family: one recipe per release line,
all sharing the hand-written-configure traps.

## Common patterns

These recur across the entries. When a new library needs a recipe, start here.

### Static, and only static
A target prefix has **no loader path we control**, so the product is the archive. In every
build system this has to be said out loud because the default is the opposite:
`--disable-shared --enable-static` (autoconf), `-DBUILD_SHARED_LIBS=OFF` (cmake, plus the
project's own `SDL_SHARED`, `PA_BUILD_SHARED`, `PHYSFS_BUILD_SHARED`, `LEXBOR_BUILD_SHARED`,
`ENABLE_SHARED`…), `-Ddefault_library=static` (meson). Add `--with-pic` when the archive is
meant to be linked into a shared object later (`libtasn1`, `libass`, `leptonica`, `libnl-3`).
Two deliberate exceptions: `ncurses` (shared, wide-char ABI) and `gmp` (`--disable-static`).

### Staging and `DESTDIR`
Install into a stage, move into place only on success. Where a Makefile **assigns**
`DESTDIR` itself, an exported variable is ignored (a Makefile variable beats the
environment) — pass it on the command line instead (`install_args = "DESTDIR=$DESTDIR"`):
`xz`, `help2man`, `openssl`, `xvidcore`, `capnproto`. Where the build has **no DESTDIR
support** at all, the *staged* prefix is what the install receives — pass `$PREFIX`, not
`$OUTPKG` (`bzip2`). With meson, `--prefix` is already in `$MESON_FLAGS`; adding `DESTDIR`
concatenates into `$OUT$OUT` (`pixman`). The failure signature is always the same:
`.../.relax-list: No such file or directory` after the build "succeeded".

### Repair the generated `.pc` / cmake package config
Several projects emit a packaging file that is simply wrong for a static, cross build. The
fix is a plain substitution of a **build output** in the staging dir (not a patch of an
upstream source): drop `-lpthread` (`openh264`), drop `Requires.private: glfw3` and add the
Android libs (`raylib`), fix `-llexbor`→`-llexbor_static` (`lexbor`), append
`-DGLOG_USE_GLOG_EXPORT` (`glog`). Rewrite the whole key, not just append — pkg-config
resolves a repeated key last-key-wins, which would drop the `-I`/`-L`.

### Host tools must RUN, and are `@native`
A program the build *executes* is a native dependency, never cross-compiled: `help2man`,
`perl`, `m4`, `flex`/`bison` (`libnl-3`), `perl` for `rtcd.pl` (`libaom`), `perl` for srt's
`Configure`, the `@native` autotools that generate a configure (`zimg`, `tesseract`). Pin
the exact path when a `PATH` lookup would bake a host path in: `PERL=$NESTDIR/perl@clang-native/bin/perl` (`help2man`). A same-system dependency does **not** put its
`bin/` on `PATH` — add it by hand (`texinfo`). The rule is a consumer should
`require("tool@native")`, never `require("tool")` (`swig`, `texinfo`).

### Never execute a target binary
Cross builds cannot run the artifacts. Where an upstream build does, either keep the
shipped generated file by `touch`ing it (docs in `m4`, `help2man`, `gmp`), build/install
only the sub-targets that avoid the run (`capnproto` names `install-libLTLIBRARIES` +
`install-data`; `libtasn1` uses `-C lib`; `zimg` splits the build), or turn the switch off:
`BUILD_TESTING=OFF` (`glog`, `libjxl`), `BUILD_TESTS=OFF` (`chromaprint`, `libjxl`),
`PHYSFS_BUILD_TEST=OFF`, the `ENABLE_TOOLS/APPS/TESTS` family (`srt`, `libaom`),
`--disable-programs` (`leptonica`), `--disable-tools/tests` (`gnutls`).

### The build host leaks into the target if you let it
Autodetection on the *build* host selects features that do not belong to the target prefix:
`ldd /usr/bin/ld` picks `lib64` (`libcap`), `uname -m` picks x86 assembly (`openh264`,
`openblas`), `config.guess` picks the linux config (`glew`), the host's ALSA/JACK get baked
into a `.pc` (`portaudio`), the host's `libunwind` would be preferred (`glog`),
`jni=auto` depends on a Java toolchain (`rubberband`). The fix is to **state the target
explicitly** and disable autodetection: `ARCH=`, `TARGET=`, the toolchain on the make line,
`-DPA_USE_ALSA=OFF`, `WITH_UNWIND=none`, `-Djni=disabled`. The same trap in cmake form: a
toolchain file that keeps `CMAKE_SYSTEM_NAME Linux` makes cmake's `ANDROID` false, so you
must pass `-DANDROID=ON` yourself (`sdl`, `glog`).

### Command-line vs environment vs makefile
When a Makefile uses `:=` (`libcap`) or a plain `=` (`glew`, `xvidcore`'s `platform.inc`),
an exported environment variable loses. A **command-line** assignment wins over both:
pass `CC/AR/RANLIB/DESTDIR/…` as make arguments (but *not* `CFLAGS=` — that switches off
every `CFLAGS +=` in the file, which is why `openh264` passes the toolchain as arguments and
lets the flags come from the environment). Build systems that ignore `$CFLAGS`/`$LDFLAGS`
entirely (`ffmpeg`) need the flags handed to `configure` the project's own way.

### Flag lists are word-split
A build that takes a list of flags needs one token at a time, or a multi-word flag arrives
as several arguments (`ffmpeg`: `Unknown option "-fPIC"`). And an option the project does
not actually implement is worse than none: `configure` accepts `--with-pic` on nettle with
a silent "unrecognized options" warning, so the recipe looks deliberate and is not.

### Field inheritance between closure nodes
A generated build script runs every node in one process; a field the recipe does not define
reads as `${BS_make:-}` and inherits whatever the **previous** node left behind. A
dependency built in `post` (`lame`, `bzip2`, `m4`, the `@native` autotools) sets
`make=false/install=false`, so the next node silently skips its steps and publishes an
**empty entry while exiting 0** (`ffmpeg`, `gnutls`, `libtasn1`, `zimg`). Any recipe after
such a node must assert `make = true`, `install = true` and clear
`targets`/`make_args`/`install_args`.

### Dependency ordering is real
The loader only orders a package after the packages it `require()`s. A dependency resolved
at configure time by `find_package` (PCRE2 for `libgit2`) fails on a *clean* nest and works
by accident on a dirty one if it is not declared. Declare it.

### Where the source comes from decides whether it builds at all
These systems carry **no autotools on purpose**, so a release `make dist` tarball (which
ships a generated `./configure`) is preferred over a git tag archive. When only a tag
archive exists, the recipe must generate the configure with `@native` autotools
(`zimg`, `tesseract`) or use a different build system that does not need one (`swig`'s
cmake, `glog`'s cmake). Watch the archive shape: `--strip-components=1` for a dist tarball
with a leading directory, **none** for a googlesource export (`libaom`), and empty
submodules that a non-optional feature needs must be fetched at the pinned commit
(`libjxl`). Release tarball copies do not preserve mtimes, which is why shipped generated
files get `touch`ed.

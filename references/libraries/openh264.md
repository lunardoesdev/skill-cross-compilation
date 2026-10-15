# openh264

H.264 codec library; installs `libopenh264.a`, `include/wels` and `openh264.pc`.

- build system: **make** (`openh264/generic.toml:2`) — a hand-written Makefile, not
  autoconf and not cmake. A recipe that just named the build system would build the wrong
  things three times over (`openh264/generic.toml:5-6`).
- source: GitHub tag archive `v2.6.0`, `--strip-components=1` (`openh264/source.toml:6-11`).
- deps: none.
- recipes: `generic.toml`, `android.toml` (pkg-config fix only).

## Overridden fields

```toml
make = false
install = false
post = """
make -j"$CORES" ARCH="$HOST_ARCH" CC="$CC" CXX="$CXX" AR="$AR" RANLIB="$RANLIB" libopenh264.a
make DESTDIR="$DESTDIR" PREFIX="$OUTPKG" LIBDIR_NAME=lib ARCH="$HOST_ARCH" CC=... RANLIB=... install-static
"""
```
(`openh264/generic.toml:96-104`)

- **`make=false`/`install=false`** because the driver's generic steps are wrong here:
  - The build step would run `make CC=... CFLAGS=...`. A **command-line assignment
    switches off every `CFLAGS +=` in this Makefile** (GNU make ignores makefile
    assignments to a variable that came from the command line). Lost: `-fno-strict-aliasing`,
    `-fPIC`, `-fstack-protector-all`, `-O3`, `-DNDEBUG`, the arm64 `-march=armv8-a` and
    `-DHAVE_NEON_AARCH64` (`openh264/generic.toml:50-60`). So the toolchain arrives as
    make *arguments* (`$CC/$CXX/$AR/$RANLIB/ARCH`) and `CFLAGS/CXXFLAGS/LDFLAGS` come from
    the environment, where the Makefile's appends land.
  - `make install` is `install-static-lib install-shared` and links the shared object too;
    the target wanted is `install-static` (`openh264/generic.toml:62-67`).
- **`ARCH="$HOST_ARCH"` on both lines**, not belt-and-braces: openh264 picks its assembly
  from `uname -m` (`openh264/generic.toml:78-83`). `install-static` depends on the
  archive, so make recomputes the object lists in the second run too — an invocation that
  omits `ARCH` falls back to `uname -m`, takes the x86 branch and dies
  (`openh264/generic.toml:89-95`).
- Build `libopenh264.a` by name — `all` is `libraries binaries` and `binaries` builds
  `h264enc`/`h264dec` (target programs), `libraries` links the `.so`
  (`openh264/generic.toml:69-76`).
- `PREFIX=$OUTPKG` (not `$PREFIX`): `install-static` writes `openh264.pc` whose prefix is
  `$(PREFIX)` (`openh264/generic.toml:85-87`).

## Android

The Android recipe differs in exactly one thing: Bionic has **no libpthread**, but
upstream's `STATIC_LDFLAGS += -lpthread -lm` writes `-lpthread` into the installed
`openh264.pc` (`openh264/android.toml:6-20`). The `post` rewrites that generated `.pc`
with `awk` to drop `-lpthread` (`openh264/android.toml:33-37`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `nasm: No such file or directory` on `codec/encoder/core/x86/coeff.o` | an invocation without `ARCH` falls back to `uname -m` and takes the x86 branch, adding x86 `.asm` objects to the archive (`openh264/generic.toml:89-95`) | pass `ARCH=$HOST_ARCH` on **every** make line, including install |
| the library built at `-O2` without `-fno-strict-aliasing` | `CFLAGS=` on the make command line switched off the Makefile's appends (`openh264/generic.toml:50-61`) | pass only the toolchain as make arguments; let `CFLAGS` reach the build from the environment |
| `ld.lld: error: unable to find library -lpthread` for a consumer of openh264 on Android | the installed `.pc` carries `-lpthread` from the static link flags (`openh264/android.toml:8-20`) | rewrite the generated `.pc` to drop `-lpthread` |
| the shared object and the CLIs get built/installed | default `all`/`install` targets (`openh264/generic.toml:62-76`) | build `libopenh264.a` and `install-static` explicitly |

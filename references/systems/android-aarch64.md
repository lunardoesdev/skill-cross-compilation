# android-aarch64 — Android arm64-v8a (`aarch64`)

Read this together with `references/systems/android-abi.md` (what changes between API
levels) and `snippets/systems/android-aarch64.sh` (the exact environment to source).

## Identity

| fact | value | source |
|---|---|---|
| host triplet (`--host`) | `aarch64-linux-android` | `system@aarch64-android33/system.toml:87` |
| build triplet | `x86_64-pc-linux-gnu` | `system@aarch64-android33/system.toml:86` |
| target | `== host` (nothing builds a compiler) | `system@aarch64-android33/system.toml:88` |
| `HOST_ARCH` / `HOST_OS` | `aarch64` / `android` | `system@aarch64-android33/system.toml:89-90` |
| CMake `CMAKE_SYSTEM_PROCESSOR` | `aarch64` | `aarch64-linux-android33-toolchain.cmake:6` |
| Meson `cpu_family` / `cpu` | `aarch64` / `aarch64` | `crossfile-aarch64-android33.ini:12-14` |
| Rust target | `aarch64-linux-android` | `cargo.toml:12` |
| fallback recipe namespace | `["android"]` | `system@aarch64-android33/system.toml:2` |

The triplet is **not** `aarch64-linux-android<API>`: the API level lives only in the
NDK wrapper *filename* and in the `ANDROID_API` number, never in the triplet
(`system.toml:28-31`).

## Toolchain resolution (what the system computes, not what it hardcodes)

The system script finds the NDK at run time, so the same file works with any NDK
version installed:

- requires `ANDROID_HOME` (`":[ \"${ANDROID_HOME:?set ANDROID_HOME to an Android SDK
  with an NDK}\"`", `system.toml:5`);
- picks the **newest** NDK under `$ANDROID_HOME/ndk` with a shell glob + `sort -V |
  tail -1` — deliberately not `ls`, because aliases like `eza` mangle `ls` output
  (`system.toml:6-10`);
- fails with a message if there is none (`system.toml:11-15`);
- `TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64`, `TOOLBIN=$TOOLCHAIN/bin`,
  `SYSROOT=$TOOLCHAIN/sysroot` (`system.toml:16-24`).

**`$TOOLBIN` is deliberately NOT prepended to `PATH`** (`system.toml:20-23`): a cross
toolchain at the front of `PATH` makes host tools run target binaries. Every tool is
named by full path instead — which is also what CMake and Meson need to resolve a
compiler that is not on `PATH`.

## Environment variables

Full literal values: `snippets/systems/android-aarch64.sh`. What each is:

- **`CC`/`CXX`** = `$TOOLBIN/aarch64-linux-android<API>-clang[++]` — the NDK "unified"
  driver wrappers; the filename encodes the API level (`system.toml:29-31`).
- **binutils** are the LLVM ones from the same `bin/`, *not* per-arch prefixed:
  `AR=llvm-ar`, `RANLIB=llvm-ranlib`, `LD=ld.lld`, `STRIP=llvm-strip`,
  `OBJCOPY=llvm-objcopy`, `READELF=llvm-readelf`, `NM=llvm-nm`, `OBJDUMP=llvm-objdump`
  (`system.toml:32-41`). `AS` and `ASM` are aliases of `$CC` (`system.toml:35-36`).
- **`CFLAGS`** = `-O2 -fPIC -DANDROID -isystem $SYSROOT/usr/include` (`system.toml:49-50`).
- **`CXXFLAGS`** = `-O2 -fPIC -DANDROID` — **no `-isystem $SYSROOT/usr/include`**
  (`system.toml:71`). This is the one place aarch64 differs from the other Android
  families (see below).
- **`LDFLAGS`** = `$LDFLAGS -lm -llog` (`system.toml:78`).
- **`PKG_CONFIG_LIBDIR`** = `…:$SYSROOT/usr/lib/pkgconfig:$SYSROOT/usr/share/pkgconfig`
  (`system.toml:58-59`); **`PKG_CONFIG_PATH`** is left as-is / effectively empty, so
  host `.pc` files are ignored (`system.toml:79-80`).
- **`ac_cv_func_ffsl=yes`**, **`gl_cv_func_strcasecmp_works=yes`** (`system.toml:62-63`).
- **Cargo**: `CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=$CC`,
  `…_AR=$AR`, plus `CC_/CFLAGS_/CXX_/CXXFLAGS_aarch64_linux_android` for `cc`-crate
  build scripts (`system.toml:64-68`).

## Flags, and why

- **`-O2 -fPIC`** — shared objects are the normal artifact; there is no "position
  dependence allowed" story for a general package (`system.toml:49`).
- **`-DANDROID`** — Bionic/Android code paths keyed on this macro (`system.toml:50`).
- **`-isystem $SYSROOT/usr/include` (C only)** — an *isystem* (not `-I`) so the NDK
  sysroot is searched *after* our `$PREFIX/include`. The reason: autoconf probes (e.g.
  libpng's zlib check, `pnglibconf.h` generation) call `$CC -E` and would otherwise find
  the NDK's own ancient `zlib.h` in the sysroot instead of ours (`system.toml:42-48`).
  It must stay **C-only**: applied to C++ it reorders libc++ before its own C headers
  and breaks `<cstdint>`; libvpx's C++ files get the sysroot via `--sysroot` instead
  (`system.toml:46-48`). This is the reason `CXXFLAGS` is written out separately here
  while the other Android families just do `CXXFLAGS="$CFLAGS"` (e.g.
  `system@i686-android33/system.toml:46`).
- **`-lm`** — Bionic keeps math functions in `libm`; glibc folds them into `libc`, so a
  program calling `log2/pow/exp` links on a native build and fails here. `libm` is in
  every sysroot, so `-lm` costs nothing (`system.toml:74-77`).
- **`-llog`** — abseil `AndroidLogSink` and glog `AlsoErrorWrite` call
  `__android_log_write`, in Bionic's `liblog`; both are static archives with no link
  step, so the reference only surfaces at consumer link time. `liblog.so` is in every
  sysroot and the symbol is API 21+ (`system.toml:51-56`).
- **runtime search path** `-Wl,-rpath,$ORIGIN -Wl,-rpath,$ORIGIN/../lib
  -Wl,-rpath,$ORIGIN/../lib64` — added by *every buildsystem script*, not by `LDFLAGS`
  (`autoconf.toml:13`). Three entries because a program lands in `bin/` and its
  libraries in `lib/`; `$ORIGIN` alone is the `bin` dir and would let the loader pick a
  host library of the same soname (`docs/systems.md:100-104`). Spelling of `$ORIGIN` is
  driver-specific: `make`/autoconf read `$$ORIGIN` inside shell quoting, CMake/Meson/
  Cargo get `$ORIGIN` directly.

## Platform vs. build boundary

**The platform / NDK gives you:**

- Bionic `libc`, `libm`, `libdl`, `liblog`, `libc++`/`libc++abi`/`libunwind` and the
  API-versioned stub `.so`/`.a` set inside `$SYSROOT/usr/lib/<aarch64-linux-android>`;
- the sysroot headers (`$SYSROOT/usr/include`) with per-API symbol availability;
- the LLVM compiler + binutils above, cross-capable out of the box.

**You must build yourself** (into `$PREFIX`, the system's "nest" dir): every
third-party library — zlib, OpenSSL, ffmpeg, … Nothing but Bionic and `liblog` comes
from the platform. There is no host `pkg-config` database for the target: `PKG_CONFIG_*`
is pointed at `$PREFIX` and the sysroot only.

## Boundary: what the *build system* adds on top of `[system]`

These are the driver fragments, identical across Android families except for filenames:

- **CMake** — toolchain file `$SYSDIR/aarch64-linux-android<API>-toolchain.cmake`;
  `-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY`
  (the compiler check links *and runs* a program, impossible when cross-compiling),
  `-DTHREADS_PREFER_PTHREAD_FLAG=ON` (FindThreads cannot detect Bionic pthreads, which
  are in libc), `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` (cmake 4.x refuses older
  projects), `-DCMAKE_MAKE_PROGRAM=$(command -v make || true)` (pins the *host* make,
  not `$PREFIX/bin/make`, which is a target binary) — `cmake.toml:6,20`.
  The toolchain file keeps `CMAKE_SYSTEM_NAME Linux` on purpose: setting it to `Android`
  makes CMake start its own NDK integration, which the system does by hand
  (`aarch64-linux-android33-toolchain.cmake:1-2`).
- **Meson** — cross-file `$SYSDIR/crossfile-aarch64-android<API>.ini`; content is
  `[host_machine] system=android` (compilers come from the environment, so `[binaries]`
  only sets `pkgconfig='pkg-config'`) — `meson.toml:5`, `crossfile-…:1-19`.
- **Autoconf** — `--host=$HOST_TRIPLET --build=$BUILD_TRIPLET --prefix=$OUTPKG`;
  `clang-native` omits `--host` (`autoconf.toml:11` vs `system@clang-native/autoconf.toml:11`).
- **make** — toolchain passed as `make` *arguments* (`CC=… AR=… RANLIB=… CFLAGS=…
  CXXFLAGS=… LDFLAGS=…`), because a Makefile with `CC=gcc` ignores the environment
  (`make.toml:7-14`).
- **Cargo** — `CARGO_BUILD_TARGET=aarch64-linux-android`, `PKG_CONFIG_ALLOW_CROSS=1`;
  the rpath goes into `$RUSTFLAGS` (`-C link-arg=-Wl,-rpath,…`) because Cargo never
  reads `$LDFLAGS` (`cargo.toml:11-17`).

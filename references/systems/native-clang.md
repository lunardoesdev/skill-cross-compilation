# native-clang — host build with clang (`clang-native`)

Source: `system@clang-native/`. Snippet: `snippets/systems/native-clang.sh`. This is the
**control case**: a build that targets the machine it runs on, kept in the same shape as
the cross systems so recipes do not branch.

## Identity

| fact | value | source |
|---|---|---|
| build / host / target triplet | all `x86_64-pc-linux-gnu` | `system@clang-native/system.toml:25-27` |
| `HOST_ARCH` / `HOST_OS` | `x86_64` / `linux` | `system@clang-native/system.toml:28-29` |
| `fallbacks` | *(none — no `fallbacks` key)* | `system@clang-native/system.toml:1` |
| probes | `clang --version`, `meson --version`, `cmake --version`, `pkg-config --version` | `system@clang-native/system.toml:38` |

## Environment variables

- **`CC`/`CXX`** = `clang` / `clang++` — bare names from `PATH`, not full paths
  (`system.toml:3-4`).
- binutils: `AR=ar`, `RANLIB=ranlib`, `LD=ld`, `STRIP=strip`, `OBJCOPY=objcopy`,
  `READELF=readelf`, `OBJDUMP=objdump` (`system.toml:5-12`), and `AS="$CC"`
  (`system.toml:8`). No `NM` (the cross systems set it; this one does not).
- **`CFLAGS = CXXFLAGS = "-O2 -fPIC $CPPFLAGS"`** (`system.toml:16-17`).
- **`LDFLAGS = "$LDFLAGS -Wl,--undefined-version"`** (`system.toml:18`).
- **`PKG_CONFIG_PATH = "$PKG_CONFIG_PATH"`** — a pass-through; the comment says "Ignore
  host `.pc` files: only ours count" (`system.toml:19-20`), because `$PREFIX` is this
  system's nest dir (where deps landed) and that is what should be searched.
- **No cross-file, no toolchain file** (see below).

## Flags, and why

- **`$CFLAGS` stays clean.** The comment is explicit: "$`CPPFLAGS`/`LDFLAGS` cover the
  autoconf probes (e.g. libpng's zlib check); plain `CFLAGS` stay clean for direct `$CC`
  users" (`system.toml:13-17`). So the *system* hands the probe-only flags to the build
  systems through `$CPPFLAGS`, and a recipe that runs `$CC` directly does not pick them
  up. (`$CPPFLAGS` itself is provided by the harness, not set here.)
- **`-Wl,--undefined-version`** — a GNU-ld relaxation; it is **ELF-only**. The mingw
  system spells out that it must *not* be used there ("that's ELF-only, ld for PE
  fails", `system@mingw64/system.toml:17`). It exists here so projects that pass version
  scripts ld would otherwise reject still link.
- **`-fPIC`** even natively, matching the cross systems, so artifacts are uniform.

## Platform vs. build boundary

There is no platform-vs-build split here in the NDK sense: the host's glibc, libm,
libstdc++/libc++ and headers are all the target's headers, and anything not in the host
must be built into `$PREFIX`. Everything the cross Android systems get from a sysroot,
this system gets from the running host. `$PREFIX` is the system's nest dir where deps
landed (`system.toml:13`).

## Build-system fragments

- **CMake** — `CMAKE_TOOLCHAIN_FILE = ""` (empty: no cross toolchain file is loaded),
  and the script's `${CMAKE_TOOLCHAIN_FILE:+…}` expansion therefore adds nothing
  (`cmake.toml:5,9`). `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` is still set (cmake 4.x
  refuses older projects), but `-DCMAKE_TRY_COMPILE_TARGET_TYPE` and
  `-DCMAKE_MAKE_PROGRAM` are **not** needed and omitted (`cmake.toml:6`).
- **Meson** — `MESON_CROSS_FILE = ""`, `MESON_FLAGS = "--prefix=$OUTPKG"` only
  (`meson.toml:5,17`). The comment records a defect that was fixed: an *empty*
  `MESON_FLAGS` left meson at `prefix=/usr/local`, so builds "installed" nothing and
  reported no error — a silent failure (`meson.toml:6-17`).
- **Autoconf** — `AUTOCONF_CONFIGURE_FLAGS = "--build=$BUILD_TRIPLET --prefix=$OUTPKG"`
  with **no `--host`** (native): `autoconf.toml:11`. (Contrast the cross systems, which
  add `--host=$HOST_TRIPLET`.)
- **Cargo** — `CARGO_BUILD_TARGET = "x86_64-unknown-linux-gnu"` (`cargo.toml:12`).

The `probe` list is the one system.toml mechanism unique to this file: it makes host
facts visible — the commands run after setup, their output and exit status are hashed
into state, and a change marks every package of the system stale; a non-zero status is a
*change*, not a failure (`docs/systems.md:65-69`).

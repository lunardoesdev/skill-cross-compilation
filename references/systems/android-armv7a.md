# android-armv7a — Android armeabi-v7a (`armv7a`)

Source: `system@armv7a-android33/`. See also `references/systems/android-abi.md` and
`snippets/systems/android-armv7a.sh`.

## Identity

| fact | value | source |
|---|---|---|
| host triplet (`--host`) | `armv7a-linux-androideabi` | `system@armv7a-android33/system.toml:83` |
| build triplet | `x86_64-pc-linux-gnu` | `system@armv7a-android33/system.toml:82` |
| `HOST_ARCH` / `HOST_OS` | `armv7a` / `android` | `system@armv7a-android33/system.toml:85-86` |
| CMake `CMAKE_SYSTEM_PROCESSOR` | `arm` | `armv7a-linux-androideabi33-toolchain.cmake:6` |
| Meson `cpu_family` / `cpu` | `arm` / `armv7` | `crossfile-armv7a-android33.ini:12,14` |
| Rust target | `armv7-linux-androideabi` | `cargo.toml:12` |

Note the triplet: `armv7a-linux-androideabi` for `--host`, but Rust spells it
`armv7-linux-androideabi` (no `a`). CMake's `CMAKE_SYSTEM_PROCESSOR` is just `arm`, not
`armv7` — the `armv7` refinement is only in the Meson `cpu` field
(`…toolchain.cmake:6`, `crossfile-…:14`).

## ⚠ The wrapper name is pinned at API 21, not the system's API

For **every** armv7a system the compiler wrappers and the CMake toolchain filename use
`21`, while `ANDROID_API` follows the system name:

- `CC="$TOOLBIN/armv7a-linux-androideabi21-clang"`
  (`system@armv7a-android33/system.toml:30-31`, and identically in the `-21`, `-24`,
  `-35` systems — `grep androideabi system@armv7a-android*/system.toml`);
- `ANDROID_API=33` in the same file (`system@armv7a-android33/system.toml:28`);
- the comment two lines up still says "Wrappers already encode the API level (33)"
  (`system@armv7a-android33/system.toml:29`) — the comment and the line disagree;
- `CMAKE_TOOLCHAIN_FILE = "$SYSDIR/armv7a-linux-androideabi21-toolchain.cmake"`
  (`system@armv7a-android33/cmake.toml:5`), but the file on disk for the 33 system is
  `armv7a-linux-androideabi33-toolchain.cmake`. This reference is **broken for every
  armv7a API ≥ 23** (verified: `-21` resolves, `-23…-35` point at a `…21-…` file that
  does not exist).

Unlike aarch64 (where `CC=…android<API>-clang` tracks the system), armv7a does not vary
the wrapper by API. The Meson cross-file *name* does vary (`crossfile-armv7a-android33.ini`)
but its content is identical across API levels.

## Environment variables

Same shape as aarch64; literal values in `snippets/systems/android-armv7a.sh`. Deltas:

- `ANDROID_API` = system's level, wrapper = `…androideabi21-clang` (see above).
- **`CXXFLAGS="$CFLAGS"`** — armv7a *does* pass `-isystem $SYSROOT/usr/include` to C++
  (`system.toml:46`), unlike aarch64. No libc++/`<cstdint>` caveat is recorded here.
- binutils: same LLVM set (`armv7a-…/system.toml:32-39`).
- **No `AS`/`ASM`** lines (aarch64 has them; armv7a/`i686`/`x86_64` do not) — the CMake
  toolchain still does `set(CMAKE_ASM_COMPILER "$ENV{AS}" …)`, so `$AS` is empty here
  (`system.toml` has no `AS`, `…toolchain.cmake:24`).
- Cargo vars use `…_ARMV7_LINUX_ANDROIDEABI_*` and `*_armv7_linux_androideabi`
  (`system.toml:60-65`).

## Flags, and why

Identical rationale to `android-aarch64.md`: `-O2 -fPIC -DANDROID`, C-only `-isystem`
sysroot reason, `-lm` (Bionic math in `libm`), `-llog` (`__android_log_write`, API 21+),
`$ORIGIN` rpath trio. See that file for the full citations; the armv7a sources are
`system.toml:44-53` and `autoconf.toml:13`.

## Platform vs. build boundary

Same as aarch64: Bionic + `liblog` + the armeabi-v7a sysroot come from the NDK; every
third-party library must be built into `$PREFIX`. Note armeabi-v7a is a **32-bit, softfp
by default** target — the NDK clang wrapper selects the ABI; nothing in these files adds
`-mfloat-abi`/`-mfpu`, so it is whatever the NDK wrapper defaults to.

## Build-system fragments

Consumer fragments are byte-identical to aarch64 except the names: toolchain file
`$SYSDIR/armv7a-linux-androideabi21-toolchain.cmake` (`cmake.toml:5`), cross-file
`$SYSDIR/crossfile-armv7a-android<API>.ini` (`meson.toml:5`), same `CMAKE_FLAGS`
(`cmake.toml:6`).

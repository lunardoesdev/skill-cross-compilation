# android-x86_64 — Android x86-64 (`x86_64`)

Source: `system@x86_64-android33/`. See also `references/systems/android-abi.md` and
`snippets/systems/android-x86_64.sh`.

## Identity

| fact | value | source |
|---|---|---|
| host triplet (`--host`) | `x86_64-linux-android` | `system@x86_64-android33/system.toml:83` |
| build triplet | `x86_64-pc-linux-gnu` | `system@x86_64-android33/system.toml:82` |
| `HOST_ARCH` / `HOST_OS` | `x86_64` / `android` | `system@x86_64-android33/system.toml:85-86` |
| CMake `CMAKE_SYSTEM_PROCESSOR` | `x86_64` | `x86_64-linux-android33-toolchain.cmake:6` |
| Meson `cpu_family` / `cpu` | `x86_64` / `x86_64` | `crossfile-x86_64-android33.ini:12-14` |
| Rust target | `x86_64-linux-android` | `cargo.toml:12` |

The build triplet and the host triplet share the `x86_64` token but differ in the OS:
the host builds on `x86_64-pc-linux-gnu` and targets `x86_64-linux-android`
(`system.toml:82-83`).

## Environment variables

Same shape as the other Android families; literal values in
`snippets/systems/android-x86_64.sh`. Deltas from aarch64:

- `ANDROID_API=33`, `CC="$TOOLBIN/x86_64-linux-android33-clang"`
  (`system.toml:28-31`).
- **`CXXFLAGS="$CFLAGS"`** (`system.toml:46`) — C++ gets
  `-isystem $SYSROOT/usr/include`.
- **No `AS`/`ASM`** assignment (`system.toml:32-39`).
- Cargo vars use `…_X86_64_LINUX_ANDROID_*` / `*_x86_64_linux_android`
  (`system.toml:60-65`).

## Flags, and why

- `-O2 -fPIC -DANDROID` (`system.toml:44-45`).
- C-only-`-isystem` semantics are moot here because `CXXFLAGS="$CFLAGS"`: both receive
  `-isystem $SYSROOT/usr/include` (`system.toml:44-46`). `-isystem` (not `-I`) keeps
  `$PREFIX/include` first for autoconf `$CC -E` probes (`system.toml:40-43`).
- `LDFLAGS = "$LDFLAGS -lm -llog"` (`system.toml:74`).
- `$ORIGIN` rpath trio per build-system script (`autoconf.toml:13`); full rationale in
  `references/systems/android-aarch64.md#flags-and-why`.

## Platform vs. build boundary

Unchanged: Bionic + `liblog` + x86_64 sysroot + LLVM toolchain come from the NDK; every
third-party library is built into `$PREFIX`. `x86_64` is the emulator's native ABI and
the most convenient Android target to smoke-test on a host
(`docs/systems.md:172-175` records the port was checked on `aarch64-android24`, not
here).

## Build-system fragments

Identical to aarch64 apart from names: toolchain file
`$SYSDIR/x86_64-linux-android33-toolchain.cmake` (`cmake.toml:5`), cross-file
`$SYSDIR/crossfile-x86_64-android33.ini` (`meson.toml:5`), same `CMAKE_FLAGS`
(`cmake.toml:6`).

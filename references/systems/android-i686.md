# android-i686 — Android x86 (`i686`)

Source: `system@i686-android33/`. See also `references/systems/android-abi.md` and
`snippets/systems/android-i686.sh`.

## Identity

| fact | value | source |
|---|---|---|
| host triplet (`--host`) | `i686-linux-android` | `system@i686-android33/system.toml:83` |
| build triplet | `x86_64-pc-linux-gnu` | `system@i686-android33/system.toml:82` |
| `HOST_ARCH` / `HOST_OS` | `i686` / `android` | `system@i686-android33/system.toml:85-86` |
| CMake `CMAKE_SYSTEM_PROCESSOR` | `x86` | `i686-linux-android33-toolchain.cmake:6` |
| Meson `cpu_family` / `cpu` | `x86` / `i686` | `crossfile-i686-android33.ini:12,14` |
| Rust target | `i686-linux-android` | `cargo.toml:12` |

The triplet arch token is `i686-linux-android`, but CMake and Meson both call the family
`x86` and only the Meson `cpu` says `i686` — three spellings of the same target
(`system.toml:83`, `…toolchain.cmake:6`, `crossfile-…:12-14`).

## Environment variables

Same shape as the other Android families; literal values in
`snippets/systems/android-i686.sh`. Deltas from aarch64:

- `ANDROID_API=33`, `CC="$TOOLBIN/i686-linux-android33-clang"`
  (`system.toml:28-31`) — wrapper tracks the system's API (contrast armv7a).
- **`CXXFLAGS="$CFLAGS"`** (`system.toml:46`) — so C++ *does* get
  `-isystem $SYSROOT/usr/include`, like armv7a and x86_64, and unlike aarch64.
- **No `AS`/`ASM`** assignment (`system.toml:32-39` only lists the LLVM binutils).
- Cargo vars use `…_I686_LINUX_ANDROID_*` / `*_i686_linux_android`
  (`system.toml:60-65`).

## Flags, and why

- `-O2 -fPIC -DANDROID` (`system.toml:44-45`).
- `-isystem $SYSROOT/usr/include` in C and C++ — searched after `$PREFIX/include` so
  autoconf `$CC -E` probes find *our* headers, not the NDK's `zlib.h`
  (`system.toml:40-45`).
- `LDFLAGS = "$LDFLAGS -lm -llog"` (`system.toml:74`) — `-lm` because Bionic keeps math
  in `libm`; `-llog` for `__android_log_write` (abseil/glog), API 21+
  (`system.toml:68-74`).
- `$ORIGIN` rpath trio, added per build-system script (`autoconf.toml:13`).

The full rationale (why `-isystem` beats `-I`, why libm/liblog cost nothing, why three
rpath entries) is in `references/systems/android-aarch64.md#flags-and-why` and applies
unchanged.

## Platform vs. build boundary

Unchanged: NDK supplies Bionic (`libc`/`libm`/`libdl`), `liblog`, libc++, the x86
sysroot, and the LLVM toolchain. Everything else (zlib, OpenSSL, …) is built into
`$PREFIX`. `x86` is a legacy 32-bit ABI; it exists in the tree as a full first-class
target (`docs/systems.md:20-21`).

## Build-system fragments

Identical to aarch64 apart from names: toolchain file
`$SYSDIR/i686-linux-android33-toolchain.cmake` (`cmake.toml:5`), cross-file
`$SYSDIR/crossfile-i686-android33.ini` (`meson.toml:5`), same `CMAKE_FLAGS` including
`-DTHREADS_PREFER_PTHREAD_FLAG=ON` and `-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY`
(`cmake.toml:6`).

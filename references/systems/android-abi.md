# android-abi — what actually changes between API levels

The tree ships **14 Android API levels** — `21, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
33, 34, 35` (22 is deliberately absent) for each of `aarch64`, `armv7a`, `i686`,
`x86_64` (`docs/systems.md:20-21`; verified: `ls -d system@aarch64-android*` →
`21 23 24 25 26 27 28 29 30 31 32 33 34 35`).

Family articles: `android-aarch64.md`, `android-armv7a.md`, `android-i686.md`,
`android-x86_64.md`. Snippets: `snippets/systems/android-*.sh` (one per family; the API
is a variable inside them).

## The whole diff, by file

Comparing `system@aarch64-android21` ↔ `-33` ↔ `-35` (`diff -rq`):

| file | changes across API? | how |
|---|---|---|
| `system.toml` | **yes** | `ANDROID_API` number and the `CC`/`CXX` wrapper basename (and the error-message string) |
| `cmake.toml` | **yes** | `CMAKE_TOOLCHAIN_FILE` filename |
| `meson.toml` | **yes** | `MESON_CROSS_FILE` filename |
| `<triple>-toolchain.cmake` | no | **identical content**, different filename |
| `crossfile-<triple>.ini` | no | **identical content**, different filename |
| `autoconf.toml`, `cargo.toml`, `make.toml`, `python.toml` | no | byte-identical |

So an API level is *almost entirely a naming fact*: it selects which clang wrapper and
which two companion files are used, and sets one number. Verified identical content:
`diff system@aarch64-android21/aarch64-linux-android21-toolchain.cmake
system@aarch64-android35/aarch64-linux-android35-toolchain.cmake` → no output;
same for the cross-files and for `autoconf.toml`/`cargo.toml`.

## What the API level means in practice

- **It sets a floor for symbol availability.** The NDK wrapper
  `aarch64-linux-android<API>-clang` targets `minSdkVersion=<API>`; `__ANDROID_API__` is
  fixed to that number, and the sysroot's API-versioned lib set is chosen accordingly.
  `-llog` is pulled in by every Android system precisely because
  `__android_log_write` is API-21+ and every level in the tree is ≥ 21
  (`system@aarch64-android33/system.toml:51-56`).
- **The `ANDROID_API` variable exists as a *number*** for tools that need it as one —
  `__ANDROID_API__`, OpenSSL's target configs, generic tooling
  (`system.toml:26-28`, `:28`). The wrapper name is the same fact spelled as a filename.
- **The triplet never carries the API.** It is always `aarch64-linux-android`,
  `armv7a-linux-androideabi`, `i686-linux-android`, `x86_64-linux-android` for every
  level (`HOST_TRIPLET`, e.g. `system@aarch64-android33/system.toml:87`). Two systems
  that differ only by API are byte-for-byte compatible at the `--host` level.
- **Higher API is not "more features you must use"; it is a floor you raise.** Because
  only the wrapper changes, bumping `ANDROID_API=21`→`35` in a portable environment is
  purely "rename the compiler and the two companion files", not a flag change.

## The two irregularities

1. **armv7a pins its wrapper at 21.** In every armv7a system the `CC`/`CXX` wrappers and
   the CMake toolchain filename say `21` regardless of the system's API, while
   `ANDROID_API` follows the system name — e.g. `system@armv7a-android33/system.toml:28`
   says `ANDROID_API=33` but `:30-31` uses `armv7a-linux-androideabi21-clang`. The
   comment on `:29` even claims "(33)". This makes the armv7a `cmake.toml:5` reference
   `armv7a-linux-androideabi21-toolchain.cmake`, which **does not exist** for API ≥ 23
   (the file shipped is `armv7a-linux-androideabi33-toolchain.cmake`). See
   `android-armv7a.md`. For a portable environment, key the wrapper name off
   `ANDROID_API` uniformly (that is what `snippets/systems/android-armv7a.sh` does, and
   what the other three families already do).
2. **The `meson.toml`/`cmake.toml` companion filenames are per-API**, so a portable
   Meson/CMake setup should compute the path rather than hardcode it (the templates do:
   `templates/system/android-*/toolchain.cmake` and `crossfile.ini` are API-agnostic).

## Cross-family matrix

| family | host triplet | CMake processor | Meson `cpu_family` / `cpu` | Rust target | wrapper tracks API? |
|---|---|---|---|---|---|
| aarch64 | `aarch64-linux-android` | `aarch64` | `aarch64` / `aarch64` | `aarch64-linux-android` | yes |
| armv7a | `armv7a-linux-androideabi` | `arm` | `arm` / `armv7` | `armv7-linux-androideabi` | **no (pinned 21)** |
| i686 | `i686-linux-android` | `x86` | `x86` / `i686` | `i686-linux-android` | yes |
| x86_64 | `x86_64-linux-android` | `x86_64` | `x86_64` / `x86_64` | `x86_64-linux-android` | yes |

Sources: `system@*-android33/system.toml:83`, `*-toolchain.cmake:6`,
`crossfile-*-android33.ini:12-14`, `cargo.toml:12`.

The only *content* difference between the four families (beyond names) is the
`CXXFLAGS` line: aarch64 writes `-O2 -fPIC -DANDROID` with no sysroot `-isystem`,
the other three write `CXXFLAGS="$CFLAGS"` and inherit it
(`system@aarch64-android33/system.toml:71` vs `system@i686-android33/system.toml:46`).

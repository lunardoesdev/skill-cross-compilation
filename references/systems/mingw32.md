# mingw32 — Windows x86 via mingw-w64 (`i686-w64-mingw32`)

Source: `system@mingw32/`. Snippet: `snippets/systems/mingw32.sh`. The 32-bit sibling of
`mingw64`; read `references/systems/mingw64.md` first — everything about "no sysroot",
"no `$ORIGIN`", "no `-fPIC`" and "`-Wl,--undefined-version` is ELF-only" applies here
unchanged. Only the differences are listed below.

## Identity

| fact | value | source |
|---|---|---|
| host triplet (`--host`) | `i686-w64-mingw32` | `system@mingw32/system.toml:25` |
| build triplet | `x86_64-pc-linux-gnu` | `system@mingw32/system.toml:24` |
| `HOST_ARCH` / `HOST_OS` | `i686` / `mingw32` | `system@mingw32/system.toml:27-28` |
| CMake `CMAKE_SYSTEM_NAME` / processor | `Windows` / `i686` | `i686-w64-mingw32-toolchain.cmake:4,7` |
| Meson `system` / `cpu_family` / `cpu` | `windows` / `x86` / `i686` | `crossfile-i686-w64-mingw32.ini:16-19` |
| Rust target | *(empty)* `CARGO_BUILD_TARGET = ""` | `cargo.toml:12` |

The toolchain file itself notes the relationship: "the 64-bit sibling is
`../x86_64-mingw/…`; only the CPU and the windres name differ"
(`i686-w64-mingw32-toolchain.cmake:2-4`).

## Environment variables

Same set as mingw64 (`system.toml:3-13`), all `i686-w64-mingw32-` prefixed, including
`WINDRES`. `CFLAGS = "-O2"`, `CXXFLAGS = "$CFLAGS"` (`system.toml:15-16`). No `AS`/`ASM`.
`PKG_CONFIG_PATH` is the pass-through (`system.toml:17-18`).

## Differences from mingw64

1. **No `$LDFLAGS` and no import-library plumbing.** Unlike `mingw64`, this system's
   `cmake.toml:6` does **not** add `-DCMAKE_REQUIRED_LIBRARIES=…`, and its `system.toml`
   carries none of the long `crypt32`/`ole32`/`gdi32` comment (`system.toml` has no
   `LDFLAGS` line at all). A 32-bit package that needs the Windows certificate store or
   COM would have to add those itself — the 64-bit measurement
   (`system@mingw64/system.toml:18-46`) has not been carried over.
2. **`CARGO_BUILD_TARGET` is empty** (`cargo.toml:12`), where mingw64 sets
   `x86_64-pc-windows-gnu` (`system@mingw64/cargo.toml:12`). An empty target means the
   install step copies from `target//release/<bin>` — with no cross target wired in, this
   relies entirely on the host toolchain selecting i686, so it should be treated as
   unfinished rather than as a working 32-bit Rust target.
3. **Meson cross-file name actually resolves here**:
   `meson.toml:18` references `$SYSDIR/crossfile-i686-w64-mingw32.ini`, which exists
   (contrast the mingw64 mismatch).

## Flags, and why

- `-O2` only (`system.toml:15`) — no `-fPIC`, matching mingw64.
- No `$ORIGIN` rpath: the autoconf and cargo scripts omit the rpath lines exactly as
  mingw64 does (`autoconf.toml` has no rpath line; `cargo.toml` has no `RUSTFLAGS`).
  A PE binary resolves imports through the search path, not an rpath
  (`docs/systems.md:158-161`).
- `CMAKE_FLAGS` still carry `-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY`,
  `-DCMAKE_POLICY_VERSION_MINIMUM=3.5`, `-DCMAKE_MAKE_PROGRAM=$(command -v make || true)`
  but **not** `-DTHREADS_PREFER_PTHREAD_FLAG=ON` (`cmake.toml:6`) — same as mingw64.

## Platform vs. build boundary

Identical to mingw64: mingw-w64 supplies the Windows ABI, headers, import libraries and
`libwinpthread`; everything else goes into `$PREFIX`; `CMAKE_FIND_ROOT_PATH` covers
`$PREFIX` only, no sysroot, program lookup `NEVER` (`i686-w64-mingw32-toolchain.cmake:32-43`).

# zlib

The compression library; installs `libz.a` / (mingw) `libzlib.a` and `zlib.h`.

- build system: **cmake** (`zlib/generic.toml:2`) — unusual for zlib, chosen over the
  hand-written `./configure`/`makefile` so CMake finds the cross toolchain from the
  toolchain file.
- source: `zlib.net/fossils/zlib-1.3.1.tar.gz` with a GitHub release as fallback,
  `--strip-components=1` (`zlib/source.toml:5-12`).
- deps: none.
- recipes: `generic.toml`, `mingw64.toml` (Windows-only post-step).

## Overridden fields

- `args = ["-DZLIB_BUILD_EXAMPLES=OFF"]` (`zlib/generic.toml:4`) — only the library is
  used; the examples cannot run on the build host.
- `mingw64.toml` adds a `post` that symlinks `libzlib.*` → `libz.*` in zlib's own lib
  directory (`zlib/mingw64.toml:11-17`).

## What it needs from the system

The CMake driver's toolchain file. Nothing else.

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| a consumer fails to link `-lz` on Windows | mingw's zlib installs as `libzlib`, but configure scripts hardcode `-lz` (`zlib/mingw64.toml:6-10`) | a `post` that creates the `libz*` aliases where the library is; put the alias in zlib's own dir, not a shared prefix — a recipe only mingw uses needs no runtime platform test |

# Package build snippets

Ready-to-use POSIX `sh` fragments for the projects whose cross-compilation cost
real hours. Each file is one project: a dense header (what it is, its build
system, what is overridden and why, and the error signature if you do it the
other way), then the actual configure / build / install sequence with the exact
flags. They contain no reference to any particular harness.

## Environment assumed

These variables are the contract every fragment relies on. A driver sets them
before sourcing one:

| variable | meaning |
| --- | --- |
| `CC` `CXX` `AR` `RANLIB` `STRIP` | the target toolchain, by full path (never PATH) |
| `CFLAGS` `CXXFLAGS` `LDFLAGS` | base target flags; may contain several words |
| `HOST_TRIPLET` / `BUILD_TRIPLET` | autoconf `--host` / `--build` |
| `HOST_ARCH` / `HOST_OS` | target arch and OS (`aarch64` / `android`, ...) |
| `SYSROOT` / `NDK` / `TOOLBIN` / `ANDROID_API` | Android toolchain facts, when relevant |
| `PREFIX` | the install prefix configure is given |
| `DESTDIR` | the staging root the install is redirected into |
| `CORES` | job count |
| `PKG_CONFIG_LIBDIR` | dependency `.pc` search path, set by the closure |

`$STAGE_PREFIX` (bzip2 only) is a prefix already carrying the stage root, for a
build system with no `DESTDIR` support at all.

## Reading a fragment

- A fragment whose install ends in `make install DESTDIR="$DESTDIR"` (command
  line, not environment) is that way on purpose: the project's Makefile
  *assigns* `DESTDIR` itself and a Makefile variable beats the environment.
- A fragment that trims `--host`/`--build` is an FFmpeg-style hand-written
  `configure` that rejects them.
- A fragment that touches shipped documentation is keeping a target binary from
  being *run* on the build host.

## System environment snippets

`snippets/systems/<family>.sh` are the other half: one file per system family
(`android-aarch64`, `android-armv7a`, `android-i686`, `android-x86_64`,
`native-clang`, `mingw64`, `mingw32`). Source one to get the exact cross
environment — `CC`/`CXX`/`AR`/`RANLIB`/`LD`/`STRIP`/`NM`, `CFLAGS`/`CXXFLAGS`/
`LDFLAGS`, `PKG_CONFIG_LIBDIR`, the sysroot and the triplets — with a short header
stating the triple, what the toolchain supplies and what the platform does. The
package fragments below then run against that environment.

## Files

`bzip2` `expat` `ffmpeg` `ffmpeg-kit-next` `gmp` `gnutls` `help2man` `leptonica`
`libtasn1` `libvpx` `m4` `ncurses` `nettle` `openssl` `sdl` `tesseract` `xz`
`zlib`.

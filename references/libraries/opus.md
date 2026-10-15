# opus

Opus audio codec; installs `libopus.a`, `opus/*.h`, `opus.pc`.

- build system: **autoconf** (`opus/generic.toml:2`).
- source: xiph release tarball, `https://downloads.xiph.org/releases/opus/opus-1.5.2.tar.gz`,
  `--strip-components=1` (`opus/source.toml:3-12`).
- deps: none (`opus/generic.toml:1`).
- recipe: `generic.toml` only — nothing is Android-specific.

## Overridden fields

```toml
configure_args = ["--disable-shared", "--enable-static", "--disable-doc", "--disable-extra-programs"]
```
(`opus/generic.toml:3`) — the static library is the whole product; the extra programs
(`opusenc`, `opusdec`) are target binaries nothing here runs. The driver's
`$AUTOCONF_CONFIGURE_FLAGS` supplies `--host/--build/--prefix` and opus' configure is
genuine autoconf, so no toolchain options are needed.

## What it needs from the system

Only the cross toolchain from the environment (`$CC` etc.) and `$CFLAGS`. Nothing
host-side.

## Known traps

None recorded. This is one of the clean recipes — it exists as the reference for how
little a plain autoconf library needs once the driver owns the triplet and the prefix.
It is a dependency of ffmpeg (`--enable-libopus`).

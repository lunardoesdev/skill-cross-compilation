# libvpx

VP8/VP9 codec library; installs `libvpx.a`, `vpx/*.h`, `libvpx.pc`.

- build system: **autoconf** (`libvpx/generic.toml:2`) — but its `configure` is
  hand-written FFmpeg-style, not autoconf, so `$AUTOCONF_CONFIGURE_FLAGS` does not
  apply and no timestamp guard is needed (`libvpx/generic.toml:3-7`).
- source: GitHub tag archive `v1.15.0`, `--strip-components=1`
  (`libvpx/source.toml:3-12`).
- deps: none (`libvpx/generic.toml:1`).
- recipes: `generic.toml` (native), `android.toml` (cross).

## Overridden fields

- static only, no examples/docs/unit-tests/tools, PIC:
  `--disable-examples --disable-docs --disable-unit-tests --disable-tools
  --enable-pic --enable-static --disable-shared` (`libvpx/generic.toml:8`).
- Android: a `--target` and the sysroot (`libvpx/android.toml:9`): libvpx spells
  64-bit ARM `arm64` and 32-bit x86 `x86`; everything else is the host arch.
  The sysroot goes in `--extra-cflags=--sysroot=$SYSROOT` (and `--extra-cxxflags`)
  **on purpose** — passed as `-isystem` it reorders libc++ before its own C headers
  and breaks `<cstdint>` (`libvpx/android.toml:7-8`).
- Android `pre` strips `-llog` from `$LDFLAGS` (`libvpx/android.toml:33-46`).

## What it needs from the system

`$CC/$AR/...`, `$CFLAGS`, and on Android `$HOST_ARCH`, `$HOST_OS`, `$SYSROOT`.

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `Unknown option "--host=aarch64-linux-android"` | hand-written configure, not autoconf (`libvpx/android.toml:27-31`) | set `AUTOCONF_CONFIGURE_FLAGS="--prefix=$OUTPKG"` in `pre` |
| `sh: line NNNN: vpx_arch: unbound variable` | fields are expanded before `pre` runs, so `--target=$vpx_arch` references an unset name (`libvpx/android.toml:17-24`) | append `--target=$vpx_arch-$HOST_OS-gcc` to `$BS_configure_args` inside `pre` |
| `ld.lld: error: unable to find library -llog` / `Toolchain is unable to link executables` | configure's probes link with `-static`, and Bionic has `liblog` only as a shared object (`libvpx/android.toml:33-37`) | rebuild `$LDFLAGS` without `-llog`, keeping the rest (`libvpx/android.toml:39-44`) |

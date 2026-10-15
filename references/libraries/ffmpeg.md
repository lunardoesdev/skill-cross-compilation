# ffmpeg (6/7/8/9 series)

The media library (libavcodec / libavformat / libavutil / …). The tree pins one
recipe per release line: `ffmpeg` (7.1.2, `ffmpeg/source.toml:1`) and `ffmpeg-9`
(9.0.2, `ffmpeg-9/source.toml:1`), with `ffmpeg-6/7/8` the same shape. All of them
exercise the same hand-written `configure`, so the traps below are shared.

- build system: **autoconf** (`ffmpeg-9/generic.toml:2`) — but ffmpeg's `configure`
  is a hand-written libav-family script, *not* autoconf, and it ignores
  `$CFLAGS`/`$LDFLAGS` (`ffmpeg-9/generic.toml:3-4`).
- source: release tarball, `https://ffmpeg.org/releases/ffmpeg-<v>.tar.xz`,
  unpacked with `--strip-components=1` (`ffmpeg-9/source.toml:3-12`).
- deps: `zlib`, `bzip2`, `xz`, `opus`, `libvpx`, `lame` (`ffmpeg-9/generic.toml:1`).
- recipes: `generic.toml` (native), `android.toml` (cross, `ffmpeg-9/android.toml`).

## Overridden fields

- `AUTOCONF_CONFIGURE_FLAGS` is trimmed to `--prefix=$OUTPKG` in `pre`
  (`ffmpeg-9/generic.toml:18`): the driver's default triple carries `--host`/`--build`,
  which this configure rejects.
- `configure_args` carries the toolchain explicitly — `--cc=$CC --cxx=$CXX --ar=$AR
  --ranlib=$RANLIB --strip=$STRIP` — because ffmpeg does not read them from the
  environment (`ffmpeg-9/generic.toml:9`).
- `--extra-cflags` is appended **one token at a time** in `pre`
  (`ffmpeg-9/generic.toml:38-41`).
- static + `--pkg-config-flags=--static`; programs/tests/docs/network off;
  `--enable-zlib --enable-bzlib --enable-lzma --enable-libopus --enable-libvpx
  --enable-libmp3lame` (`ffmpeg-9/generic.toml:9`).
- `make = true`, `install = true`, and `targets`/`make_args`/`install_args` cleared
  (`ffmpeg-9/generic.toml:54-58`).
- Android recipe: `--enable-cross-compile --target-os=$HOST_OS` and `--arch`
  (`ffmpeg-9/android.toml:6,22`). `ffmpeg-9` also passes `--enable-shared`;
  the older `ffmpeg` line passes `--disable-shared` (`ffmpeg/generic.toml:9`).

## What it needs from the system

`$CFLAGS` (for `-O2`/`-fPIC`, and on Android `-DANDROID` + the NDK header dir),
`$CC/$CXX/$AR/$RANLIB/$STRIP`, and a pkg-config path pointing at the dependency
prefix. Cross builds additionally need `$HOST_ARCH`/`$HOST_OS`
(`ffmpeg-9/android.toml:8-11`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `Unknown option "--host=aarch64-linux-android"` | the driver adds `--host`/`--build` to `$AUTOCONF_CONFIGURE_FLAGS`, but ffmpeg's configure is not autoconf (`ffmpeg-9/generic.toml:11-17`, `ffmpeg-9/android.toml:24-31`) | set `AUTOCONF_CONFIGURE_FLAGS="--prefix=$OUTPKG"` in `pre`; hand the toolchain via `--cc/--cxx/--ar/--ranlib/--strip` |
| `Unknown option "-fPIC"` (the second word) | a list field is expanded unquoted, so `--extra-cflags=$CFLAGS` with a multi-word `$CFLAGS` arrives as several arguments (`ffmpeg-9/generic.toml:20-27`) | loop one token at a time: `for _f in $CFLAGS; do BS_configure_args="$BS_configure_args --extra-cflags=$_f"; done` |
| `Unknown option "--extra-ldflags=..."` | `--extra-ldflags` is advertised in `--help` but is in neither `CMDLINE_SET` nor `CMDLINE_APPEND` (`ffmpeg-9/generic.toml:29-33`) | never pass it; let ffmpeg's own link rules link and find deps through pkg-config |
| `sh: line NN: ffmpeg_arch: unbound variable` | the driver expands recipe fields *before* the recipe's own shell runs, so a name set in `pre` does not exist when the field is expanded (`ffmpeg-9/android.toml:14-21`) | append `--arch=$ffmpeg_arch` to `$BS_configure_args` inside `pre`, where the name exists |
| both build and install skipped in silence; `.../.relax-list: No such file or directory` | an unset field reads `${BS_make:-}`, so this node inherits the previous node's value — `lame` (built in `post`) sets `make=false/install=false` (`ffmpeg-9/generic.toml:44-53`) | assert `make = true`, `install = true`, clear `targets/make_args/install_args` |
| a probe fails with `unable to find library -llog` | ffmpeg is not the culprit here, but its static probes on Bionic fail like libvpx's (`libvpx/android.toml:33-38`) | keep `--pkg-config-flags=--static` and let deps resolve through the closure |

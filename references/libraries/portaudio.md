# portaudio

Audio I/O library; installs `libportaudio.a`, `portaudio.h`, `portaudio-2.0.pc`.

- build system: **cmake** (`portaudio/generic.toml:2`) — chosen even though the release
  ships both, because the autotools path is unusable here (see traps).
- source: `codeload.github.com/PortAudio/portaudio/tar.gz/refs/tags/v19.7.0`,
  `--strip-components=1` (`portaudio/source.toml:5-12`).
- deps: none.
- recipe: `generic.toml` only.

## Overridden fields

```toml
args = ["-DPA_BUILD_STATIC=ON", "-DPA_BUILD_SHARED=OFF", "-DPA_USE_ALSA=OFF",
        "-DPA_USE_JACK=OFF", "-DPA_BUILD_TESTS=OFF", "-DPA_BUILD_EXAMPLES=OFF"]
```
(`portaudio/generic.toml:162`)

- Static only: `PA_BUILD_SHARED` defaults ON; a target prefix has no loader path
  (`portaudio/generic.toml:146-149`).
- **ALSA and JACK forced OFF**: upstream auto-detects both, and each has an else-branch
  that turns its option off when the library is missing — but this **build host** has
  libasound and libjack installed, so autodetection would bake `-lasound`/`-ljack` into
  the installed `portaudio-2.0.pc`. That is a build-host audio stack leaking into the
  target prefix (`portaudio/generic.toml:151-157`).
- Tests/examples are OFF upstream already, stated so a default flip cannot start
  compiling host programs (`portaudio/generic.toml:159-161`).

## Known traps

| symptom in the log | cause | fix |
| --- | --- | --- |
| `ld.lld: error: unable to find library -lpthread` in configure | the autotools path's `configure.in:393` does `AC_CHECK_LIB(pthread, ..., AC_MSG_ERROR([libpthread not found!]))` — a hard abort on any toolchain without `-lpthread`; Bionic ships no libpthread (`portaudio/generic.toml:132-139`) | use the **CMake** path instead of autotools |
| 29 test programs / 9 examples / 3 selftests built by `all` | `Makefile.in:159` makes `all` build them with no configure switch; they open audio devices (`portaudio/generic.toml:140-144`) | use CMake, which builds the library alone by default |
| the target `.pc` names `-lasound`/`-ljack` | autodetection found the **host's** ALSA/JACK (`portaudio/generic.toml:151-157`) | force `-DPA_USE_ALSA=OFF -DPA_USE_JACK=OFF` |
